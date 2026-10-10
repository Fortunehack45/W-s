package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
)

func TestAntiBot_CommentSpamAndPreviewMode(t *testing.T) {
	ctx := context.Background()
	profileRepo := profiles.NewMemoryRepository()
	profileSvc := profiles.NewService(profileRepo)

	botUserID := "bot-account-007"

	// Create profile with 0 videos
	p := &profiles.Profile{
		ID:                botUserID,
		Username:          "spam_bot_01",
		DisplayName:       "Bot 01",
		VideoCount:        0, // Zero uploads
		RestrictionStatus: profiles.RestrictionNormal,
	}
	if err := profileSvc.CreateProfile(ctx, p); err != nil {
		t.Fatalf("CreateProfile failed: %v", err)
	}

	engine := moderation.NewAntiBotEngine(profileSvc)

	// Simulate 99 spam comments
	for i := 0; i < 99; i++ {
		if err := engine.CheckCommentSpam(ctx, botUserID); err != nil {
			t.Fatalf("comment %d unexpectedly rejected: %v", i, err)
		}
	}

	// 100th comment triggers automated restriction
	err := engine.CheckCommentSpam(ctx, botUserID)
	if err == nil {
		t.Fatalf("expected 100th comment to be blocked by anti-bot engine")
	}

	// Verify account status was changed to Restricted
	updatedProfile, _ := profileSvc.GetProfile(ctx, botUserID)
	if updatedProfile.RestrictionStatus != profiles.RestrictionRestricted {
		t.Errorf("expected profile restriction status 'restricted', got %s", updatedProfile.RestrictionStatus)
	}

	// Invariant: Passive Read-Only Preview Mode
	// Bot can still watch videos, but their views must NOT be counted!
	isEligible := engine.ValidateViewEligibility(ctx, botUserID)
	if isEligible {
		t.Errorf("Passive Preview Mode violated: restricted account view was counted as valid")
	}

	// Invariant: Subsequent comment attempts are blocked
	if err := engine.CheckCommentSpam(ctx, botUserID); err == nil {
		t.Errorf("expected commenting to be blocked for restricted account")
	}

	// In-App Appeal Submission
	appeal, err := engine.SubmitAppeal(ctx, botUserID, "I am a real user and promise to post videos now.")
	if err != nil {
		t.Fatalf("SubmitAppeal failed: %v", err)
	}
	if appeal.Status != "pending" {
		t.Errorf("expected pending appeal status, got %s", appeal.Status)
	}
}
