package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

func TestVideo_ZeroCostUploadAndResumableChunks(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	antiBot := moderation.NewAntiBotEngine(profService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBot, profService)

	creatorID := "creator-alice"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:       creatorID,
		Username: "alice_creator",
	})

	// 1. Invariant: Video upload costs ZERO W's (starts at 0 W's)
	totalBytes := int64(100)
	video, upload, err := videoService.InitUpload(ctx, creatorID, "alice_creator", "My First Video", "Testing zero cost posting", totalBytes)
	if err != nil {
		t.Fatalf("InitUpload failed: %v", err)
	}

	if video.Status != videos.StatusUploading {
		t.Fatalf("expected status %s, got %s", videos.StatusUploading, video.Status)
	}

	// Verify Video W Pool starts at 0 W's
	pool, err := poolService.GetPool(ctx, video.ID)
	if err != nil {
		t.Fatalf("GetPool failed: %v", err)
	}
	if pool.CurrentWCount != 0 {
		t.Fatalf("expected pool CurrentWCount = 0, got %d", pool.CurrentWCount)
	}
	if pool.ReserveBalance != 0 {
		t.Fatalf("expected pool ReserveBalance = 0, got %d", pool.ReserveBalance)
	}

	// 2. Resumable Chunk 1: bytes 0..50
	chunk1 := make([]byte, 50)
	up1, err := videoService.AppendChunk(ctx, upload.ID, 0, chunk1)
	if err != nil {
		t.Fatalf("AppendChunk 1 failed: %v", err)
	}
	if up1.UploadedBytes != 50 {
		t.Fatalf("expected 50 uploaded bytes, got %d", up1.UploadedBytes)
	}
	if up1.Status != "active" {
		t.Fatalf("expected active status, got %s", up1.Status)
	}

	// 3. Resumable Chunk 2: bytes 50..100 (completion)
	chunk2 := make([]byte, 50)
	up2, err := videoService.AppendChunk(ctx, upload.ID, 50, chunk2)
	if err != nil {
		t.Fatalf("AppendChunk 2 failed: %v", err)
	}
	if up2.UploadedBytes != 100 {
		t.Fatalf("expected 100 uploaded bytes, got %d", up2.UploadedBytes)
	}
	if up2.Status != "completed" {
		t.Fatalf("expected completed status, got %s", up2.Status)
	}

	// Verify video transitioned to published with HLS stream
	v, err := videoService.GetVideo(ctx, video.ID)
	if err != nil {
		t.Fatalf("GetVideo failed: %v", err)
	}
	if v.Status != videos.StatusPublished {
		t.Fatalf("expected StatusPublished, got %s", v.Status)
	}
	if v.VideoURL == "" {
		t.Fatal("expected non-empty HLS VideoURL")
	}
}

func TestVideo_PassivePreviewModeViewsDoNotCount(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	antiBot := moderation.NewAntiBotEngine(profService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBot, profService)

	creatorID := "creator-bob"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:       creatorID,
		Username: "bob_creator",
	})

	video, upload, _ := videoService.InitUpload(ctx, creatorID, "bob_creator", "Bob's Clip", "Awesome clip", 10)
	_, _ = videoService.AppendChunk(ctx, upload.ID, 0, make([]byte, 10))

	// Normal Viewer
	normalViewerID := "viewer-charlie"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:                normalViewerID,
		Username:          "charlie_normal",
		RestrictionStatus: profiles.RestrictionNormal,
	})

	// Restricted Viewer (Auto-restricted bot account in Passive Preview Mode)
	restrictedViewerID := "viewer-bot"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:                restrictedViewerID,
		Username:          "bot_spammer",
		RestrictionStatus: profiles.RestrictionRestricted,
	})

	// 1. Normal viewer watches video
	vSession1, err := videoService.RecordView(ctx, video.ID, normalViewerID, 15.0, true, "127.0.0.1")
	if err != nil {
		t.Fatalf("RecordView normal failed: %v", err)
	}
	if !vSession1.IsCounted {
		t.Fatal("expected normal viewer view to be counted")
	}

	v1, _ := videoService.GetVideo(ctx, video.ID)
	if v1.ViewCount != 1 {
		t.Fatalf("expected ViewCount = 1, got %d", v1.ViewCount)
	}

	// 2. Restricted viewer watches video in passive preview mode
	vSession2, err := videoService.RecordView(ctx, video.ID, restrictedViewerID, 15.0, true, "192.168.1.10")
	if err != nil {
		t.Fatalf("RecordView restricted failed: %v", err)
	}

	// Invariant: IsCounted MUST be false for restricted accounts!
	if vSession2.IsCounted {
		t.Fatal("INVARIANT VIOLATED: restricted user's view was counted!")
	}

	// Invariant: Video's public view count MUST NOT increment!
	v2, _ := videoService.GetVideo(ctx, video.ID)
	if v2.ViewCount != 1 {
		t.Fatalf("INVARIANT VIOLATED: public ViewCount incremented by restricted view! expected 1, got %d", v2.ViewCount)
	}
}

func TestVideo_PersonalizedFYPRecommendationEngine(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	antiBot := moderation.NewAntiBotEngine(profService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBot, profService)

	viewerID := "viewer-david"
	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: viewerID, Username: "david"})

	// Create 2 published videos: Video 1 is about AI, Video 2 is about Cooking
	vid1, up1, _ := videoService.InitUpload(ctx, "c1", "c1", "Cutting Edge AI Machine Learning", "Run local LLMs", 10)
	_, _ = videoService.AppendChunk(ctx, up1.ID, 0, make([]byte, 10))

	vid2, up2, _ := videoService.InitUpload(ctx, "c2", "c2", "Delicious Italian Pasta Recipe", "Easy 10 min dinner", 10)
	_, _ = videoService.AppendChunk(ctx, up2.ID, 0, make([]byte, 10))

	// Viewer searches for "machine learning"
	_ = videoService.RecordSearch(ctx, viewerID, "machine learning")

	// Get FYP
	feed, err := videoService.GetFYP(ctx, viewerID, 10, 0)
	if err != nil {
		t.Fatalf("GetFYP failed: %v", err)
	}

	if len(feed) < 2 {
		t.Fatalf("expected at least 2 videos, got %d", len(feed))
	}

	// Video 1 must rank first because of the search keyword match!
	if feed[0].ID != vid1.ID {
		t.Fatalf("expected AI video (%s) to rank #1 due to search keywords, but got #1 = %s (%s)",
			vid1.ID, feed[0].ID, feed[0].Title)
	}
	if feed[1].ID != vid2.ID {
		t.Fatalf("expected cooking video (%s) to rank #2, got #2 = %s (%s)",
			vid2.ID, feed[1].ID, feed[1].Title)
	}
}
