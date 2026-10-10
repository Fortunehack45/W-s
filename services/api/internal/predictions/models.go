package predictions

import (
	"context"
	"errors"
	"time"
)

var (
	ErrMarketNotFound     = errors.New("prediction market not found")
	ErrMarketNotOpen      = errors.New("prediction market is closed or resolved")
	ErrInvalidOption      = errors.New("invalid prediction option")
	ErrInvalidPoints      = errors.New("points must be greater than zero")
	ErrMarketAlreadyEnded = errors.New("market prediction window has closed")
)

type MarketStatus string

const (
	MarketStatusOpen      MarketStatus = "open"
	MarketStatusLocked    MarketStatus = "locked"
	MarketStatusResolved  MarketStatus = "resolved"
	MarketStatusCancelled MarketStatus = "cancelled"
)

type PredictionOption struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	TotalPoints int64  `json:"totalPoints"`
}

type PredictionMarket struct {
	ID              string             `json:"id"`
	Title           string             `json:"title"`
	Description     string             `json:"description"`
	Category        string             `json:"category"`
	Options         []PredictionOption `json:"options"`
	TotalPoolPoints int64              `json:"totalPoolPoints"`
	Status          MarketStatus       `json:"status"`
	WinningOptionID *string            `json:"winningOptionId,omitempty"`
	ClosesAt        time.Time          `json:"closesAt"`
	CreatedAt       time.Time          `json:"createdAt"`
}

type UserPredictionEntry struct {
	ID         string    `json:"id"`
	UserID     string    `json:"userId"`
	MarketID   string    `json:"marketId"`
	OptionID   string    `json:"optionId"`
	Points     int64     `json:"points"`
	PayoutWon  int64     `json:"payoutWon"`
	Status     string    `json:"status"` // "active", "won", "lost", "refunded"
	CreatedAt  time.Time `json:"createdAt"`
}

type Service interface {
	CreateMarket(ctx context.Context, title, description, category string, optionLabels []string, durationMinutes int) (*PredictionMarket, error)
	GetMarket(ctx context.Context, marketID string) (*PredictionMarket, error)
	ListOpenMarkets(ctx context.Context) ([]*PredictionMarket, error)
	PlacePrediction(ctx context.Context, userID, marketID, optionID string, points int64) (*UserPredictionEntry, error)
	ResolveMarket(ctx context.Context, marketID, winningOptionID string) (*PredictionMarket, error)
	GetUserPredictions(ctx context.Context, userID string) ([]*UserPredictionEntry, error)
}
