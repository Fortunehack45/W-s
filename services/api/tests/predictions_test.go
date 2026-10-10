package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/predictions"
)

func TestPredictions_CallItLifecycleAndParimutuelPayout(t *testing.T) {
	ctx := context.Background()
	service := predictions.NewInMemoryPredictionService()

	// 1. Create Prediction Market
	market, err := service.CreateMarket(
		ctx,
		"Will @creator_alex reach 500k views on their new clip?",
		"Prediction resolves in 24 hours based on public view count.",
		"Viral Milestones",
		[]string{"Yes, Reaches 500k", "No, Under 500k"},
		1440, // 24 hours
	)
	if err != nil {
		t.Fatalf("failed to create prediction market: %v", err)
	}
	if len(market.Options) != 2 {
		t.Fatalf("expected 2 options, got %d", len(market.Options))
	}

	optYesID := market.Options[0].ID
	optNoID := market.Options[1].ID

	// 2. Users place predictions using virtual game points
	// User 1 backs "Yes" with 300 points
	u1Entry, err := service.PlacePrediction(ctx, "user-1", market.ID, optYesID, 300)
	if err != nil {
		t.Fatalf("user 1 prediction failed: %v", err)
	}
	if u1Entry.Points != 300 || u1Entry.Status != "active" {
		t.Fatalf("unexpected entry state: %+v", u1Entry)
	}

	// User 2 backs "Yes" with 700 points (Total on Yes = 1,000 points)
	_, err = service.PlacePrediction(ctx, "user-2", market.ID, optYesID, 700)
	if err != nil {
		t.Fatalf("user 2 prediction failed: %v", err)
	}

	// User 3 backs "No" with 1,000 points (Total on No = 1,000 points)
	u3Entry, err := service.PlacePrediction(ctx, "user-3", market.ID, optNoID, 1000)
	if err != nil {
		t.Fatalf("user 3 prediction failed: %v", err)
	}
	if u3Entry.Points != 1000 {
		t.Fatalf("expected 1000 points, got %d", u3Entry.Points)
	}

	// Check Market Pool (Total Pool = 2,000 points)
	mCheck, _ := service.GetMarket(ctx, market.ID)
	if mCheck.TotalPoolPoints != 2000 {
		t.Fatalf("expected 2000 total pool points, got %d", mCheck.TotalPoolPoints)
	}

	// 3. Resolve Market: Outcome is "Yes"
	resolved, err := service.ResolveMarket(ctx, market.ID, optYesID)
	if err != nil {
		t.Fatalf("resolution failed: %v", err)
	}
	if resolved.Status != predictions.MarketStatusResolved {
		t.Fatalf("expected resolved status, got %s", resolved.Status)
	}
	if *resolved.WinningOptionID != optYesID {
		t.Fatalf("expected winning opt %s, got %s", optYesID, *resolved.WinningOptionID)
	}

	// 4. Verify Parimutuel Pool Distribution:
	// Total pool is 2,000 points. Total winning bets on Yes = 1,000 points.
	// User 1 contributed 30% of winning pool -> receives 30% of 2,000 = 600 points!
	u1Predictions, _ := service.GetUserPredictions(ctx, "user-1")
	if len(u1Predictions) != 1 || u1Predictions[0].Status != "won" || u1Predictions[0].PayoutWon != 600 {
		t.Fatalf("user 1 payout mismatch: %+v (expected status=won, payout=600)", u1Predictions[0])
	}

	// User 2 contributed 70% of winning pool -> receives 70% of 2,000 = 1,400 points!
	u2Predictions, _ := service.GetUserPredictions(ctx, "user-2")
	if len(u2Predictions) != 1 || u2Predictions[0].Status != "won" || u2Predictions[0].PayoutWon != 1400 {
		t.Fatalf("user 2 payout mismatch: %+v (expected status=won, payout=1400)", u2Predictions[0])
	}

	// User 3 backed "No" -> status=lost, payout=0
	u3Predictions, _ := service.GetUserPredictions(ctx, "user-3")
	if len(u3Predictions) != 1 || u3Predictions[0].Status != "lost" || u3Predictions[0].PayoutWon != 0 {
		t.Fatalf("user 3 lost state mismatch: %+v", u3Predictions[0])
	}
}
