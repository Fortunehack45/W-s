package auctions

import (
	"context"
	"errors"
	"time"

	"github.com/ws-platform/api/internal/cards"
)

var (
	ErrListingNotFound     = errors.New("listing not found")
	ErrListingNotActive     = errors.New("listing is not active")
	ErrCardNotOwned         = errors.New("card is not owned by seller or is not available for listing")
	ErrSelfBiddingBlocked   = errors.New("seller cannot bid on own listing")
	ErrBidTooLow            = errors.New("bid must be higher than current highest bid and meet minimum bid")
	ErrAuctionEnded         = errors.New("auction has already ended")
	ErrCannotCancelWithBids = errors.New("cannot cancel listing once bids have been placed")
	ErrNotAuthorized        = errors.New("not authorized to modify this listing")
)

type ListingStatus string

const (
	StatusActive    ListingStatus = "active"
	StatusCompleted ListingStatus = "completed"
	StatusCancelled ListingStatus = "cancelled"
	StatusNoBids    ListingStatus = "no_bids"
)

type CardListing struct {
	ID                 string                     `json:"id"`
	CardInstanceID     string                     `json:"cardInstanceId"`
	SellerID           string                     `json:"sellerId"`
	MinimumBidW        int64                      `json:"minimumBidW"`
	CurrentHighestBidW int64                      `json:"currentHighestBidW"`
	CurrentBidderID    *string                    `json:"currentBidderId,omitempty"`
	Status             ListingStatus              `json:"status"`
	StartsAt           time.Time                  `json:"startsAt"`
	EndsAt             time.Time                  `json:"endsAt"`
	BidCount           int                        `json:"bidCount"`
	FeePercentage      float64                    `json:"feePercentage"`
	CreatedAt          time.Time                  `json:"createdAt"`
	Card               *cards.CardInstanceWithDef `json:"card,omitempty"`
}

type CardBid struct {
	ID             string    `json:"id"`
	ListingID      string    `json:"listingId"`
	BidderID       string    `json:"bidderId"`
	AmountW        int64     `json:"amountW"`
	IdempotencyKey string    `json:"idempotencyKey"`
	CreatedAt      time.Time `json:"createdAt"`
}

type Service interface {
	CreateListing(ctx context.Context, sellerID, cardInstanceID string, minBidW int64, durationMinutes int, feePercentage float64) (*CardListing, error)
	GetListing(ctx context.Context, listingID string) (*CardListing, error)
	ListActive(ctx context.Context) ([]*CardListing, error)
	PlaceBid(ctx context.Context, bidderID, listingID string, bidAmountW int64) (*CardBid, error)
	SettleAuction(ctx context.Context, listingID string) (*CardListing, error)
	CancelListing(ctx context.Context, sellerID, listingID string) error
}
