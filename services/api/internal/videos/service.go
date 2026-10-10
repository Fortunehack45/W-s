package videos

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
)

var (
	ErrVideoNotFound    = errors.New("video not found")
	ErrUploadNotFound   = errors.New("upload session not found")
	ErrInvalidOffset    = errors.New("invalid upload offset")
	ErrEmptyTitle       = errors.New("video title cannot be empty")
	ErrAccountRestricted = errors.New("account is restricted: actions disabled in passive preview mode")
)

// Service defines video publishing, engagement, and feed delivery operations.
type Service interface {
	InitUpload(ctx context.Context, userID, username, title, description string, expectedBytes int64) (*Video, *UploadSession, error)
	AppendChunk(ctx context.Context, uploadID string, offset int64, chunk []byte) (*UploadSession, error)
	GetVideo(ctx context.Context, videoID string) (*VideoWithPool, error)
	RecordView(ctx context.Context, videoID, viewerID string, duration float64, completed bool, ipHash string) (*ViewSession, error)
	PostComment(ctx context.Context, videoID, authorID, username, content string, parentID *string) (*Comment, error)
	ListComments(ctx context.Context, videoID string) ([]*Comment, error)
	RepostVideo(ctx context.Context, videoID, userID string) error
	SaveVideo(ctx context.Context, videoID, userID string) error
	RecordSearch(ctx context.Context, userID, queryText string) error
	GetCreatorTotalViews(ctx context.Context, creatorID string) (int64, error)
	GetFYP(ctx context.Context, viewerID string, limit, offset int) ([]*VideoWithPool, error)
	ListAllVideos(ctx context.Context) ([]*Video, error)
	ListAllComments(ctx context.Context, limit int) ([]*Comment, error)
	DeleteComment(ctx context.Context, commentID string) error
}

type inMemoryVideoService struct {
	mu            sync.RWMutex
	videos        map[string]*Video
	uploads       map[string]*UploadSession
	comments      map[string][]*Comment
	views         map[string][]*ViewSession
	reposts       map[string][]*Repost       // videoID -> list
	userReposts   map[string]map[string]bool // userID -> set of videoIDs
	userSaves     map[string]map[string]bool // userID -> set of videoIDs
	searchHistory map[string][]string        // userID -> list of queries
	userFollows   map[string]map[string]bool // userID -> set of followed userIDs

	poolService   *videopools.Service
	antiBotEngine *moderation.AntiBotEngine
	profService   *profiles.Service
}

// NewInMemoryVideoService creates a service instance wired to pool and moderation services.
func NewInMemoryVideoService(
	poolService *videopools.Service,
	antiBotEngine *moderation.AntiBotEngine,
	profService *profiles.Service,
) Service {
	return &inMemoryVideoService{
		videos:        make(map[string]*Video),
		uploads:       make(map[string]*UploadSession),
		comments:      make(map[string][]*Comment),
		views:         make(map[string][]*ViewSession),
		reposts:       make(map[string][]*Repost),
		userReposts:   make(map[string]map[string]bool),
		userSaves:     make(map[string]map[string]bool),
		searchHistory: make(map[string][]string),
		userFollows:   make(map[string]map[string]bool),
		poolService:   poolService,
		antiBotEngine: antiBotEngine,
		profService:   profService,
	}
}

// InitUpload begins a resumable upload session. Cost is 0 W's (100% free to post).
func (s *inMemoryVideoService) InitUpload(
	ctx context.Context,
	userID, username, title, description string,
	expectedBytes int64,
) (*Video, *UploadSession, error) {
	if strings.TrimSpace(title) == "" {
		return nil, nil, ErrEmptyTitle
	}

	// Verify user is not restricted from posting
	p, err := s.profService.GetProfile(ctx, userID)
	if err == nil && p != nil && p.IsReadOnlyPreview() {
		return nil, nil, ErrAccountRestricted
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	videoID := uuid.New().String()
	uploadID := uuid.New().String()
	now := time.Now().UTC()

	video := &Video{
		ID:              videoID,
		CreatorID:       userID,
		CreatorUsername: username,
		Title:           title,
		Description:     description,
		DurationSeconds: 15.0,
		Status:          StatusUploading,
		ViewCount:       0,
		LikeCount:       0,
		CommentCount:    0,
		RepostCount:     0,
		ShareCount:      0,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	upload := &UploadSession{
		ID:            uploadID,
		VideoID:       videoID,
		UserID:        userID,
		ExpectedBytes: expectedBytes,
		UploadedBytes: 0,
		Status:        "active",
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	s.videos[videoID] = video
	s.uploads[uploadID] = upload

	// Initialize Dynamic W Pool at 0 W's with 2% creator royalty
	_, _ = s.poolService.InitPool(ctx, videoID, userID)

	return video, upload, nil
}

// AppendChunk writes a byte chunk at the expected offset.
// When completed, it transitions the video through processing to published.
func (s *inMemoryVideoService) AppendChunk(
	ctx context.Context,
	uploadID string,
	offset int64,
	chunk []byte,
) (*UploadSession, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	upload, exists := s.uploads[uploadID]
	if !exists {
		return nil, ErrUploadNotFound
	}

	if upload.UploadedBytes != offset {
		return nil, fmt.Errorf("%w: expected %d, got %d", ErrInvalidOffset, upload.UploadedBytes, offset)
	}

	upload.UploadedBytes += int64(len(chunk))
	upload.UpdatedAt = time.Now().UTC()

	// If all bytes received, publish video
	if upload.UploadedBytes >= upload.ExpectedBytes {
		upload.Status = "completed"
		if video, exists := s.videos[upload.VideoID]; exists {
			now := time.Now().UTC()
			video.Status = StatusPublished
			video.PublishedAt = &now
			video.VideoURL = fmt.Sprintf("https://cdn.ws-platform.tv/hls/%s/index.m3u8", video.ID)
			video.ThumbnailURL = fmt.Sprintf("https://cdn.ws-platform.tv/thumbnails/%s.jpg", video.ID)
			video.UpdatedAt = now
		}
	}

	return upload, nil
}

// GetVideo returns the video along with its live W pool.
func (s *inMemoryVideoService) GetVideo(ctx context.Context, videoID string) (*VideoWithPool, error) {
	s.mu.RLock()
	video, exists := s.videos[videoID]
	s.mu.RUnlock()

	if !exists {
		return nil, ErrVideoNotFound
	}

	pool, err := s.poolService.GetPool(ctx, videoID)
	if err != nil {
		pool = &videopools.Pool{
			VideoID:           videoID,
			CreatorID:         video.CreatorID,
			CurrentWCount:     0,
			ReserveBalance:    0,
			TotalShares:       0,
			BasePriceW:        1,
			SlopeScaled:       100,
			CreatorRoyaltyBps: 200,
		}
	}

	return &VideoWithPool{
		Video: *video,
		WPool: *pool,
	}, nil
}

// RecordView tracks watch duration. If viewer is restricted, isCounted is FALSE and does NOT increment counters!
func (s *inMemoryVideoService) RecordView(
	ctx context.Context,
	videoID, viewerID string,
	duration float64,
	completed bool,
	ipHash string,
) (*ViewSession, error) {
	s.mu.Lock()
	video, exists := s.videos[videoID]
	if !exists {
		s.mu.Unlock()
		return nil, ErrVideoNotFound
	}
	s.mu.Unlock()

	// Check if viewer account is eligible to increment views (not in passive read-only mode)
	isCounted := s.antiBotEngine.ValidateViewEligibility(ctx, viewerID)

	s.mu.Lock()
	defer s.mu.Unlock()

	session := &ViewSession{
		ID:                   uuid.New().String(),
		VideoID:              videoID,
		ViewerID:             viewerID,
		WatchDurationSeconds: duration,
		IsCompleted:          completed,
		IsCounted:            isCounted,
		IPHash:               ipHash,
		CreatedAt:            time.Now().UTC(),
	}

	s.views[videoID] = append(s.views[videoID], session)

	// Invariant: Views from restricted accounts DO NOT count toward public video metrics or creator watch minutes!
	if isCounted {
		video.ViewCount++
		// Increment creator's lifetime watch minutes
		watchMinutes := int64(duration / 60.0)
		if watchMinutes > 0 && s.profService != nil {
			_ = s.profService.IncrementWatchMinutes(ctx, video.CreatorID, watchMinutes)
		}
	}

	return session, nil
}

// PostComment posts a comment after verifying anti-bot velocity rules.
func (s *inMemoryVideoService) PostComment(
	ctx context.Context,
	videoID, authorID, username, content string,
	parentID *string,
) (*Comment, error) {
	// Enforce anti-bot comment velocity rule: 100 comments/day on accounts with 0 uploads triggers auto-restriction
	err := s.antiBotEngine.CheckCommentSpam(ctx, authorID)
	if err != nil {
		return nil, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	video, exists := s.videos[videoID]
	if !exists {
		return nil, ErrVideoNotFound
	}

	comment := &Comment{
		ID:        uuid.New().String(),
		VideoID:   videoID,
		AuthorID:  authorID,
		Username:  username,
		ParentID:  parentID,
		Content:   content,
		LikeCount: 0,
		CreatedAt: time.Now().UTC(),
	}

	s.comments[videoID] = append(s.comments[videoID], comment)
	video.CommentCount++

	return comment, nil
}

// ListComments retrieves comments for a video.
func (s *inMemoryVideoService) ListComments(ctx context.Context, videoID string) ([]*Comment, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	comments, exists := s.comments[videoID]
	if !exists {
		return []*Comment{}, nil
	}

	res := make([]*Comment, len(comments))
	copy(res, comments)
	return res, nil
}

// RepostVideo shares a video to follower feeds.
func (s *inMemoryVideoService) RepostVideo(ctx context.Context, videoID, userID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	video, exists := s.videos[videoID]
	if !exists {
		return ErrVideoNotFound
	}

	if s.userReposts[userID] == nil {
		s.userReposts[userID] = make(map[string]bool)
	}

	if !s.userReposts[userID][videoID] {
		s.userReposts[userID][videoID] = true
		s.reposts[videoID] = append(s.reposts[videoID], &Repost{
			ID:        uuid.New().String(),
			UserID:    userID,
			VideoID:   videoID,
			CreatedAt: time.Now().UTC(),
		})
		video.RepostCount++
	}

	return nil
}

// SaveVideo bookmarks a video for a user.
func (s *inMemoryVideoService) SaveVideo(ctx context.Context, videoID, userID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.videos[videoID]; !exists {
		return ErrVideoNotFound
	}

	if s.userSaves[userID] == nil {
		s.userSaves[userID] = make(map[string]bool)
	}
	s.userSaves[userID][videoID] = true
	return nil
}

// RecordSearch logs search query to personalize the FYP algorithm.
func (s *inMemoryVideoService) RecordSearch(ctx context.Context, userID, queryText string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	clean := strings.ToLower(strings.TrimSpace(queryText))
	if clean != "" {
		s.searchHistory[userID] = append(s.searchHistory[userID], clean)
	}
	return nil
}

// GetFYP returns personalized video feed ranked by search relevance, follower reposts, and W momentum.
func (s *inMemoryVideoService) GetFYP(ctx context.Context, viewerID string, limit, offset int) ([]*VideoWithPool, error) {
	s.mu.RLock()
	var published []*Video
	for _, v := range s.videos {
		if v.Status == StatusPublished {
			published = append(published, v)
		}
	}

	searches := s.searchHistory[viewerID]
	viewerFollows := s.userFollows[viewerID]
	s.mu.RUnlock()

	type scoredVideo struct {
		video *Video
		score float64
	}

	scored := make([]scoredVideo, 0, len(published))

	for _, v := range published {
		score := 0.0

		// 1. Search Query Personalization (+100 per matching keyword)
		titleLower := strings.ToLower(v.Title + " " + v.Description)
		for _, q := range searches {
			if strings.Contains(titleLower, q) {
				score += 100.0
			}
		}

		// 2. Follower Repost Boost (+50 if reposted by someone viewer follows)
		s.mu.RLock()
		for _, rep := range s.reposts[v.ID] {
			if viewerFollows != nil && viewerFollows[rep.UserID] {
				score += 50.0
				break
			}
		}
		s.mu.RUnlock()

		// 3. Dynamic W Momentum Pool Multiplier (Log-scale boost)
		pool, err := s.poolService.GetPool(ctx, v.ID)
		if err == nil && pool.CurrentWCount > 0 {
			score += math.Log2(float64(pool.CurrentWCount+1)) * 10.0
		}

		// 4. Freshness Boost
		if v.PublishedAt != nil {
			hoursOld := time.Since(*v.PublishedAt).Hours()
			score += math.Max(0, 50.0-(hoursOld*2.0))
		}

		scored = append(scored, scoredVideo{video: v, score: score})
	}

	// Sort descending by relevance score
	sort.Slice(scored, func(i, j int) bool {
		return scored[i].score > scored[j].score
	})

	start := offset
	if start > len(scored) {
		start = len(scored)
	}
	end := start + limit
	if end > len(scored) {
		end = len(scored)
	}

	results := make([]*VideoWithPool, 0, end-start)
	for i := start; i < end; i++ {
		v := scored[i].video
		pool, err := s.poolService.GetPool(ctx, v.ID)
		if err != nil {
			pool = &videopools.Pool{
				VideoID:           v.ID,
				CreatorID:         v.CreatorID,
				CurrentWCount:     0,
				ReserveBalance:    0,
				TotalShares:       0,
				BasePriceW:        1,
				SlopeScaled:       100,
				CreatorRoyaltyBps: 200,
			}
		}
		results = append(results, &VideoWithPool{
			Video: *v,
			WPool: *pool,
		})
	}

	return results, nil
}

// GetCreatorTotalViews returns the sum of views across all videos published by the creator.
func (s *inMemoryVideoService) GetCreatorTotalViews(ctx context.Context, creatorID string) (int64, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var total int64
	for _, v := range s.videos {
		if v.CreatorID == creatorID {
			total += v.ViewCount
		}
	}
	return total, nil
}

func (s *inMemoryVideoService) ListAllVideos(ctx context.Context) ([]*Video, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	res := make([]*Video, 0, len(s.videos))
	for _, v := range s.videos {
		cpy := *v
		res = append(res, &cpy)
	}
	return res, nil
}

func (s *inMemoryVideoService) ListAllComments(ctx context.Context, limit int) ([]*Comment, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var all []*Comment
	for _, comments := range s.comments {
		for _, c := range comments {
			cpy := *c
			all = append(all, &cpy)
		}
	}
	sort.Slice(all, func(i, j int) bool {
		return all[i].CreatedAt.After(all[j].CreatedAt)
	})
	if limit > 0 && len(all) > limit {
		all = all[:limit]
	}
	return all, nil
}

func (s *inMemoryVideoService) DeleteComment(ctx context.Context, commentID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	for videoID, list := range s.comments {
		for i, c := range list {
			if c.ID == commentID {
				s.comments[videoID] = append(list[:i], list[i+1:]...)
				if v, ok := s.videos[videoID]; ok && v.CommentCount > 0 {
					v.CommentCount--
				}
				return nil
			}
		}
	}
	return errors.New("comment not found")
}
