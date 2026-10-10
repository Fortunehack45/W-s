package videopools

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/ws-platform/api/internal/wallet"
)

var (
	ErrPoolNotFound      = errors.New("video pool not found")
	ErrInsufficientShares = errors.New("user has insufficient shares to unstake")
	ErrSlippageExceeded  = errors.New("slippage tolerance exceeded")
	ErrZeroDeposit       = errors.New("deposit amount must be greater than zero")
)

// Repository manages persistence for video pools and user positions.
type Repository interface {
	GetPool(ctx context.Context, videoID string) (*Pool, error)
	SavePool(ctx context.Context, pool *Pool) error
	GetPosition(ctx context.Context, userID, videoID string) (*Position, error)
	SavePosition(ctx context.Context, pos *Position) error
}

// MemoryRepository provides concurrency-safe storage for tests.
type MemoryRepository struct {
	mu        sync.RWMutex
	pools     map[string]*Pool
	positions map[string]*Position // key: userID + ":" + videoID
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		pools:     make(map[string]*Pool),
		positions: make(map[string]*Position),
	}
}

func (r *MemoryRepository) GetPool(ctx context.Context, videoID string) (*Pool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	p, ok := r.pools[videoID]
	if !ok {
		return nil, ErrPoolNotFound
	}
	cpy := *p
	return &cpy, nil
}

func (r *MemoryRepository) SavePool(ctx context.Context, pool *Pool) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	pool.UpdatedAt = time.Now().UTC()
	pool.Version++
	cpy := *pool
	r.pools[pool.VideoID] = &cpy
	return nil
}

func (r *MemoryRepository) GetPosition(ctx context.Context, userID, videoID string) (*Position, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	key := userID + ":" + videoID
	pos, ok := r.positions[key]
	if !ok {
		return &Position{
			UserID:      userID,
			VideoID:     videoID,
			SharesOwned: 0,
			WCostBasis:  0,
		}, nil
	}
	cpy := *pos
	return &cpy, nil
}

func (r *MemoryRepository) SavePosition(ctx context.Context, pos *Position) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	key := pos.UserID + ":" + pos.VideoID
	pos.UpdatedAt = time.Now().UTC()
	cpy := *pos
	r.positions[key] = &cpy
	return nil
}

// Service manages bonding curve calculations, staking, and profit taking.
type Service struct {
	repo          Repository
	walletService *wallet.Service
	defaultRoyalty int
}

func NewService(repo Repository, walletService *wallet.Service, defaultRoyalty int) *Service {
	return &Service{
		repo:          repo,
		walletService: walletService,
		defaultRoyalty: defaultRoyalty,
	}
}

// InitPool creates an initial pool for a newly published video starting at 0 W's.
func (s *Service) InitPool(ctx context.Context, videoID, creatorID string) (*Pool, error) {
	pool := &Pool{
		VideoID:           videoID,
		CreatorID:         creatorID,
		CurrentWCount:     0, // Starts at 0 W's
		ReserveBalance:    0,
		TotalShares:       0,
		BasePriceW:        1,
		SlopeScaled:       100, // 0.01 per share
		CreatorRoyaltyBps: s.defaultRoyalty,
		TotalVolumeW:      0,
	}
	if err := s.repo.SavePool(ctx, pool); err != nil {
		return nil, err
	}
	return pool, nil
}

// GetPool returns current pool metrics.
func (s *Service) GetPool(ctx context.Context, videoID string) (*Pool, error) {
	return s.repo.GetPool(ctx, videoID)
}

// StakeW buys shares in the video's bonding curve pool.
func (s *Service) StakeW(ctx context.Context, userID, videoID string, wAmount int64, minSharesOut int64, idempotencyKey string) (*StakeResult, error) {
	if wAmount <= 0 {
		return nil, ErrZeroDeposit
	}

	pool, err := s.repo.GetPool(ctx, videoID)
	if err != nil {
		return nil, err
	}

	// 1. Calculate 2% creator royalty
	royaltyW := (wAmount * int64(pool.CreatorRoyaltyBps)) / 10000
	netDeposit := wAmount - royaltyW

	// 2. Compute shares minted from bonding curve
	sharesMinted, wSpent := calculateBuyShares(pool.TotalShares, netDeposit, pool.BasePriceW, pool.SlopeScaled)
	if sharesMinted < minSharesOut {
		return nil, ErrSlippageExceeded
	}

	// 3. Authoritative Wallet Debit for user
	debitKey := fmt.Sprintf("stake_debit:%s:%s", videoID, idempotencyKey)
	if err := s.walletService.DebitAvailable(ctx, userID, wAmount, wallet.EventVideoWStake, "video_pool", videoID, debitKey); err != nil {
		return nil, err
	}

	// 4. Credit creator royalty to creator's earned balance
	if royaltyW > 0 && pool.CreatorID != "" && pool.CreatorID != userID {
		royaltyKey := fmt.Sprintf("creator_royalty:%s:%s", videoID, idempotencyKey)
		_ = s.walletService.CreditAvailable(ctx, pool.CreatorID, royaltyW, wallet.SourceEarned, wallet.EventCreatorRoyalty, "video_pool", videoID, royaltyKey)
	}

	// 5. Update Video Pool
	pool.TotalShares += sharesMinted
	pool.ReserveBalance += wSpent
	pool.CurrentWCount += wAmount // Public count increments by full W's backed
	pool.TotalVolumeW += wAmount
	if err := s.repo.SavePool(ctx, pool); err != nil {
		return nil, err
	}

	// 6. Update user's position
	pos, err := s.repo.GetPosition(ctx, userID, videoID)
	if err != nil {
		return nil, err
	}
	pos.SharesOwned += sharesMinted
	pos.WCostBasis += wAmount
	if err := s.repo.SavePosition(ctx, pos); err != nil {
		return nil, err
	}

	// 7. Get user's updated wallet summary
	summary, _ := s.walletService.GetSummary(ctx, userID)

	return &StakeResult{
		SharesMinted:    sharesMinted,
		WDeposited:      wAmount,
		CreatorRoyaltyW: royaltyW,
		NewVideoWCount:  pool.CurrentWCount,
		UserAvailableW:  summary.AvailableW,
	}, nil
}

// UnstakeW sells shares back to the video pool to cash out W's and take profit.
func (s *Service) UnstakeW(ctx context.Context, userID, videoID string, sharesToBurn int64, minWOut int64, idempotencyKey string) (*UnstakeResult, error) {
	if sharesToBurn <= 0 {
		return nil, errors.New("shares to burn must be greater than zero")
	}

	pool, err := s.repo.GetPool(ctx, videoID)
	if err != nil {
		return nil, err
	}

	pos, err := s.repo.GetPosition(ctx, userID, videoID)
	if err != nil || pos.SharesOwned < sharesToBurn {
		return nil, ErrInsufficientShares
	}

	// 1. Calculate gross W payout from burning shares
	grossPayout := calculateSellGross(pool.TotalShares, sharesToBurn, pool.BasePriceW, pool.SlopeScaled)
	if grossPayout > pool.ReserveBalance {
		// Cap to reserve to preserve solvency
		grossPayout = pool.ReserveBalance
	}

	// 2. Calculate 2% creator royalty on the sale
	royaltyW := (grossPayout * int64(pool.CreatorRoyaltyBps)) / 10000
	netPayout := grossPayout - royaltyW
	if netPayout < minWOut {
		return nil, ErrSlippageExceeded
	}

	// 3. Update Video Pool: reduce shares, reserve, and dynamically drop public W count!
	pool.TotalShares -= sharesToBurn
	pool.ReserveBalance -= grossPayout
	if pool.ReserveBalance < 0 {
		pool.ReserveBalance = 0
	}
	pool.CurrentWCount -= grossPayout
	if pool.CurrentWCount < 0 {
		pool.CurrentWCount = 0
	}
	pool.TotalVolumeW += grossPayout
	if err := s.repo.SavePool(ctx, pool); err != nil {
		return nil, err
	}

	// 4. Update user position
	pos.SharesOwned -= sharesToBurn
	realizedPnL := netPayout - ((pos.WCostBasis * sharesToBurn) / (pos.SharesOwned + sharesToBurn))
	pos.TotalWRealizedPnL += realizedPnL
	if pos.SharesOwned == 0 {
		pos.WCostBasis = 0
	} else {
		pos.WCostBasis -= (pos.WCostBasis * sharesToBurn) / (pos.SharesOwned + sharesToBurn)
	}
	if err := s.repo.SavePosition(ctx, pos); err != nil {
		return nil, err
	}

	// 5. Credit user's wallet with net payout
	payoutKey := fmt.Sprintf("unstake_payout:%s:%s", videoID, idempotencyKey)
	if err := s.walletService.CreditAvailable(ctx, userID, netPayout, wallet.SourceEarned, wallet.EventVideoWUnstake, "video_pool", videoID, payoutKey); err != nil {
		return nil, err
	}

	// 6. Credit creator royalty
	if royaltyW > 0 && pool.CreatorID != "" && pool.CreatorID != userID {
		royaltyKey := fmt.Sprintf("creator_royalty_sell:%s:%s", videoID, idempotencyKey)
		_ = s.walletService.CreditAvailable(ctx, pool.CreatorID, royaltyW, wallet.SourceEarned, wallet.EventCreatorRoyalty, "video_pool", videoID, royaltyKey)
	}

	summary, _ := s.walletService.GetSummary(ctx, userID)

	return &UnstakeResult{
		SharesBurned:    sharesToBurn,
		WPayout:         netPayout,
		CreatorRoyaltyW: royaltyW,
		NewVideoWCount:  pool.CurrentWCount,
		UserAvailableW:  summary.AvailableW,
	}, nil
}

// GetPosition returns a user's holding in a video pool.
func (s *Service) GetPosition(ctx context.Context, userID, videoID string) (*Position, error) {
	return s.repo.GetPosition(ctx, userID, videoID)
}

// Helper: Calculate price of share index s (0-indexed)
func sharePrice(s int64, basePrice, slopeScaled int64) int64 {
	p := basePrice + (s*slopeScaled)/10000
	if p < 1 {
		return 1
	}
	return p
}

// calculateBuyShares calculates how many whole shares can be bought with wNet
func calculateBuyShares(currentShares, wNet, basePrice, slopeScaled int64) (sharesMinted int64, wSpent int64) {
	remaining := wNet
	s := currentShares
	for {
		cost := sharePrice(s, basePrice, slopeScaled)
		if remaining < cost {
			break
		}
		remaining -= cost
		wSpent += cost
		sharesMinted++
		s++
	}
	// Return any unused dust W's or spend full net
	return sharesMinted, wSpent
}

// calculateSellGross calculates gross W redeemed when burning sharesToBurn
func calculateSellGross(currentShares, sharesToBurn, basePrice, slopeScaled int64) int64 {
	var totalGross int64
	s := currentShares - 1
	for i := int64(0); i < sharesToBurn; i++ {
		if s < 0 {
			break
		}
		totalGross += sharePrice(s, basePrice, slopeScaled)
		s--
	}
	return totalGross
}
