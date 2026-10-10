package chat

import (
	"context"
	"errors"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
)

var (
	ErrRoomNotFound       = errors.New("chat room not found")
	ErrThreadNotFound     = errors.New("direct message thread not found")
	ErrSelfMessage        = errors.New("cannot create direct message thread with self")
	ErrContentEmpty       = errors.New("message content cannot be empty")
	ErrAccountRestricted  = errors.New("account is restricted in passive preview mode: messaging disabled")
)

type Service interface {
	GetOrCreateVideoRoom(ctx context.Context, videoID, title string) (*ChatRoom, error)
	SendVideoChatMessage(ctx context.Context, videoID, authorID, username, content, idempotencyKey string) (*ChatMessage, error)
	ListVideoChatMessages(ctx context.Context, videoID string, limit int) ([]*ChatMessage, error)
	GetOrCreateDirectThread(ctx context.Context, userA, userB string) (*DirectThread, error)
	SendDirectMessage(ctx context.Context, threadID, senderID, senderUsername, content, idempotencyKey string, testDate *string) (*SendMessageResult, error)
	ListDirectMessages(ctx context.Context, threadID string, limit int) ([]*DirectMessage, error)
	ListUserThreads(ctx context.Context, userID string) ([]*DirectThread, error)
	ListAllVideoChatMessages(ctx context.Context, limit int) ([]*ChatMessage, error)
	ListAllDirectMessages(ctx context.Context, limit int) ([]*DirectMessage, error)
	ListAllDirectThreads(ctx context.Context) ([]*DirectThread, error)
}

type inMemoryChatService struct {
	mu            sync.RWMutex
	rooms         map[string]*ChatRoom         // videoID -> room
	roomMessages  map[string][]*ChatMessage    // videoID -> messages
	threads       map[string]*DirectThread     // threadID -> thread
	userThreads   map[string][]*DirectThread   // userID -> threads
	threadLookup  map[string]string            // canonical key (userA:userB) -> threadID
	threadMsgs    map[string][]*DirectMessage  // threadID -> messages
	idempotentKeys map[string]bool

	poolService  *videopools.Service
	cardsService cards.Service
	profService  *profiles.Service
}

func NewInMemoryChatService(
	poolService *videopools.Service,
	cardsService cards.Service,
	profService *profiles.Service,
) Service {
	return &inMemoryChatService{
		rooms:          make(map[string]*ChatRoom),
		roomMessages:   make(map[string][]*ChatMessage),
		threads:        make(map[string]*DirectThread),
		userThreads:    make(map[string][]*DirectThread),
		threadLookup:   make(map[string]string),
		threadMsgs:     make(map[string][]*DirectMessage),
		idempotentKeys: make(map[string]bool),
		poolService:    poolService,
		cardsService:   cardsService,
		profService:    profService,
	}
}

// GetOrCreateVideoRoom returns the single canonical chat room for a video.
func (s *inMemoryChatService) GetOrCreateVideoRoom(ctx context.Context, videoID, title string) (*ChatRoom, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if r, exists := s.rooms[videoID]; exists {
		return r, nil
	}

	room := &ChatRoom{
		ID:           uuid.New().String(),
		VideoID:      videoID,
		Title:        title,
		IsArchived:   false,
		MessageCount: 0,
		CreatedAt:    time.Now().UTC(),
	}
	s.rooms[videoID] = room
	return room, nil
}

// SendVideoChatMessage posts a message to a video's canonical chat room with top backer badge.
func (s *inMemoryChatService) SendVideoChatMessage(
	ctx context.Context,
	videoID, authorID, username, content, idempotencyKey string,
) (*ChatMessage, error) {
	if strings.TrimSpace(content) == "" {
		return nil, ErrContentEmpty
	}

	// Verify account not restricted
	if s.profService != nil {
		p, err := s.profService.GetProfile(ctx, authorID)
		if err == nil && p.IsReadOnlyPreview() {
			return nil, ErrAccountRestricted
		}
	}

	s.mu.Lock()
	if s.idempotentKeys[idempotencyKey] {
		s.mu.Unlock()
		// Return last message if idempotent retry
		msgs := s.roomMessages[videoID]
		if len(msgs) > 0 {
			return msgs[len(msgs)-1], nil
		}
	}
	s.idempotentKeys[idempotencyKey] = true

	room, exists := s.rooms[videoID]
	if !exists {
		room = &ChatRoom{
			ID:           uuid.New().String(),
			VideoID:      videoID,
			Title:        "Video Chat",
			CreatedAt:    time.Now().UTC(),
		}
		s.rooms[videoID] = room
	}
	s.mu.Unlock()

	// Compute Backer Badge from Video W Pool positions
	badge := ""
	if s.poolService != nil {
		pos, err := s.poolService.GetPosition(ctx, authorID, videoID)
		if err == nil && pos != nil && pos.SharesOwned > 0 {
			if pos.SharesOwned >= 50 {
				badge = "⚡ Top 1 Backer"
			} else if pos.SharesOwned >= 10 {
				badge = "🔥 Top 5 Backer"
			} else {
				badge = "Backer"
			}
		}
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	msg := &ChatMessage{
		ID:             uuid.New().String(),
		RoomID:         room.ID,
		VideoID:        videoID,
		AuthorID:       authorID,
		AuthorUsername: username,
		Content:        content,
		Badge:          badge,
		IdempotencyKey: idempotencyKey,
		CreatedAt:      time.Now().UTC(),
	}

	s.roomMessages[videoID] = append(s.roomMessages[videoID], msg)
	room.MessageCount++

	return msg, nil
}

// ListVideoChatMessages retrieves recent messages in the video chat room.
func (s *inMemoryChatService) ListVideoChatMessages(ctx context.Context, videoID string, limit int) ([]*ChatMessage, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	msgs := s.roomMessages[videoID]
	if len(msgs) == 0 {
		return []*ChatMessage{}, nil
	}

	start := 0
	if limit > 0 && len(msgs) > limit {
		start = len(msgs) - limit
	}

	res := make([]*ChatMessage, len(msgs[start:]))
	copy(res, msgs[start:])
	return res, nil
}

// GetOrCreateDirectThread returns the canonical thread between two users.
func (s *inMemoryChatService) GetOrCreateDirectThread(ctx context.Context, userA, userB string) (*DirectThread, error) {
	if userA == userB {
		return nil, ErrSelfMessage
	}

	// Canonical ordering: u1 < u2
	u1, u2 := userA, userB
	if u1 > u2 {
		u1, u2 = userB, userA
	}

	canonKey := u1 + ":" + u2

	s.mu.Lock()
	defer s.mu.Unlock()

	if threadID, exists := s.threadLookup[canonKey]; exists {
		return s.threads[threadID], nil
	}

	threadID := uuid.New().String()
	now := time.Now().UTC()
	thread := &DirectThread{
		ID:                threadID,
		User1ID:           u1,
		User2ID:           u2,
		CurrentStreakDays: 0,
		LongestStreakDays: 0,
		LastMessageAt:     now,
		LastStreakDate:    "",
		CreatedAt:         now,
	}

	s.threads[threadID] = thread
	s.threadLookup[canonKey] = threadID
	s.userThreads[u1] = append(s.userThreads[u1], thread)
	s.userThreads[u2] = append(s.userThreads[u2], thread)

	return thread, nil
}

// SendDirectMessage sends a DM and executes the Daily Streak & NFT Card Minting Engine.
func (s *inMemoryChatService) SendDirectMessage(
	ctx context.Context,
	threadID, senderID, senderUsername, content, idempotencyKey string,
	testDate *string,
) (*SendMessageResult, error) {
	if strings.TrimSpace(content) == "" {
		return nil, ErrContentEmpty
	}

	// Verify not restricted
	if s.profService != nil {
		p, err := s.profService.GetProfile(ctx, senderID)
		if err == nil && p.IsReadOnlyPreview() {
			return nil, ErrAccountRestricted
		}
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	thread, exists := s.threads[threadID]
	if !exists {
		return nil, ErrThreadNotFound
	}

	now := time.Now().UTC()
	todayStr := now.Format("2006-01-02")
	if testDate != nil && *testDate != "" {
		todayStr = *testDate
	}

	streakAdvanced := false
	var mintedCards []string

	// Calculate streak transition
	if thread.LastStreakDate == "" {
		// First message in thread begins Day 1 streak
		thread.CurrentStreakDays = 1
		thread.LongestStreakDays = 1
		thread.LastStreakDate = todayStr
		streakAdvanced = true
	} else if thread.LastStreakDate != todayStr {
		lastDate, err := time.Parse("2006-01-02", thread.LastStreakDate)
		currentDate, _ := time.Parse("2006-01-02", todayStr)

		if err == nil {
			daysDiff := int(currentDate.Sub(lastDate).Hours() / 24)
			if daysDiff == 1 {
				// Consecutive calendar day -> Advance streak!
				thread.CurrentStreakDays++
				if thread.CurrentStreakDays > thread.LongestStreakDays {
					thread.LongestStreakDays = thread.CurrentStreakDays
				}
				thread.LastStreakDate = todayStr
				streakAdvanced = true

				// Check Streak Collectible Card Minting Triggers
				var targetCard string
				switch thread.CurrentStreakDays {
				case 7:
					targetCard = "Streak Spark" // Common
				case 30:
					targetCard = "Flame Keeper" // Rare
				case 100:
					targetCard = "Century Blaze" // Epic
				case 200:
					targetCard = "Immortal Bond" // Legendary
				}

				if targetCard != "" && s.cardsService != nil {
					// Mint card for both participants!
					_, _ = s.cardsService.MintCard(ctx, targetCard, thread.User1ID, "streak_milestone")
					_, _ = s.cardsService.MintCard(ctx, targetCard, thread.User2ID, "streak_milestone")
					mintedCards = append(mintedCards, targetCard)
				}
			} else if daysDiff > 1 {
				// Broken streak -> Reset to Day 1
				thread.CurrentStreakDays = 1
				thread.LastStreakDate = todayStr
				streakAdvanced = false
			}
		}
	}

	thread.LastMessageAt = now

	msg := &DirectMessage{
		ID:             uuid.New().String(),
		ThreadID:       threadID,
		SenderID:       senderID,
		SenderUsername: senderUsername,
		Content:        content,
		IdempotencyKey: idempotencyKey,
		IsRead:         false,
		CreatedAt:      now,
	}

	s.threadMsgs[threadID] = append(s.threadMsgs[threadID], msg)

	return &SendMessageResult{
		Message:        msg,
		Thread:         thread,
		StreakAdvanced: streakAdvanced,
		MintedCards:    mintedCards,
	}, nil
}

// ListDirectMessages lists messages for a thread.
func (s *inMemoryChatService) ListDirectMessages(ctx context.Context, threadID string, limit int) ([]*DirectMessage, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	msgs := s.threadMsgs[threadID]
	if len(msgs) == 0 {
		return []*DirectMessage{}, nil
	}

	start := 0
	if limit > 0 && len(msgs) > limit {
		start = len(msgs) - limit
	}

	res := make([]*DirectMessage, len(msgs[start:]))
	copy(res, msgs[start:])
	return res, nil
}

// ListUserThreads returns all active threads for a user.
func (s *inMemoryChatService) ListUserThreads(ctx context.Context, userID string) ([]*DirectThread, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	threads := s.userThreads[userID]
	res := make([]*DirectThread, len(threads))
	copy(res, threads)
	return res, nil
}

// ListAllVideoChatMessages returns all video chat messages across all videos for admin inspection.
func (s *inMemoryChatService) ListAllVideoChatMessages(ctx context.Context, limit int) ([]*ChatMessage, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var all []*ChatMessage
	for _, msgs := range s.roomMessages {
		for _, m := range msgs {
			cpy := *m
			all = append(all, &cpy)
		}
	}
	if limit > 0 && len(all) > limit {
		all = all[len(all)-limit:]
	}
	return all, nil
}

// ListAllDirectMessages returns all 1-on-1 direct messages across all threads for admin inspection.
func (s *inMemoryChatService) ListAllDirectMessages(ctx context.Context, limit int) ([]*DirectMessage, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var all []*DirectMessage
	for _, msgs := range s.threadMsgs {
		for _, m := range msgs {
			cpy := *m
			all = append(all, &cpy)
		}
	}
	if limit > 0 && len(all) > limit {
		all = all[len(all)-limit:]
	}
	return all, nil
}

// ListAllDirectThreads returns all direct message threads for admin inspection.
func (s *inMemoryChatService) ListAllDirectThreads(ctx context.Context) ([]*DirectThread, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	res := make([]*DirectThread, 0, len(s.threads))
	for _, t := range s.threads {
		cpy := *t
		res = append(res, &cpy)
	}
	return res, nil
}
