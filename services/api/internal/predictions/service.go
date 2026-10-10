package predictions

import (
	"context"
	"fmt"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
)

type inMemoryPredictionService struct {
	mu          sync.RWMutex
	markets     map[string]*PredictionMarket
	predictions map[string][]*UserPredictionEntry // marketID -> entries
	userEntries map[string][]*UserPredictionEntry // userID -> entries
}

func NewInMemoryPredictionService() Service {
	s := &inMemoryPredictionService{
		markets:     make(map[string]*PredictionMarket),
		predictions: make(map[string][]*UserPredictionEntry),
		userEntries: make(map[string][]*UserPredictionEntry),
	}

	// Seed popular community entertainment markets
	now := time.Now().UTC()
	m1ID := "market-viral-100k"
	s.markets[m1ID] = &PredictionMarket{
		ID:          m1ID,
		Title:       "Will @creator_star reach 1,000,000 views this weekend?",
		Description: "Call whether this trending vertical clip hits 1M public views before Sunday midnight.",
		Category:    "Trending Milestones",
		Options: []PredictionOption{
			{ID: "opt-yes", Label: "Yes, Hits 1M Views", TotalPoints: 2400},
			{ID: "opt-no", Label: "No, Falls Short", TotalPoints: 1600},
		},
		TotalPoolPoints: 4000,
		Status:          MarketStatusOpen,
		ClosesAt:        now.Add(48 * time.Hour),
		CreatedAt:       now,
	}

	m2ID := "market-sound-battle"
	s.markets[m2ID] = &PredictionMarket{
		ID:          m2ID,
		Title:       "Which creator drops the #1 remix track of the week?",
		Description: "Community battle between Neon Wave vs Cyber Beat.",
		Category:    "Creator Battles",
		Options: []PredictionOption{
			{ID: "opt-neon", Label: "Neon Wave", TotalPoints: 1500},
			{ID: "opt-cyber", Label: "Cyber Beat", TotalPoints: 3500},
		},
		TotalPoolPoints: 5000,
		Status:          MarketStatusOpen,
		ClosesAt:        now.Add(24 * time.Hour),
		CreatedAt:       now,
	}

	return s
}

func (s *inMemoryPredictionService) CreateMarket(
	ctx context.Context,
	title, description, category string,
	optionLabels []string,
	durationMinutes int,
) (*PredictionMarket, error) {
	if title == "" || len(optionLabels) < 2 || durationMinutes <= 0 {
		return nil, fmt.Errorf("invalid market configuration")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	marketID := uuid.New().String()
	options := make([]PredictionOption, len(optionLabels))
	for i, label := range optionLabels {
		options[i] = PredictionOption{
			ID:          fmt.Sprintf("opt-%d-%s", i, uuid.New().String()[:6]),
			Label:       label,
			TotalPoints: 0,
		}
	}

	now := time.Now().UTC()
	market := &PredictionMarket{
		ID:              marketID,
		Title:           title,
		Description:     description,
		Category:        category,
		Options:         options,
		TotalPoolPoints: 0,
		Status:          MarketStatusOpen,
		ClosesAt:        now.Add(time.Duration(durationMinutes) * time.Minute),
		CreatedAt:       now,
	}

	s.markets[marketID] = market
	return market, nil
}

func (s *inMemoryPredictionService) GetMarket(ctx context.Context, marketID string) (*PredictionMarket, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	m, exists := s.markets[marketID]
	if !exists {
		return nil, ErrMarketNotFound
	}
	cpy := *m
	return &cpy, nil
}

func (s *inMemoryPredictionService) ListOpenMarkets(ctx context.Context) ([]*PredictionMarket, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var open []*PredictionMarket
	for _, m := range s.markets {
		if m.Status == MarketStatusOpen {
			cpy := *m
			open = append(open, &cpy)
		}
	}
	return open, nil
}

func (s *inMemoryPredictionService) PlacePrediction(
	ctx context.Context,
	userID, marketID, optionID string,
	points int64,
) (*UserPredictionEntry, error) {
	if points <= 0 {
		return nil, ErrInvalidPoints
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	market, exists := s.markets[marketID]
	if !exists {
		return nil, ErrMarketNotFound
	}
	if market.Status != MarketStatusOpen {
		return nil, ErrMarketNotOpen
	}
	if time.Now().UTC().After(market.ClosesAt) {
		return nil, ErrMarketAlreadyEnded
	}

	var found bool
	for i := range market.Options {
		if market.Options[i].ID == optionID {
			market.Options[i].TotalPoints += points
			found = true
			break
		}
	}
	if !found {
		return nil, ErrInvalidOption
	}

	market.TotalPoolPoints += points

	entry := &UserPredictionEntry{
		ID:        uuid.New().String(),
		UserID:    userID,
		MarketID:  marketID,
		OptionID:  optionID,
		Points:    points,
		PayoutWon: 0,
		Status:    "active",
		CreatedAt: time.Now().UTC(),
	}

	s.predictions[marketID] = append(s.predictions[marketID], entry)
	s.userEntries[userID] = append(s.userEntries[userID], entry)

	return entry, nil
}

func (s *inMemoryPredictionService) ResolveMarket(
	ctx context.Context,
	marketID, winningOptionID string,
) (*PredictionMarket, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	market, exists := s.markets[marketID]
	if !exists {
		return nil, ErrMarketNotFound
	}
	if market.Status == MarketStatusResolved {
		return market, nil
	}

	var winningTotalPoints int64 = 0
	var validWinningOpt bool
	for _, opt := range market.Options {
		if opt.ID == winningOptionID {
			winningTotalPoints = opt.TotalPoints
			validWinningOpt = true
			break
		}
	}
	if !validWinningOpt {
		return nil, ErrInvalidOption
	}

	market.Status = MarketStatusResolved
	market.WinningOptionID = &winningOptionID

	// Parimutuel distribution across winners
	entries := s.predictions[marketID]
	for _, e := range entries {
		if e.OptionID == winningOptionID {
			e.Status = "won"
			if winningTotalPoints > 0 {
				ratio := float64(e.Points) / float64(winningTotalPoints)
				e.PayoutWon = int64(math.Round(ratio * float64(market.TotalPoolPoints)))
			} else {
				e.PayoutWon = e.Points
			}
		} else {
			e.Status = "lost"
			e.PayoutWon = 0
		}
	}

	cpy := *market
	return &cpy, nil
}

func (s *inMemoryPredictionService) GetUserPredictions(ctx context.Context, userID string) ([]*UserPredictionEntry, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	entries := s.userEntries[userID]
	res := make([]*UserPredictionEntry, len(entries))
	copy(res, entries)
	return res, nil
}
