package wallet

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInsufficientBalance = errors.New("insufficient available balance")
	ErrAccountNotFound     = errors.New("wallet account not found")
	ErrDuplicateRequest    = errors.New("duplicate request")
)

// Repository manages persistence for wallet accounts and ledger entries.
type Repository interface {
	GetAccount(ctx context.Context, userID string) (*Account, error)
	SaveAccount(ctx context.Context, acc *Account) error
	AddLedgerEntry(ctx context.Context, entry *LedgerEntry) error
	HasIdempotencyKey(ctx context.Context, key string) bool
	GetLedger(ctx context.Context, userID string) ([]LedgerEntry, error)
}

// MemoryRepository is a concurrency-safe in-memory store for unit and integration testing.
type MemoryRepository struct {
	mu          sync.RWMutex
	accounts    map[string]*Account
	ledger      map[string][]LedgerEntry
	idempotency map[string]bool
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		accounts:    make(map[string]*Account),
		ledger:      make(map[string][]LedgerEntry),
		idempotency: make(map[string]bool),
	}
}

func (r *MemoryRepository) GetAccount(ctx context.Context, userID string) (*Account, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	acc, ok := r.accounts[userID]
	if !ok {
		return nil, ErrAccountNotFound
	}
	cpy := *acc
	return &cpy, nil
}

func (r *MemoryRepository) SaveAccount(ctx context.Context, acc *Account) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	acc.UpdatedAt = time.Now().UTC()
	acc.Version++
	cpy := *acc
	r.accounts[acc.UserID] = &cpy
	return nil
}

func (r *MemoryRepository) AddLedgerEntry(ctx context.Context, entry *LedgerEntry) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.idempotency[entry.IdempotencyKey] {
		return ErrDuplicateRequest
	}
	r.idempotency[entry.IdempotencyKey] = true
	entry.CreatedAt = time.Now().UTC()
	if entry.ID == "" {
		entry.ID = uuid.NewString()
	}
	r.ledger[entry.UserID] = append(r.ledger[entry.UserID], *entry)
	return nil
}

func (r *MemoryRepository) HasIdempotencyKey(ctx context.Context, key string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.idempotency[key]
}

func (r *MemoryRepository) GetLedger(ctx context.Context, userID string) ([]LedgerEntry, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	entries, ok := r.ledger[userID]
	if !ok {
		return []LedgerEntry{}, nil
	}
	res := make([]LedgerEntry, len(entries))
	copy(res, entries)
	return res, nil
}

// Service coordinates authoritative wallet actions.
type Service struct {
	repo         Repository
	signupBonusW int64
}

func NewService(repo Repository, signupBonusW int64) *Service {
	return &Service{
		repo:         repo,
		signupBonusW: signupBonusW,
	}
}

// GetSummary retrieves the user's available balance and reserves.
func (s *Service) GetSummary(ctx context.Context, userID string) (*Summary, error) {
	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrAccountNotFound) {
			return &Summary{}, nil
		}
		return nil, err
	}
	return &Summary{
		AvailableW:        acc.AvailableW,
		ReservedW:         acc.ReservedW,
		EarnedWBalance:    acc.EarnedWBalance,
		PurchasedWBalance: acc.PurchasedWBalance,
	}, nil
}

// GrantSignupBonus idempotently credits the initial 50 W's to a newly registered user.
func (s *Service) GrantSignupBonus(ctx context.Context, userID string) (*Summary, error) {
	idempotencyKey := fmt.Sprintf("signup_bonus:%s", userID)

	// Check if already awarded
	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return s.GetSummary(ctx, userID)
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrAccountNotFound) {
			acc = &Account{
				UserID:            userID,
				AvailableW:        0,
				ReservedW:         0,
				EarnedWBalance:    0,
				PurchasedWBalance: 0,
			}
		} else {
			return nil, err
		}
	}

	// Double-entry mutation
	acc.AvailableW += s.signupBonusW
	acc.EarnedWBalance += s.signupBonusW

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      EventSignupBonus,
		PointAmount:    s.signupBonusW,
		BalanceSource:  SourceSignupBonus,
		ReferenceType:  "signup",
		ReferenceID:    userID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		if errors.Is(err, ErrDuplicateRequest) {
			return s.GetSummary(ctx, userID)
		}
		return nil, err
	}

	if err := s.repo.SaveAccount(ctx, acc); err != nil {
		return nil, err
	}

	return &Summary{
		AvailableW:        acc.AvailableW,
		ReservedW:         acc.ReservedW,
		EarnedWBalance:    acc.EarnedWBalance,
		PurchasedWBalance: acc.PurchasedWBalance,
	}, nil
}

// DebitAvailable debits available W's atomically with an immutable ledger entry.
func (s *Service) DebitAvailable(ctx context.Context, userID string, amount int64, eventType EventType, refType, refID, idempotencyKey string) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}

	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return nil // Idempotent success
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		return err
	}

	if acc.AvailableW < amount {
		return ErrInsufficientBalance
	}

	acc.AvailableW -= amount
	// Deduct from earned first, then purchased
	if acc.EarnedWBalance >= amount {
		acc.EarnedWBalance -= amount
	} else {
		remainder := amount - acc.EarnedWBalance
		acc.EarnedWBalance = 0
		acc.PurchasedWBalance -= remainder
	}

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      eventType,
		PointAmount:    -amount,
		BalanceSource:  SourceEarned,
		ReferenceType:  refType,
		ReferenceID:    refID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		return err
	}

	return s.repo.SaveAccount(ctx, acc)
}

// CreditAvailable credits W's to the user's available and earned balance.
func (s *Service) CreditAvailable(ctx context.Context, userID string, amount int64, source BalanceSource, eventType EventType, refType, refID, idempotencyKey string) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}

	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return nil
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrAccountNotFound) {
			acc = &Account{UserID: userID}
		} else {
			return err
		}
	}

	acc.AvailableW += amount
	if source == SourcePurchased {
		acc.PurchasedWBalance += amount
	} else {
		acc.EarnedWBalance += amount
	}

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      eventType,
		PointAmount:    amount,
		BalanceSource:  source,
		ReferenceType:  refType,
		ReferenceID:    refID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		return err
	}

	return s.repo.SaveAccount(ctx, acc)
}

// GetLedger retrieves the user's audit log.
func (s *Service) GetLedger(ctx context.Context, userID string) ([]LedgerEntry, error) {
	return s.repo.GetLedger(ctx, userID)
}

// ReserveAvailable moves W's from AvailableW to ReservedW for auction bid escrow.
func (s *Service) ReserveAvailable(ctx context.Context, userID string, amount int64, eventType EventType, refType, refID, idempotencyKey string) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}
	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return nil
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		return err
	}

	if acc.AvailableW < amount {
		return ErrInsufficientBalance
	}

	acc.AvailableW -= amount
	acc.ReservedW += amount

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      eventType,
		PointAmount:    -amount,
		BalanceSource:  SourceEarned,
		ReferenceType:  refType,
		ReferenceID:    refID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		return err
	}

	return s.repo.SaveAccount(ctx, acc)
}

// ReleaseReserved returns previously reserved funds back to AvailableW (e.g. when outbid).
func (s *Service) ReleaseReserved(ctx context.Context, userID string, amount int64, eventType EventType, refType, refID, idempotencyKey string) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}
	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return nil
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		return err
	}

	if acc.ReservedW < amount {
		return errors.New("insufficient reserved funds to release")
	}

	acc.ReservedW -= amount
	acc.AvailableW += amount

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      eventType,
		PointAmount:    amount,
		BalanceSource:  SourceEarned,
		ReferenceType:  refType,
		ReferenceID:    refID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		return err
	}

	return s.repo.SaveAccount(ctx, acc)
}

// FinalizeDebitReserved permanently consumes reserved W's upon auction winning settlement.
func (s *Service) FinalizeDebitReserved(ctx context.Context, userID string, amount int64, eventType EventType, refType, refID, idempotencyKey string) error {
	if amount <= 0 {
		return errors.New("amount must be positive")
	}
	if s.repo.HasIdempotencyKey(ctx, idempotencyKey) {
		return nil
	}

	acc, err := s.repo.GetAccount(ctx, userID)
	if err != nil {
		return err
	}

	if acc.ReservedW < amount {
		return errors.New("insufficient reserved funds to finalize")
	}

	acc.ReservedW -= amount
	if acc.EarnedWBalance >= amount {
		acc.EarnedWBalance -= amount
	} else {
		remainder := amount - acc.EarnedWBalance
		acc.EarnedWBalance = 0
		acc.PurchasedWBalance -= remainder
	}

	entry := &LedgerEntry{
		UserID:         userID,
		EventType:      eventType,
		PointAmount:    -amount,
		BalanceSource:  SourceEarned,
		ReferenceType:  refType,
		ReferenceID:    refID,
		IdempotencyKey: idempotencyKey,
	}

	if err := s.repo.AddLedgerEntry(ctx, entry); err != nil {
		return err
	}

	return s.repo.SaveAccount(ctx, acc)
}

