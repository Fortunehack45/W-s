package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/wallet"
)

func TestSignupBonus_Idempotent(t *testing.T) {
	ctx := context.Background()
	repo := wallet.NewMemoryRepository()
	svc := wallet.NewService(repo, 50)

	userID := "user-alice-123"

	// 1. Initial Grant
	summary1, err := svc.GrantSignupBonus(ctx, userID)
	if err != nil {
		t.Fatalf("first GrantSignupBonus failed: %v", err)
	}

	if summary1.AvailableW != 50 {
		t.Errorf("expected 50 available W's, got %d", summary1.AvailableW)
	}
	if summary1.EarnedWBalance != 50 {
		t.Errorf("expected 50 earned W's, got %d", summary1.EarnedWBalance)
	}

	// 2. Duplicate Grant Attempt (e.g. network retry or malicious client)
	summary2, err := svc.GrantSignupBonus(ctx, userID)
	if err != nil {
		t.Fatalf("second GrantSignupBonus failed: %v", err)
	}

	if summary2.AvailableW != 50 {
		t.Errorf("idempotency violated: expected 50 W's on retry, got %d", summary2.AvailableW)
	}

	// 3. Verify Ledger Audit Log
	entries, err := svc.GetLedger(ctx, userID)
	if err != nil {
		t.Fatalf("GetLedger failed: %v", err)
	}

	if len(entries) != 1 {
		t.Fatalf("expected exactly 1 ledger entry, got %d", len(entries))
	}

	if entries[0].EventType != wallet.EventSignupBonus {
		t.Errorf("expected event_type signup_bonus, got %s", entries[0].EventType)
	}
	if entries[0].PointAmount != 50 {
		t.Errorf("expected point_amount 50, got %d", entries[0].PointAmount)
	}
}
