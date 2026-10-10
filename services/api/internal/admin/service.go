package admin

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/ads"
	"github.com/ws-platform/api/internal/chat"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

type Service interface {
	GetStats(ctx context.Context) (*PlatformStats, error)
	ListUsers(ctx context.Context, query string, filterRestricted *bool) ([]*AdminUserView, error)
	ListAllComments(ctx context.Context, limit int) ([]*AdminCommentView, error)
	DeleteComment(ctx context.Context, commentID string) error
	ListAllVideoChats(ctx context.Context, limit int) ([]*chat.ChatMessage, error)
	ListAllDMs(ctx context.Context, limit int) ([]*chat.DirectMessage, error)
	ListAllThreads(ctx context.Context) ([]*chat.DirectThread, error)
	ListAppeals(ctx context.Context) ([]*moderation.Appeal, error)
	ResolveAppeal(ctx context.Context, appealID string, approve bool) error
	SetUserRestriction(ctx context.Context, userID string, restrict bool) error
	SetUserVerified(ctx context.Context, userID string, verified bool) error
	ListActivities(ctx context.Context, limit int) ([]*AdminActivityEvent, error)
	RecordActivity(evtType, userID, username, details string)
}

type adminService struct {
	mu             sync.RWMutex
	profileService *profiles.Service
	videoService   videos.Service
	chatService    chat.Service
	poolService    *videopools.Service
	walletService  *wallet.Service
	adsService     ads.Service
	antiBotEngine  *moderation.AntiBotEngine
	activities     []*AdminActivityEvent
}

func NewService(
	profileService *profiles.Service,
	videoService videos.Service,
	chatService chat.Service,
	poolService *videopools.Service,
	walletService *wallet.Service,
	adsService ads.Service,
	antiBotEngine *moderation.AntiBotEngine,
) Service {
	s := &adminService{
		profileService: profileService,
		videoService:   videoService,
		chatService:    chatService,
		poolService:    poolService,
		walletService:  walletService,
		adsService:     adsService,
		antiBotEngine:  antiBotEngine,
		activities:     make([]*AdminActivityEvent, 0),
	}

	// Seed some initial audit entries for dashboard realism
	s.RecordActivity("system", "system", "SYSTEM", "W's platform initialized with real-time audit trail")
	return s
}

func (s *adminService) RecordActivity(evtType, userID, username, details string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	evt := &AdminActivityEvent{
		ID:        uuid.NewString(),
		Type:      evtType,
		UserID:    userID,
		Username:  username,
		Details:   details,
		Timestamp: time.Now().UTC(),
	}
	s.activities = append([]*AdminActivityEvent{evt}, s.activities...)
	if len(s.activities) > 500 {
		s.activities = s.activities[:500]
	}
}

func (s *adminService) GetStats(ctx context.Context) (*PlatformStats, error) {
	users, _ := s.profileService.ListAllProfiles(ctx)
	allVideos, _ := s.videoService.ListAllVideos(ctx)
	comments, _ := s.videoService.ListAllComments(ctx, 0)
	threads, _ := s.chatService.ListAllDirectThreads(ctx)

	stats := &PlatformStats{
		TotalUsers:    len(users),
		TotalVideos:   len(allVideos),
		TotalComments: len(comments),
	}

	for _, u := range users {
		if u.IsVerified {
			stats.VerifiedUsers++
		}
		if u.IsReadOnlyPreview() {
			stats.RestrictedUsers++
		}
	}

	for _, v := range allVideos {
		stats.TotalVideoViews += v.ViewCount
	}

	for _, t := range threads {
		if t.CurrentStreakDays > 0 {
			stats.ActiveStreaks++
		}
	}

	if s.adsService != nil {
		activeCampaigns, _ := s.adsService.ListActiveCampaigns(ctx)
		stats.TotalAdCampaigns = len(activeCampaigns)
	}

	return stats, nil
}

func (s *adminService) ListUsers(ctx context.Context, query string, filterRestricted *bool) ([]*AdminUserView, error) {
	profilesList, err := s.profileService.ListAllProfiles(ctx)
	if err != nil {
		return nil, err
	}

	q := strings.ToLower(strings.TrimSpace(query))
	views := make([]*AdminUserView, 0, len(profilesList))

	for _, p := range profilesList {
		if q != "" {
			if !strings.Contains(strings.ToLower(p.Username), q) &&
				!strings.Contains(strings.ToLower(p.DisplayName), q) &&
				!strings.Contains(strings.ToLower(p.ID), q) {
				continue
			}
		}

		if filterRestricted != nil {
			isRestr := p.IsReadOnlyPreview()
			if *filterRestricted != isRestr {
				continue
			}
		}

		views = append(views, &AdminUserView{
			ID:                     p.ID,
			Username:               p.Username,
			DisplayName:            p.DisplayName,
			IsVerified:             p.IsVerified,
			IsPremium:              p.IsPremium,
			RestrictionStatus:      string(p.RestrictionStatus),
			BotRiskScore:           p.BotRiskScore,
			FollowersCount:         int64(p.FollowersCount),
			VerifiedFollowersCount: int64(p.VerifiedFollowersCount),
			FollowingCount:         int64(p.FollowingCount),
			TotalWatchMinutes:      p.TotalWatchMinutes,
			TotalEarnedW:           p.NetWEarned,
			VideoCount:             p.VideoCount,
			CreatedAt:              p.CreatedAt,
		})
	}

	sort.Slice(views, func(i, j int) bool {
		return views[i].CreatedAt.After(views[j].CreatedAt)
	})

	return views, nil
}

func (s *adminService) ListAllComments(ctx context.Context, limit int) ([]*AdminCommentView, error) {
	rawComments, err := s.videoService.ListAllComments(ctx, limit)
	if err != nil {
		return nil, err
	}

	velocityMap := s.antiBotEngine.GetCommentCounts()
	views := make([]*AdminCommentView, 0, len(rawComments))

	for _, c := range rawComments {
		vel := velocityMap[c.AuthorID]
		views = append(views, &AdminCommentView{
			ID:             c.ID,
			VideoID:        c.VideoID,
			AuthorID:       c.AuthorID,
			AuthorUsername: c.Username,
			Content:        c.Content,
			SpamVelocity:   vel,
			IsFlagged:      vel >= 100,
			CreatedAt:      c.CreatedAt,
		})
	}

	return views, nil
}

func (s *adminService) DeleteComment(ctx context.Context, commentID string) error {
	err := s.videoService.DeleteComment(ctx, commentID)
	if err == nil {
		s.RecordActivity("delete_comment", "admin", "ADMIN", fmt.Sprintf("Deleted comment %s", commentID))
	}
	return err
}

func (s *adminService) ListAllVideoChats(ctx context.Context, limit int) ([]*chat.ChatMessage, error) {
	return s.chatService.ListAllVideoChatMessages(ctx, limit)
}

func (s *adminService) ListAllDMs(ctx context.Context, limit int) ([]*chat.DirectMessage, error) {
	return s.chatService.ListAllDirectMessages(ctx, limit)
}

func (s *adminService) ListAllThreads(ctx context.Context) ([]*chat.DirectThread, error) {
	return s.chatService.ListAllDirectThreads(ctx)
}

func (s *adminService) ListAppeals(ctx context.Context) ([]*moderation.Appeal, error) {
	return s.antiBotEngine.ListAllAppeals(ctx), nil
}

func (s *adminService) ResolveAppeal(ctx context.Context, appealID string, approve bool) error {
	err := s.antiBotEngine.ResolveAppeal(ctx, appealID, approve)
	if err == nil {
		status := "approved"
		if !approve {
			status = "rejected"
		}
		s.RecordActivity("resolve_appeal", "admin", "ADMIN", fmt.Sprintf("Resolved appeal %s as %s", appealID, status))
	}
	return err
}

func (s *adminService) SetUserRestriction(ctx context.Context, userID string, restrict bool) error {
	status := profiles.RestrictionNormal
	if restrict {
		status = profiles.RestrictionRestricted
	}
	err := s.profileService.SetRestriction(ctx, userID, status)
	if err == nil {
		s.RecordActivity("moderation", "admin", "ADMIN", fmt.Sprintf("Set user %s restriction to %s", userID, status))
	}
	return err
}

func (s *adminService) SetUserVerified(ctx context.Context, userID string, verified bool) error {
	err := s.profileService.SetVerified(ctx, userID, verified)
	if err == nil {
		s.RecordActivity("verify_user", "admin", "ADMIN", fmt.Sprintf("Set user %s verified status to %v", userID, verified))
	}
	return err
}

func (s *adminService) ListActivities(ctx context.Context, limit int) ([]*AdminActivityEvent, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if limit <= 0 || limit > len(s.activities) {
		limit = len(s.activities)
	}

	res := make([]*AdminActivityEvent, limit)
	copy(res, s.activities[:limit])
	return res, nil
}
