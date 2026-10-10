package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/ads"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

type mockVideoMetrics struct {
	views map[string]int64
}

func (m *mockVideoMetrics) GetCreatorTotalViews(ctx context.Context, creatorID string) (int64, error) {
	return m.views[creatorID], nil
}

func TestAdCampaign_LifecycleAndPassivePreviewImmunity(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	metrics := &mockVideoMetrics{views: make(map[string]int64)}
	adsService := ads.NewInMemoryAdsService(profService, metrics)

	advertiserID := "advertiser-uuid-1"
	viewerID := "viewer-organic-1"
	botViewerID := "viewer-bot-1"

	// 1. Create Campaign ($1.00 budget = 100 cents, $10.00 CPM = 1000 cents, so 1 cent per view)
	camp, err := adsService.CreateCampaign(
		ctx,
		advertiserID,
		"vid-promoted-1",
		"Launch Promo",
		"Get 20% off with code WS",
		"https://example.com/deal",
		"Claim Offer",
		100,  // 100 cents budget
		1000, // 1000 cents CPM = 1 cent per impression
	)
	if err != nil {
		t.Fatalf("failed to create ad campaign: %v", err)
	}
	if camp.Status != ads.CampaignActive {
		t.Fatalf("expected campaign to be active, got %s", camp.Status)
	}

	// 2. Organic Viewer Impression
	imp1, err := adsService.RecordImpression(
		ctx,
		camp.ID,
		viewerID,
		false, // not restricted
		12.5,
		false,
		true, // clicked CTA
		"",
	)
	if err != nil {
		t.Fatalf("failed to record organic impression: %v", err)
	}
	if !imp1.IsCounted {
		t.Fatal("expected organic impression to be counted")
	}
	if imp1.CostChargedCents != 1 {
		t.Fatalf("expected 1 cent charged, got %d", imp1.CostChargedCents)
	}

	campCheck, _ := adsService.GetCampaign(ctx, camp.ID)
	if campCheck.SpentCents != 1 || campCheck.ImpressionCount != 1 || campCheck.ClickCount != 1 {
		t.Fatalf("unexpected campaign metrics: spent=%d, imp=%d, clicks=%d", campCheck.SpentCents, campCheck.ImpressionCount, campCheck.ClickCount)
	}

	// 3. Passive Preview Mode Invariant: Restricted Bot Viewer
	impBot, err := adsService.RecordImpression(
		ctx,
		camp.ID,
		botViewerID,
		true, // IS RESTRICTED
		15.0,
		true,
		false,
		"",
	)
	if err != nil {
		t.Fatalf("failed to record bot impression: %v", err)
	}
	if impBot.IsCounted {
		t.Fatal("INVARIANT VIOLATION: restricted bot view was counted as an ad impression")
	}
	if impBot.CostChargedCents != 0 {
		t.Fatalf("INVARIANT VIOLATION: advertiser was charged for bot view: got %d cents", impBot.CostChargedCents)
	}

	campCheck2, _ := adsService.GetCampaign(ctx, camp.ID)
	if campCheck2.SpentCents != 1 || campCheck2.ImpressionCount != 1 {
		t.Fatalf("campaign budget was modified by bot view: spent=%d", campCheck2.SpentCents)
	}

	// 4. Budget Exhaustion
	// Simulate remaining 99 views
	for i := 0; i < 99; i++ {
		_, err := adsService.RecordImpression(ctx, camp.ID, viewerID, false, 5.0, false, false, "")
		if err != nil {
			t.Fatalf("failed at step %d: %v", i, err)
		}
	}

	campFinal, _ := adsService.GetCampaign(ctx, camp.ID)
	if campFinal.SpentCents != 100 {
		t.Fatalf("expected 100 cents spent, got %d", campFinal.SpentCents)
	}
	if campFinal.Status != ads.CampaignExhausted {
		t.Fatalf("expected campaign to be exhausted, got %s", campFinal.Status)
	}

	activeList, _ := adsService.ListActiveCampaigns(ctx)
	if len(activeList) != 0 {
		t.Fatalf("exhausted campaign should not appear in active list, got %d", len(activeList))
	}
}

func TestCreatorMonetization_GateAndAdRevenuePayouts(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	metrics := &mockVideoMetrics{views: make(map[string]int64)}
	adsService := ads.NewInMemoryAdsService(profService, metrics)

	creatorID := "creator-star-1"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:                     creatorID,
		Username:               "creator_star",
		DisplayName:            "Star Creator",
		FollowersCount:         1500,
		VerifiedFollowersCount: 200,
		TotalWatchMinutes:      2000000,
		IsPremium:              false,
	})
	metrics.views[creatorID] = 2500000

	// 1. Test Gate Failure: Creator does not meet requirements
	err := adsService.ApplyForMonetization(ctx, creatorID)
	if err != ads.ErrNotEligible {
		t.Fatalf("expected ErrNotEligible, got: %v", err)
	}

	// 2. Buy Premium for Creator
	_, err = profService.BuyPremium(ctx, creatorID)
	if err != nil {
		t.Fatalf("failed to buy premium: %v", err)
	}

	// 3. Scale Creator metrics to satisfy all 5 criteria
	// Criteria: Premium (true), 500 verified followers, 2000 total followers, 5M watch mins, 5M views
	p, _ := profRepo.GetByID(ctx, creatorID)
	p.FollowersCount = 2500
	p.VerifiedFollowersCount = 550
	p.TotalWatchMinutes = 5500000
	_ = profRepo.Update(ctx, p)
	metrics.views[creatorID] = 6000000

	summary, err := adsService.GetMonetizationSummary(ctx, creatorID)
	if err != nil {
		t.Fatalf("failed to get monetization summary: %v", err)
	}
	if !summary.Progress.IsEligible {
		t.Fatalf("creator should now be eligible: %+v", summary.Progress)
	}

	// 4. Apply for Monetization -> Should succeed!
	err = adsService.ApplyForMonetization(ctx, creatorID)
	if err != nil {
		t.Fatalf("monetization application should have succeeded: %v", err)
	}

	pApproved, _ := profRepo.GetByID(ctx, creatorID)
	if !pApproved.IsMonetizationApproved {
		t.Fatal("profile.IsMonetizationApproved was not set to true")
	}

	// 5. Test 55% Ad Revenue Split
	camp, _ := adsService.CreateCampaign(
		ctx,
		"advertiser-corp",
		"vid-ad-1",
		"Brand Campaign",
		"Best sneakers online",
		"https://sneakers.test",
		"Shop Now",
		50000, // $500.00
		10000, // $100.00 CPM = 10 cents per view
	)

	// Organic user watches ad on this creator's video
	imp, err := adsService.RecordImpression(ctx, camp.ID, "viewer-fan", false, 15.0, true, true, creatorID)
	if err != nil {
		t.Fatalf("failed to record impression: %v", err)
	}
	if imp.CostChargedCents != 10 {
		t.Fatalf("expected 10 cents charged, got %d", imp.CostChargedCents)
	}

	// 55% of 10 cents = 6 cents (rounded)
	summaryAfterAd, _ := adsService.GetMonetizationSummary(ctx, creatorID)
	if summaryAfterAd.AvailableBalanceCents != 6 {
		t.Fatalf("expected 6 cents ad revenue split, got %d", summaryAfterAd.AvailableBalanceCents)
	}

	// 6. Credit Engagement Bonus to test Payouts ($50.00 = 5000 cents total)
	_ = adsService.CreditCreatorRevenue(ctx, creatorID, 4994, "bonus-1", "Monthly engagement bonus")

	summaryFunded, _ := adsService.GetMonetizationSummary(ctx, creatorID)
	if summaryFunded.AvailableBalanceCents != 5000 {
		t.Fatalf("expected 5000 cents balance, got %d", summaryFunded.AvailableBalanceCents)
	}

	// 7. Payout Rule Enforcements:
	// a. Below minimum ($15 < $20 minimum)
	_, err = adsService.RequestPayout(ctx, creatorID, 1500, "bank_transfer", "US123456789")
	if err != ads.ErrBelowMinimumPayout {
		t.Fatalf("expected ErrBelowMinimumPayout, got %v", err)
	}

	// b. Exceeding balance ($60 > $50)
	_, err = adsService.RequestPayout(ctx, creatorID, 6000, "bank_transfer", "US123456789")
	if err != ads.ErrInsufficientBalance {
		t.Fatalf("expected ErrInsufficientBalance, got %v", err)
	}

	// c. Valid Payout ($30.00 = 3000 cents)
	payout, err := adsService.RequestPayout(ctx, creatorID, 3000, "bank_transfer", "US123456789")
	if err != nil {
		t.Fatalf("expected valid payout to succeed: %v", err)
	}
	if payout.AmountCents != 3000 || payout.Status != "pending" {
		t.Fatalf("unexpected payout details: %+v", payout)
	}

	// Verify remaining balance: $50.00 - $30.00 = $20.00 (2000 cents)
	summaryFinal, _ := adsService.GetMonetizationSummary(ctx, creatorID)
	if summaryFinal.AvailableBalanceCents != 2000 {
		t.Fatalf("expected 2000 cents remaining, got %d", summaryFinal.AvailableBalanceCents)
	}
	if summaryFinal.TotalWithdrawnCents != 3000 {
		t.Fatalf("expected 3000 cents total withdrawn, got %d", summaryFinal.TotalWithdrawnCents)
	}
}

func TestCreatorMonetization_EndToEndWithVideoFeed(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	antiBot := moderation.NewAntiBotEngine(profService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBot, profService)
	adsService := ads.NewInMemoryAdsService(profService, videoService)

	creatorID := "creator-feed-1"
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:          creatorID,
		Username:    "feed_creator",
		DisplayName: "Feed Creator",
	})

	// Creator publishes a video at zero cost
	video, upload, err := videoService.InitUpload(ctx, creatorID, "feed_creator", "Viral Dance", "Watch this!", 100)
	if err != nil {
		t.Fatalf("upload init failed: %v", err)
	}
	_, err = videoService.AppendChunk(ctx, upload.ID, 0, make([]byte, 100))
	if err != nil {
		t.Fatalf("append chunk failed: %v", err)
	}

	// 10 viewers watch video
	for i := 0; i < 10; i++ {
		_, _ = videoService.RecordView(ctx, video.ID, "fan", 15.0, true, "ip-fan")
	}

	totalViews, err := videoService.GetCreatorTotalViews(ctx, creatorID)
	if err != nil {
		t.Fatalf("failed to get views: %v", err)
	}
	if totalViews != 10 {
		t.Fatalf("expected 10 views, got %d", totalViews)
	}

	// Creator checks monetization progress
	summary, err := adsService.GetMonetizationSummary(ctx, creatorID)
	if err != nil {
		t.Fatalf("failed to get summary: %v", err)
	}
	if summary.Progress.TotalViews != 10 {
		t.Fatalf("expected 10 views in progress, got %d", summary.Progress.TotalViews)
	}
	if summary.Progress.IsEligible {
		t.Fatal("creator with only 10 views should not be eligible")
	}
}
