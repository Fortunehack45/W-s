package tests

import (
	"context"
	"testing"

	"github.com/ws-platform/api/internal/auctions"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/wallet"
)

func TestCardAuctions_EnglishAuctionLifecycleAndEscrow(t *testing.T) {
	ctx := context.Background()

	// 1. Setup services
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50) // 50 W signup bonus
	cardsService := cards.NewInMemoryCardService()
	auctionService := auctions.NewInMemoryAuctionService(cardsService, walletService)

	sellerID := "seller-user-1"
	bidder1ID := "bidder-user-1"
	bidder2ID := "bidder-user-2"

	// Grant initial balances
	_, _ = walletService.GrantSignupBonus(ctx, sellerID)
	_, _ = walletService.GrantSignupBonus(ctx, bidder1ID)
	_, _ = walletService.GrantSignupBonus(ctx, bidder2ID)
	// Fund Bidder 2 with extra 100 W (Total 150 W)
	_ = walletService.CreditAvailable(ctx, bidder2ID, 100, wallet.SourceEarned, wallet.EventAchievement, "promo", "1", "seed-bidder2")

	// 2. Mint a card for seller
	cardInst, err := cardsService.MintCard(ctx, "Streak Spark", sellerID, "streak_milestone")
	if err != nil {
		t.Fatalf("failed to mint card: %v", err)
	}
	if cardInst.OwnerID != sellerID || cardInst.Status != "owned" {
		t.Fatalf("unexpected card state: owner=%s, status=%s", cardInst.OwnerID, cardInst.Status)
	}

	// 3. Create Auction Listing (min bid 30 W, 60 minutes duration, 5% fee)
	listing, err := auctionService.CreateListing(ctx, sellerID, cardInst.ID, 30, 60, 5.0)
	if err != nil {
		t.Fatalf("failed to create listing: %v", err)
	}
	if listing.Status != auctions.StatusActive {
		t.Fatalf("expected listing to be active, got %s", listing.Status)
	}

	// Verify card instance status is now listed
	cardCheck, _ := cardsService.GetInstance(ctx, cardInst.ID)
	if cardCheck.Status != "listed" {
		t.Fatalf("card status should be 'listed', got %s", cardCheck.Status)
	}

	// 4. Test Invariant: Seller cannot bid on own listing
	_, err = auctionService.PlaceBid(ctx, sellerID, listing.ID, 35)
	if err != auctions.ErrSelfBiddingBlocked {
		t.Fatalf("expected ErrSelfBiddingBlocked, got %v", err)
	}

	// 5. Bidder 1 places first bid of 30 W
	bid1, err := auctionService.PlaceBid(ctx, bidder1ID, listing.ID, 30)
	if err != nil {
		t.Fatalf("bid 1 failed: %v", err)
	}
	if bid1.AmountW != 30 {
		t.Fatalf("expected 30 W bid, got %d", bid1.AmountW)
	}

	// Verify Bidder 1 wallet escrow (Available: 50 - 30 = 20, Reserved: 30)
	b1Summary, _ := walletService.GetSummary(ctx, bidder1ID)
	if b1Summary.AvailableW != 20 || b1Summary.ReservedW != 30 {
		t.Fatalf("bidder 1 escrow mismatch: available=%d, reserved=%d", b1Summary.AvailableW, b1Summary.ReservedW)
	}

	// 6. Bidder 2 outbids with 40 W
	bid2, err := auctionService.PlaceBid(ctx, bidder2ID, listing.ID, 40)
	if err != nil {
		t.Fatalf("bid 2 failed: %v", err)
	}
	if bid2.AmountW != 40 {
		t.Fatalf("expected 40 W bid, got %d", bid2.AmountW)
	}

	// Invariant: Immediate Outbid Release for Bidder 1!
	// Bidder 1's 30 W must be completely unreserved back to available
	b1AfterOutbid, _ := walletService.GetSummary(ctx, bidder1ID)
	if b1AfterOutbid.AvailableW != 50 || b1AfterOutbid.ReservedW != 0 {
		t.Fatalf("INVARIANT VIOLATION: outbid bidder funds were not refunded! available=%d, reserved=%d", b1AfterOutbid.AvailableW, b1AfterOutbid.ReservedW)
	}

	// Bidder 2's escrow verified (Available: 150 - 40 = 110, Reserved: 40)
	b2Summary, _ := walletService.GetSummary(ctx, bidder2ID)
	if b2Summary.AvailableW != 110 || b2Summary.ReservedW != 40 {
		t.Fatalf("bidder 2 escrow mismatch: available=%d, reserved=%d", b2Summary.AvailableW, b2Summary.ReservedW)
	}

	// 7. Test Invariant: Cannot cancel listing once bids are active
	err = auctionService.CancelListing(ctx, sellerID, listing.ID)
	if err != auctions.ErrCannotCancelWithBids {
		t.Fatalf("expected ErrCannotCancelWithBids, got %v", err)
	}

	// 8. Test Settlement: Bidder 2 wins auction
	settled, err := auctionService.SettleAuction(ctx, listing.ID)
	if err != nil {
		t.Fatalf("settlement failed: %v", err)
	}
	if settled.Status != auctions.StatusCompleted {
		t.Fatalf("expected status completed, got %s", settled.Status)
	}

	// Verify Bidder 2's reserved funds permanently finalized (Available: 110, Reserved: 0)
	b2Final, _ := walletService.GetSummary(ctx, bidder2ID)
	if b2Final.AvailableW != 110 || b2Final.ReservedW != 0 {
		t.Fatalf("winner reserved balance not settled: available=%d, reserved=%d", b2Final.AvailableW, b2Final.ReservedW)
	}

	// Verify Seller received winning bid minus 5% platform fee:
	// 40 W * 0.05 = 2 W fee -> Seller gets 38 W net credit
	// Seller started with 50 W signup bonus -> 50 + 38 = 88 W
	sellerFinal, _ := walletService.GetSummary(ctx, sellerID)
	if sellerFinal.AvailableW != 88 {
		t.Fatalf("expected seller balance of 88 W (50 + 38 net), got %d", sellerFinal.AvailableW)
	}

	// Verify card ownership transferred to Bidder 2
	wonCard, _ := cardsService.GetInstance(ctx, cardInst.ID)
	if wonCard.OwnerID != bidder2ID {
		t.Fatalf("expected card owner to be bidder 2 (%s), got %s", bidder2ID, wonCard.OwnerID)
	}
	if wonCard.Status != "owned" {
		t.Fatalf("expected card status to revert to 'owned', got %s", wonCard.Status)
	}
}

func TestCardAuctions_NoBidsAndAntiSniping(t *testing.T) {
	ctx := context.Background()

	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	cardsService := cards.NewInMemoryCardService()
	auctionService := auctions.NewInMemoryAuctionService(cardsService, walletService)

	sellerID := "seller-user-2"
	bidderID := "bidder-user-3"
	_, _ = walletService.GrantSignupBonus(ctx, sellerID)
	_, _ = walletService.GrantSignupBonus(ctx, bidderID)

	// 1. Test No-Bids Expiration
	cardInst, _ := cardsService.MintCard(ctx, "Flame Keeper", sellerID, "streak_milestone")
	listing, err := auctionService.CreateListing(ctx, sellerID, cardInst.ID, 45, 10, 5.0)
	if err != nil {
		t.Fatalf("failed to create listing: %v", err)
	}

	// Settle with zero bids
	settled, err := auctionService.SettleAuction(ctx, listing.ID)
	if err != nil {
		t.Fatalf("settlement failed: %v", err)
	}
	if settled.Status != auctions.StatusNoBids {
		t.Fatalf("expected StatusNoBids, got %s", settled.Status)
	}

	// Verify card reverted to seller
	revertedCard, _ := cardsService.GetInstance(ctx, cardInst.ID)
	if revertedCard.OwnerID != sellerID || revertedCard.Status != "owned" {
		t.Fatalf("card did not revert cleanly to seller: owner=%s, status=%s", revertedCard.OwnerID, revertedCard.Status)
	}

	// 2. Test Anti-Sniping Protection
	// Create auction with only 1 minute remaining
	card2, _ := cardsService.MintCard(ctx, "Streak Spark", sellerID, "streak_milestone")
	listing2, _ := auctionService.CreateListing(ctx, sellerID, card2.ID, 10, 1, 5.0) // 1 minute duration

	timeBeforeBid := listing2.EndsAt
	// Bid placed within last 2 minutes
	_, err = auctionService.PlaceBid(ctx, bidderID, listing2.ID, 15)
	if err != nil {
		t.Fatalf("bid failed: %v", err)
	}

	updatedListing, _ := auctionService.GetListing(ctx, listing2.ID)
	if !updatedListing.EndsAt.After(timeBeforeBid) {
		t.Fatalf("anti-sniping failed: EndsAt was not extended! Before: %v, After: %v", timeBeforeBid, updatedListing.EndsAt)
	}
}
