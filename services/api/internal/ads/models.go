package ads

import (
	"context"
	"errors"
	"time"
)

var (
	ErrCampaignNotFound     = errors.New("ad campaign not found")
	ErrCampaignNotActive    = errors.New("ad campaign is not active")
	ErrInsufficientBudget   = errors.New("insufficient campaign budget")
	ErrInvalidCampaignInput = errors.New("invalid campaign parameters")
	ErrNotMonetized         = errors.New("creator is not approved for monetization")
	ErrNotEligible          = errors.New("creator does not meet all 5 monetization criteria")
	ErrInsufficientBalance  = errors.New("insufficient monetization balance for payout")
	ErrBelowMinimumPayout   = errors.New("payout amount is below the minimum threshold ($20.00)")
)

type CampaignStatus string

const (
	CampaignActive    CampaignStatus = "active"
	CampaignPaused    CampaignStatus = "paused"
	CampaignExhausted CampaignStatus = "exhausted"
)

type AdCampaign struct {
	ID                string         `json:"id"`
	AdvertiserID      string         `json:"advertiserId"`
	VideoID           string         `json:"videoId"`
	CampaignName      string         `json:"campaignName"`
	Headline          string         `json:"headline"`
	CallToActionURL   string         `json:"callToActionUrl"`
	CallToActionLabel string         `json:"callToActionLabel"`
	BudgetCents       int64          `json:"budgetCents"`
	SpentCents        int64          `json:"spentCents"`
	CPMBidCents       int64          `json:"cpmBidCents"`
	Status            CampaignStatus `json:"status"`
	ImpressionCount   int64          `json:"impressionCount"`
	ClickCount        int64          `json:"clickCount"`
	StartsAt          time.Time      `json:"startsAt"`
	EndsAt            time.Time      `json:"endsAt"`
	CreatedAt         time.Time      `json:"createdAt"`
}

type AdImpression struct {
	ID                   string    `json:"id"`
	CampaignID           string    `json:"campaignId"`
	ViewerID             string    `json:"viewerId"`
	WatchDurationSeconds float64   `json:"watchDurationSeconds"`
	IsCompleted          bool      `json:"isCompleted"`
	ClickedCTA           bool      `json:"clickedCta"`
	CostChargedCents     int64     `json:"costChargedCents"`
	IsCounted            bool      `json:"isCounted"`
	CreatedAt            time.Time `json:"createdAt"`
}

type CreatorEarningsLedgerEntry struct {
	ID          string    `json:"id"`
	CreatorID   string    `json:"creatorId"`
	Type        string    `json:"type"` // "ad_revenue_split", "engagement_bonus", "payout_withdrawal"
	AmountCents int64     `json:"amountCents"`
	ReferenceID string    `json:"referenceId"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"createdAt"`
}

type MonetizationProgress struct {
	IsPremium            bool  `json:"isPremium"`
	VerifiedFollowers    int   `json:"verifiedFollowers"`
	TotalFollowers       int   `json:"totalFollowers"`
	TotalWatchMinutes    int64 `json:"totalWatchMinutes"`
	TotalViews           int64 `json:"totalViews"`
	ReqVerifiedFollowers int   `json:"reqVerifiedFollowers"` // 500
	ReqTotalFollowers    int   `json:"reqTotalFollowers"`    // 2,000
	ReqTotalWatchMinutes int64 `json:"reqTotalWatchMinutes"` // 5,000,000
	ReqTotalViews        int64 `json:"reqTotalViews"`        // 5,000,000
	IsEligible           bool  `json:"isEligible"`
	IsApproved           bool  `json:"isApproved"`
}

type MonetizationSummary struct {
	Progress              MonetizationProgress          `json:"progress"`
	AvailableBalanceCents int64                         `json:"availableBalanceCents"`
	LifetimeEarnedCents   int64                         `json:"lifetimeEarnedCents"`
	TotalWithdrawnCents   int64                         `json:"totalWithdrawnCents"`
	EstimatedRPMUSD       float64                       `json:"estimatedRpmUsd"`
	LedgerHistory         []*CreatorEarningsLedgerEntry `json:"ledgerHistory"`
}

type PayoutRequest struct {
	ID          string    `json:"id"`
	CreatorID   string    `json:"creatorId"`
	AmountCents int64     `json:"amountCents"`
	Method      string    `json:"method"`
	Account     string    `json:"account"`
	Status      string    `json:"status"` // "pending", "processed"
	CreatedAt   time.Time `json:"createdAt"`
}

type Service interface {
	CreateCampaign(ctx context.Context, advertiserID, videoID, name, headline, ctaURL, ctaLabel string, budgetCents, cpmBidCents int64) (*AdCampaign, error)
	GetCampaign(ctx context.Context, campaignID string) (*AdCampaign, error)
	ListActiveCampaigns(ctx context.Context) ([]*AdCampaign, error)
	RecordImpression(ctx context.Context, campaignID, viewerID string, isViewerRestricted bool, durationSec float64, completed, clickedCTA bool, creatorID string) (*AdImpression, error)
	RecordCTAClick(ctx context.Context, campaignID string) error

	// Creator Monetization
	GetMonetizationSummary(ctx context.Context, creatorID string) (*MonetizationSummary, error)
	ApplyForMonetization(ctx context.Context, creatorID string) error
	CreditCreatorRevenue(ctx context.Context, creatorID string, amountCents int64, refID, desc string) error
	RequestPayout(ctx context.Context, creatorID string, amountCents int64, method, account string) (*PayoutRequest, error)
}
