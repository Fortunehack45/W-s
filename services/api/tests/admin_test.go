package tests

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ws-platform/api/internal/admin"
	"github.com/ws-platform/api/internal/ads"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/chat"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

func TestAdmin_PlatformStatsAndModerationAudit(t *testing.T) {
	ctx := context.Background()

	// Setup dependencies
	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	antiBot := moderation.NewAntiBotEngine(profService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBot, profService)
	cardsService := cards.NewInMemoryCardService()
	chatService := chat.NewInMemoryChatService(poolService, cardsService, profService)
	adsService := ads.NewInMemoryAdsService(profService, videoService)

	adminService := admin.NewService(profService, videoService, chatService, poolService, walletService, adsService, antiBot)
	adminHandler := admin.NewHandler(adminService)

	// Create users
	u1 := &profiles.Profile{ID: "usr-creator", Username: "creator1", IsVerified: true}
	u2 := &profiles.Profile{ID: "usr-bot", Username: "spambot99"}
	_ = profService.CreateProfile(ctx, u1)
	_ = profService.CreateProfile(ctx, u2)

	// Post video & comments
	vid, _, _ := videoService.InitUpload(ctx, u1.ID, u1.Username, "First Viral Video", "Test caption", 1024)
	c1, _ := videoService.PostComment(ctx, vid.ID, u2.ID, u2.Username, "Amazing content!", nil)
	if c1 == nil {
		t.Fatalf("expected comment to be posted")
	}

	// 1. Check Platform Stats
	stats, err := adminService.GetStats(ctx)
	if err != nil {
		t.Fatalf("unexpected error getting stats: %v", err)
	}
	if stats.TotalUsers != 2 {
		t.Errorf("expected 2 total users, got %d", stats.TotalUsers)
	}
	if stats.VerifiedUsers != 1 {
		t.Errorf("expected 1 verified user, got %d", stats.VerifiedUsers)
	}

	// 2. Check Comments inspection
	comments, err := adminService.ListAllComments(ctx, 10)
	if err != nil {
		t.Fatalf("unexpected error listing comments: %v", err)
	}
	if len(comments) != 1 {
		t.Fatalf("expected 1 comment, got %d", len(comments))
	}
	if comments[0].AuthorUsername != "spambot99" {
		t.Errorf("expected author spambot99, got %s", comments[0].AuthorUsername)
	}

	// 3. Admin restricts bot account
	err = adminService.SetUserRestriction(ctx, u2.ID, true)
	if err != nil {
		t.Fatalf("unexpected error restricting user: %v", err)
	}

	p2, _ := profService.GetProfile(ctx, u2.ID)
	if !p2.IsReadOnlyPreview() {
		t.Errorf("expected u2 to be in read-only preview mode")
	}

	// 4. Test Web Console endpoint returns 200 OK HTML
	req := httptest.NewRequest(http.MethodGet, "/admin", nil)
	rr := httptest.NewRecorder()
	adminHandler.ServeWebConsole(rr, req)
	if rr.Code != http.StatusOK {
		t.Errorf("expected status 200 for /admin, got %d", rr.Code)
	}
	if rr.Header().Get("Content-Type") != "text/html; charset=utf-8" {
		t.Errorf("expected text/html header, got %s", rr.Header().Get("Content-Type"))
	}
}
