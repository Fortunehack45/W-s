package moderation

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/profiles"
)

var (
	ErrCannotPerformAction = errors.New("action blocked: account is in read-only preview mode due to restriction")
	ErrAppealTooShort      = errors.New("appeal message must be at least 10 characters")
)

// Appeal represents a user's appeal request.
type Appeal struct {
	ID                string    `json:"id"`
	UserID            string    `json:"userId"`
	RestrictionReason string    `json:"restrictionReason"`
	AppealMessage     string    `json:"appealMessage"`
	Status            string    `json:"status"` // pending, approved, rejected
	CreatedAt         time.Time `json:"createdAt"`
}

// AntiBotEngine analyzes behavior and auto-restricts abusive/bot accounts.
type AntiBotEngine struct {
	mu             sync.Mutex
	commentCounts  map[string]int // userID -> count today
	lastReset      time.Time
	appeals        map[string]*Appeal // appealID -> Appeal
	userAppeals    map[string]string  // userID -> latest appealID
	profileService *profiles.Service
}

func NewAntiBotEngine(profileService *profiles.Service) *AntiBotEngine {
	return &AntiBotEngine{
		commentCounts:  make(map[string]int),
		lastReset:      time.Now().UTC(),
		appeals:        make(map[string]*Appeal),
		userAppeals:    make(map[string]string),
		profileService: profileService,
	}
}

// CheckCommentSpam evaluates if an account is a comment spammer (0 uploads + 100+ comments).
// If flagged, it auto-restricts the account.
func (e *AntiBotEngine) CheckCommentSpam(ctx context.Context, userID string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	p, err := e.profileService.GetProfile(ctx, userID)
	if err != nil {
		return err
	}

	// If already restricted, block commenting immediately
	if p.IsReadOnlyPreview() {
		return ErrCannotPerformAction
	}

	// Daily counter tracking
	e.commentCounts[userID]++
	count := e.commentCounts[userID]

	// Spammer fingerprint: 0 uploaded videos AND >= 100 comments
	if p.VideoCount == 0 && count >= 100 {
		// Auto-restrict account
		p.RestrictionStatus = profiles.RestrictionRestricted
		p.BotRiskScore = 95.0
		_ = e.profileService.UpdateProfile(ctx, p)
		return ErrCannotPerformAction
	}

	return nil
}

// ValidateViewEligibility returns whether a video view should be counted toward views/monetization.
// If the user is restricted/bot-flagged, the view is NOT counted (is_counted = false).
func (e *AntiBotEngine) ValidateViewEligibility(ctx context.Context, userID string) bool {
	if userID == "" {
		return true // Anonymous organic view
	}
	p, err := e.profileService.GetProfile(ctx, userID)
	if err != nil {
		return true
	}
	// Passive Preview Mode: Watching is permitted, but does NOT count!
	if p.IsReadOnlyPreview() {
		return false
	}
	return true
}

// IsRestricted returns true if the user is in read-only preview mode.
func (e *AntiBotEngine) IsRestricted(ctx context.Context, userID string) bool {
	return !e.ValidateViewEligibility(ctx, userID)
}

// SubmitAppeal allows a restricted user to request review.
func (e *AntiBotEngine) SubmitAppeal(ctx context.Context, userID, appealMessage string) (*Appeal, error) {
	if len(appealMessage) < 10 {
		return nil, ErrAppealTooShort
	}

	e.mu.Lock()
	defer e.mu.Unlock()

	appealID := uuid.NewString()
	app := &Appeal{
		ID:                appealID,
		UserID:            userID,
		RestrictionReason: "Automated high-frequency activity or comment spam detected",
		AppealMessage:     appealMessage,
		Status:            "pending",
		CreatedAt:         time.Now().UTC(),
	}

	e.appeals[appealID] = app
	e.userAppeals[userID] = appealID
	return app, nil
}

// GetUserAppeal retrieves a user's active appeal if one exists.
func (e *AntiBotEngine) GetUserAppeal(ctx context.Context, userID string) *Appeal {
	e.mu.Lock()
	defer e.mu.Unlock()

	id, ok := e.userAppeals[userID]
	if !ok {
		return nil
	}
	return e.appeals[id]
}

// ListAllAppeals returns all appeals for admin inspection.
func (e *AntiBotEngine) ListAllAppeals(ctx context.Context) []*Appeal {
	e.mu.Lock()
	defer e.mu.Unlock()

	res := make([]*Appeal, 0, len(e.appeals))
	for _, a := range e.appeals {
		cpy := *a
		res = append(res, &cpy)
	}
	return res
}

// ResolveAppeal approves or rejects a user restriction appeal.
func (e *AntiBotEngine) ResolveAppeal(ctx context.Context, appealID string, approve bool) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	app, ok := e.appeals[appealID]
	if !ok {
		return errors.New("appeal not found")
	}

	if approve {
		app.Status = "approved"
		// Restore user to normal
		p, err := e.profileService.GetProfile(ctx, app.UserID)
		if err == nil {
			p.RestrictionStatus = profiles.RestrictionNormal
			p.BotRiskScore = 0.0
			_ = e.profileService.UpdateProfile(ctx, p)
		}
	} else {
		app.Status = "rejected"
	}

	return nil
}

// GetCommentCounts returns daily comment counts for analytics.
func (e *AntiBotEngine) GetCommentCounts() map[string]int {
	e.mu.Lock()
	defer e.mu.Unlock()

	counts := make(map[string]int, len(e.commentCounts))
	for k, v := range e.commentCounts {
		counts[k] = v
	}
	return counts
}
