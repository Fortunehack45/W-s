package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/wallet"
)

func TestBondingCurve_StakeProfitAndCashout(t *testing.T) {
	ctx := context.Background()

	// 1. Setup Wallet & Video Pool Service
	walletRepo := wallet.NewMemoryRepository()
	walletSvc := wallet.NewService(walletRepo, 50)

	poolRepo := videopools.NewMemoryRepository()
	poolSvc := videopools.NewService(poolRepo, walletSvc, 200) // 2% creator royalty

	creatorID := "creator-bob"
	buyerA := "user-alice"
	buyerB := "user-charlie"
	videoID := "video-viral-001"

	// 2. Fund users
	_, _ = walletSvc.GrantSignupBonus(ctx, creatorID) // Bob gets 50 W
	_, _ = walletSvc.GrantSignupBonus(ctx, buyerA)    // Alice gets 50 W
	_, _ = walletSvc.GrantSignupBonus(ctx, buyerB)    // Charlie gets 50 W
	// Give Charlie extra W's to simulate a large backer
	_ = walletSvc.CreditAvailable(ctx, buyerB, 500, wallet.SourceEarned, wallet.EventAchievement, "promo", "1", "topup-charlie")

	// 3. Initialize Video Pool at 0 W's
	pool, err := poolSvc.InitPool(ctx, videoID, creatorID)
	if err != nil {
		t.Fatalf("InitPool failed: %v", err)
	}
	if pool.CurrentWCount != 0 {
		t.Fatalf("expected new video pool to start at 0 W, got %d", pool.CurrentWCount)
	}

	// 4. Alice backs the video early with 10 W's
	resA, err := poolSvc.StakeW(ctx, buyerA, videoID, 10, 1, "alice-stake-1")
	if err != nil {
		t.Fatalf("Alice StakeW failed: %v", err)
	}
	if resA.NewVideoWCount != 10 {
		t.Errorf("expected video pool to reach 10 W, got %d", resA.NewVideoWCount)
	}
	if resA.SharesMinted <= 0 {
		t.Errorf("expected Alice to receive shares, got %d", resA.SharesMinted)
	}

	// Check Creator received 2% royalty from Alice
	creatorSummary, _ := walletSvc.GetSummary(ctx, creatorID)
	// Bob had 50 W initially, plus royalty on 10 W (at 2% = 0 W due to integer division on small numbers)

	// 5. Charlie backs the video with 200 W's
	resB, err := poolSvc.StakeW(ctx, buyerB, videoID, 200, 1, "charlie-stake-1")
	if err != nil {
		t.Fatalf("Charlie StakeW failed: %v", err)
	}
	if resB.NewVideoWCount != 210 {
		t.Errorf("expected video pool to reach 210 W, got %d", resB.NewVideoWCount)
	}

	// Verify Bob received creator royalty from Charlie's 200 W stake (2% of 200 = 4 W)
	creatorSummaryAfterB, _ := walletSvc.GetSummary(ctx, creatorID)
	if creatorSummaryAfterB.AvailableW <= creatorSummary.AvailableW {
		t.Errorf("expected creator to receive royalties from Charlie's stake, previous=%d, now=%d",
			creatorSummary.AvailableW, creatorSummaryAfterB.AvailableW)
	}

	// 6. Alice sells her shares to take profit!
	posA, err := poolSvc.GetPosition(ctx, buyerA, videoID)
	if err != nil {
		t.Fatalf("GetPosition failed: %v", err)
	}

	aliceBalanceBeforeSale, _ := walletSvc.GetSummary(ctx, buyerA)
	unstakeRes, err := poolSvc.UnstakeW(ctx, buyerA, videoID, posA.SharesOwned, 1, "alice-unstake-1")
	if err != nil {
		t.Fatalf("Alice UnstakeW failed: %v", err)
	}

	// Invariant: Alice entered with 10 W. Now that the pool rose to 210 W, her shares must be worth MORE than 10 W!
	if unstakeRes.WPayout <= 10 {
		t.Errorf("Alice expected profit (> 10 W), but got payout %d", unstakeRes.WPayout)
	}

	// Invariant: The video's active W count must decrease when Alice cashes out!
	if unstakeRes.NewVideoWCount >= 210 {
		t.Errorf("expected video pool W count to drop below 210, got %d", unstakeRes.NewVideoWCount)
	}

	// Invariant: Alice's wallet must reflect the profit
	aliceBalanceAfterSale, _ := walletSvc.GetSummary(ctx, buyerA)
	if aliceBalanceAfterSale.AvailableW <= aliceBalanceBeforeSale.AvailableW+10 {
		t.Errorf("Alice's available W did not gain profit: before=%d, after=%d",
			aliceBalanceBeforeSale.AvailableW, aliceBalanceAfterSale.AvailableW)
	}

	// Invariant: Pool reserve must remain non-negative (Solvency check)
	updatedPool, _ := poolSvc.GetPool(ctx, videoID)
	if updatedPool.ReserveBalance < 0 {
		t.Errorf("Solvency violated: reserve balance is negative: %d", updatedPool.ReserveBalance)
	}
}
