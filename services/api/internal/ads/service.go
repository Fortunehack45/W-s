package ads

import (
	"context"
	"fmt"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/ws-platform/api/internal/profiles"
)

// VideoMetricProvider provides video count and view aggregates.
type VideoMetricProvider interface {
	GetCreatorTotalViews(ctx context.Context, creatorID string) (int64, error)
}

type inMemoryAdsService struct {
	mu             sync.RWMutex
	campaigns      map[string]*AdCampaign
	impressions    []*AdImpression
	creatorLedger  map[string][]*CreatorEarningsLedgerEntry // key: creatorID
	payoutRequests []*PayoutRequest
	profileService *profiles.Service
	videoMetrics   VideoMetricProvider
}

func NewInMemoryAdsService(profileService *profiles.Service, videoMetrics VideoMetricProvider) Service {
	return &inMemoryAdsService{
		campaigns:      make(map[string]*AdCampaign),
		impressions:    make([]*AdImpression, 0),
		creatorLedger:  make(map[string][]*CreatorEarningsLedgerEntry),
		payoutRequests: make([]*PayoutRequest, 0),
		profileService: profileService,
		videoMetrics:   videoMetrics,
	}
}

func (s *inMemoryAdsService) CreateCampaign(
	ctx context.Context,
	advertiserID, videoID, name, headline, ctaURL, ctaLabel string,
	budgetCents, cpmBidCents int64,
) (*AdCampaign, error) {
	if budgetCents <= 0 || cpmBidCents <= 0 || name == "" || ctaURL == "" {
		return nil, ErrInvalidCampaignInput
	}
	if ctaLabel == "" {
		ctaLabel = "Learn More"
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now().UTC()
	camp := &AdCampaign{
		ID:                uuid.New().String(),
		AdvertiserID:      advertiserID,
		VideoID:           videoID,
		CampaignName:      name,
		Headline:          headline,
		CallToActionURL:   ctaURL,
		CallToActionLabel: ctaLabel,
		BudgetCents:       budgetCents,
		SpentCents:        0,
		CPMBidCents:       cpmBidCents,
		Status:            CampaignActive,
		ImpressionCount:   0,
		ClickCount:        0,
		StartsAt:          now,
		EndsAt:            now.Add(30 * 24 * time.Hour),
		CreatedAt:         now,
	}

	s.campaigns[camp.ID] = camp
	return camp, nil
}

func (s *inMemoryAdsService) GetCampaign(ctx context.Context, campaignID string) (*AdCampaign, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	camp, exists := s.campaigns[campaignID]
	if !exists {
		return nil, ErrCampaignNotFound
	}
	cpy := *camp
	return &cpy, nil
}

func (s *inMemoryAdsService) ListActiveCampaigns(ctx context.Context) ([]*AdCampaign, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var active []*AdCampaign
	for _, c := range s.campaigns {
		if c.Status == CampaignActive && c.SpentCents < c.BudgetCents {
			cpy := *c
			active = append(active, &cpy)
		}
	}
	return active, nil
}

func (s *inMemoryAdsService) RecordImpression(
	ctx context.Context,
	campaignID, viewerID string,
	isViewerRestricted bool,
	durationSec float64,
	completed, clickedCTA bool,
	creatorID string,
) (*AdImpression, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	camp, exists := s.campaigns[campaignID]
	if !exists {
		return nil, ErrCampaignNotFound
	}

	now := time.Now().UTC()

	// 1. Passive Preview Mode Invariant: Bot/Restricted users views do NOT count and do NOT incur cost
	if isViewerRestricted {
		imp := &AdImpression{
			ID:                   uuid.New().String(),
			CampaignID:           campaignID,
			ViewerID:             viewerID,
			WatchDurationSeconds: durationSec,
			IsCompleted:          completed,
			ClickedCTA:           clickedCTA,
			CostChargedCents:     0,
			IsCounted:            false,
			CreatedAt:            now,
		}
		s.impressions = append(s.impressions, imp)
		return imp, nil
	}

	// 2. Calculate impression cost based on CPM bid
	cost := camp.CPMBidCents / 1000
	if cost < 1 {
		cost = 1 // Minimum 1 cent per charge chunk
	}

	if camp.SpentCents+cost > camp.BudgetCents {
		cost = camp.BudgetCents - camp.SpentCents
	}

	camp.SpentCents += cost
	camp.ImpressionCount++
	if clickedCTA {
		camp.ClickCount++
	}

	if camp.SpentCents >= camp.BudgetCents {
		camp.Status = CampaignExhausted
	}

	imp := &AdImpression{
		ID:                   uuid.New().String(),
		CampaignID:           campaignID,
		ViewerID:             viewerID,
		WatchDurationSeconds: durationSec,
		IsCompleted:          completed,
		ClickedCTA:           clickedCTA,
		CostChargedCents:     cost,
		IsCounted:            true,
		CreatedAt:            now,
	}
	s.impressions = append(s.impressions, imp)

	// 3. Creator ad revenue split: 55% to monetized creators
	if creatorID != "" && s.profileService != nil {
		prof, err := s.profileService.GetProfile(ctx, creatorID)
		if err == nil && prof.IsMonetizationApproved {
			creatorShare := int64(math.Round(float64(cost) * 0.55))
			if creatorShare > 0 {
				entry := &CreatorEarningsLedgerEntry{
					ID:          uuid.New().String(),
					CreatorID:   creatorID,
					Type:        "ad_revenue_split",
					AmountCents: creatorShare,
					ReferenceID: imp.ID,
					Description: fmt.Sprintf("55%% Ad revenue split from campaign %s", camp.CampaignName),
					CreatedAt:   now,
				}
				s.creatorLedger[creatorID] = append(s.creatorLedger[creatorID], entry)
			}
		}
	}

	return imp, nil
}

func (s *inMemoryAdsService) RecordCTAClick(ctx context.Context, campaignID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	camp, exists := s.campaigns[campaignID]
	if !exists {
		return ErrCampaignNotFound
	}
	camp.ClickCount++
	return nil
}

func (s *inMemoryAdsService) GetMonetizationSummary(ctx context.Context, creatorID string) (*MonetizationSummary, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if s.profileService == nil {
		return nil, fmt.Errorf("profile service not configured")
	}

	prof, err := s.profileService.GetProfile(ctx, creatorID)
	if err != nil {
		return nil, err
	}

	var totalViews int64 = 0
	if s.videoMetrics != nil {
		views, _ := s.videoMetrics.GetCreatorTotalViews(ctx, creatorID)
		totalViews = views
	}

	progress := MonetizationProgress{
		IsPremium:            prof.IsPremium,
		VerifiedFollowers:    prof.VerifiedFollowersCount,
		TotalFollowers:       prof.FollowersCount,
		TotalWatchMinutes:    prof.TotalWatchMinutes,
		TotalViews:           totalViews,
		ReqVerifiedFollowers: 500,
		ReqTotalFollowers:    2000,
		ReqTotalWatchMinutes: 5000000,
		ReqTotalViews:        5000000,
		IsApproved:           prof.IsMonetizationApproved,
	}

	progress.IsEligible = progress.IsPremium &&
		progress.VerifiedFollowers >= progress.ReqVerifiedFollowers &&
		progress.TotalFollowers >= progress.ReqTotalFollowers &&
		progress.TotalWatchMinutes >= progress.ReqTotalWatchMinutes &&
		progress.TotalViews >= progress.ReqTotalViews

	var available int64 = 0
	var lifetime int64 = 0
	var withdrawn int64 = 0

	history := s.creatorLedger[creatorID]
	for _, h := range history {
		if h.AmountCents > 0 {
			lifetime += h.AmountCents
		} else {
			withdrawn += (-h.AmountCents)
		}
		available += h.AmountCents
	}

	rpm := 4.50 // Standard estimated platform RPM ($4.50 / 1000 views)
	if totalViews > 1000 && lifetime > 0 {
		rpm = (float64(lifetime) / 100.0) / (float64(totalViews) / 1000.0)
	}

	return &MonetizationSummary{
		Progress:              progress,
		AvailableBalanceCents: available,
		LifetimeEarnedCents:   lifetime,
		TotalWithdrawnCents:   withdrawn,
		EstimatedRPMUSD:       rpm,
		LedgerHistory:         history,
	}, nil
}

func (s *inMemoryAdsService) ApplyForMonetization(ctx context.Context, creatorID string) error {
	summary, err := s.GetMonetizationSummary(ctx, creatorID)
	if err != nil {
		return err
	}

	if !summary.Progress.IsEligible {
		return ErrNotEligible
	}

	prof, err := s.profileService.GetProfile(ctx, creatorID)
	if err != nil {
		return err
	}

	prof.IsMonetizationApproved = true
	return s.profileService.UpdateProfile(ctx, prof)
}

func (s *inMemoryAdsService) CreditCreatorRevenue(ctx context.Context, creatorID string, amountCents int64, refID, desc string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	entry := &CreatorEarningsLedgerEntry{
		ID:          uuid.New().String(),
		CreatorID:   creatorID,
		Type:        "engagement_bonus",
		AmountCents: amountCents,
		ReferenceID: refID,
		Description: desc,
		CreatedAt:   time.Now().UTC(),
	}

	s.creatorLedger[creatorID] = append(s.creatorLedger[creatorID], entry)
	return nil
}

func (s *inMemoryAdsService) RequestPayout(
	ctx context.Context,
	creatorID string,
	amountCents int64,
	method, account string,
) (*PayoutRequest, error) {
	if amountCents < 2000 {
		return nil, ErrBelowMinimumPayout
	}

	summary, err := s.GetMonetizationSummary(ctx, creatorID)
	if err != nil {
		return nil, err
	}

	if !summary.Progress.IsApproved {
		return nil, ErrNotMonetized
	}

	if summary.AvailableBalanceCents < amountCents {
		return nil, ErrInsufficientBalance
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now().UTC()
	req := &PayoutRequest{
		ID:          uuid.New().String(),
		CreatorID:   creatorID,
		AmountCents: amountCents,
		Method:      method,
		Account:     account,
		Status:      "pending",
		CreatedAt:   now,
	}

	debit := &CreatorEarningsLedgerEntry{
		ID:          uuid.New().String(),
		CreatorID:   creatorID,
		Type:        "payout_withdrawal",
		AmountCents: -amountCents,
		ReferenceID: req.ID,
		Description: fmt.Sprintf("Payout withdrawal to %s (%s)", method, account),
		CreatedAt:   now,
	}

	s.creatorLedger[creatorID] = append(s.creatorLedger[creatorID], debit)
	s.payoutRequests = append(s.payoutRequests, req)

	return req, nil
}
