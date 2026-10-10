package auctions

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/wallet"
)

type inMemoryAuctionService struct {
	mu            sync.RWMutex
	listings      map[string]*CardListing
	bids          map[string][]*CardBid // listingID -> bids
	cardsService  cards.Service
	walletService *wallet.Service
}

func NewInMemoryAuctionService(cardsService cards.Service, walletService *wallet.Service) Service {
	return &inMemoryAuctionService{
		listings:      make(map[string]*CardListing),
		bids:          make(map[string][]*CardBid),
		cardsService:  cardsService,
		walletService: walletService,
	}
}

func (s *inMemoryAuctionService) CreateListing(
	ctx context.Context,
	sellerID, cardInstanceID string,
	minBidW int64,
	durationMinutes int,
	feePercentage float64,
) (*CardListing, error) {
	if minBidW <= 0 || durationMinutes <= 0 {
		return nil, errors.New("invalid minimum bid or duration")
	}

	// 1. Verify card instance ownership and eligibility
	cardInst, err := s.cardsService.GetInstance(ctx, cardInstanceID)
	if err != nil {
		return nil, err
	}
	if cardInst.OwnerID != sellerID || cardInst.Status != "owned" {
		return nil, ErrCardNotOwned
	}

	if feePercentage <= 0.0 {
		feePercentage = 5.0 // Default 5% platform fee
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	// 2. Mark card instance as listed
	if err := s.cardsService.UpdateCardStatus(ctx, cardInstanceID, "listed"); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	listing := &CardListing{
		ID:                 uuid.New().String(),
		CardInstanceID:     cardInstanceID,
		SellerID:           sellerID,
		MinimumBidW:        minBidW,
		CurrentHighestBidW: 0,
		CurrentBidderID:    nil,
		Status:             StatusActive,
		StartsAt:           now,
		EndsAt:             now.Add(time.Duration(durationMinutes) * time.Minute),
		BidCount:           0,
		FeePercentage:      feePercentage,
		CreatedAt:          now,
		Card:               cardInst,
	}

	s.listings[listing.ID] = listing
	return listing, nil
}

func (s *inMemoryAuctionService) GetListing(ctx context.Context, listingID string) (*CardListing, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	l, exists := s.listings[listingID]
	if !exists {
		return nil, ErrListingNotFound
	}

	cpy := *l
	cardInst, _ := s.cardsService.GetInstance(ctx, l.CardInstanceID)
	cpy.Card = cardInst
	return &cpy, nil
}

func (s *inMemoryAuctionService) ListActive(ctx context.Context) ([]*CardListing, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var active []*CardListing
	now := time.Now().UTC()

	for _, l := range s.listings {
		if l.Status == StatusActive && l.EndsAt.After(now) {
			cpy := *l
			cardInst, _ := s.cardsService.GetInstance(ctx, l.CardInstanceID)
			cpy.Card = cardInst
			active = append(active, &cpy)
		}
	}
	return active, nil
}

func (s *inMemoryAuctionService) PlaceBid(
	ctx context.Context,
	bidderID, listingID string,
	bidAmountW int64,
) (*CardBid, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing, exists := s.listings[listingID]
	if !exists {
		return nil, ErrListingNotFound
	}
	if listing.Status != StatusActive {
		return nil, ErrListingNotActive
	}

	now := time.Now().UTC()
	if now.After(listing.EndsAt) {
		return nil, ErrAuctionEnded
	}

	if bidderID == listing.SellerID {
		return nil, ErrSelfBiddingBlocked
	}

	// Bid threshold check
	if listing.CurrentHighestBidW == 0 {
		if bidAmountW < listing.MinimumBidW {
			return nil, ErrBidTooLow
		}
	} else {
		if bidAmountW <= listing.CurrentHighestBidW {
			return nil, ErrBidTooLow
		}
	}

	// 1. Authoritative Escrow Reservation for New Bidder
	reserveKey := fmt.Sprintf("auction_bid_reserve:%s:%s:%d", listingID, bidderID, bidAmountW)
	err := s.walletService.ReserveAvailable(
		ctx,
		bidderID,
		bidAmountW,
		wallet.EventAuctionBidReserve,
		"auction_listing",
		listingID,
		reserveKey,
	)
	if err != nil {
		return nil, err
	}

	// 2. Immediate Outbid Release for Previous Highest Bidder
	if listing.CurrentBidderID != nil && *listing.CurrentBidderID != "" {
		prevBidder := *listing.CurrentBidderID
		prevAmount := listing.CurrentHighestBidW
		releaseKey := fmt.Sprintf("auction_bid_release:%s:%s:%d", listingID, prevBidder, prevAmount)

		_ = s.walletService.ReleaseReserved(
			ctx,
			prevBidder,
			prevAmount,
			wallet.EventAuctionBidRelease,
			"auction_listing",
			listingID,
			releaseKey,
		)
	}

	// 3. Anti-Sniping Protection: Extend timer by 2 minutes if bid within last 2 minutes
	if time.Until(listing.EndsAt) < 2*time.Minute {
		listing.EndsAt = now.Add(2 * time.Minute)
	}

	// 4. Update Listing High Bid
	bidID := uuid.New().String()
	listing.CurrentHighestBidW = bidAmountW
	listing.CurrentBidderID = &bidderID
	listing.BidCount++

	bid := &CardBid{
		ID:             bidID,
		ListingID:      listingID,
		BidderID:       bidderID,
		AmountW:        bidAmountW,
		IdempotencyKey: reserveKey,
		CreatedAt:      now,
	}

	s.bids[listingID] = append(s.bids[listingID], bid)
	return bid, nil
}

func (s *inMemoryAuctionService) SettleAuction(ctx context.Context, listingID string) (*CardListing, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing, exists := s.listings[listingID]
	if !exists {
		return nil, ErrListingNotFound
	}
	if listing.Status != StatusActive {
		return nil, ErrListingNotActive
	}

	// 1. If No Bids: Revert card to seller
	if listing.CurrentBidderID == nil || *listing.CurrentBidderID == "" {
		listing.Status = StatusNoBids
		_ = s.cardsService.UpdateCardStatus(ctx, listing.CardInstanceID, "owned")
		cpy := *listing
		return &cpy, nil
	}

	winnerID := *listing.CurrentBidderID
	winningBid := listing.CurrentHighestBidW

	// 2. Finalize Winning Bidder's Escrow Debit
	debitKey := fmt.Sprintf("auction_settle_debit:%s:%s", listingID, winnerID)
	err := s.walletService.FinalizeDebitReserved(
		ctx,
		winnerID,
		winningBid,
		wallet.EventAuctionDebit,
		"auction_listing",
		listingID,
		debitKey,
	)
	if err != nil {
		return nil, err
	}

	// 3. Deduct Platform Fee and Credit Seller
	feeRate := listing.FeePercentage / 100.0
	platformFee := int64(math.Round(float64(winningBid) * feeRate))
	sellerCredit := winningBid - platformFee

	creditKey := fmt.Sprintf("auction_settle_credit:%s:%s", listingID, listing.SellerID)
	_ = s.walletService.CreditAvailable(
		ctx,
		listing.SellerID,
		sellerCredit,
		wallet.SourceEarned,
		wallet.EventAuctionCredit,
		"auction_listing",
		listingID,
		creditKey,
	)

	// 4. Transfer Card Instance Ownership to Winner
	_ = s.cardsService.TransferOwnership(ctx, listing.CardInstanceID, winnerID, "auction_purchase")

	listing.Status = StatusCompleted
	cpy := *listing
	cardInst, _ := s.cardsService.GetInstance(ctx, listing.CardInstanceID)
	cpy.Card = cardInst
	return &cpy, nil
}

func (s *inMemoryAuctionService) CancelListing(ctx context.Context, sellerID, listingID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	listing, exists := s.listings[listingID]
	if !exists {
		return ErrListingNotFound
	}
	if listing.SellerID != sellerID {
		return ErrNotAuthorized
	}
	if listing.Status != StatusActive {
		return ErrListingNotActive
	}
	if listing.BidCount > 0 {
		return ErrCannotCancelWithBids
	}

	listing.Status = StatusCancelled
	return s.cardsService.UpdateCardStatus(ctx, listing.CardInstanceID, "owned")
}
