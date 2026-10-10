package profiles

import (
	"context"
	"errors"
	"sync"
	"time"
)

var (
	ErrProfileNotFound   = errors.New("profile not found")
	ErrUsernameTaken     = errors.New("username is already taken")
	ErrAccountRestricted = errors.New("account is restricted")
)

// Repository defines profile storage interface.
type Repository interface {
	GetByID(ctx context.Context, id string) (*Profile, error)
	GetByUsername(ctx context.Context, username string) (*Profile, error)
	ListAll(ctx context.Context) ([]*Profile, error)
	Create(ctx context.Context, p *Profile) error
	Update(ctx context.Context, p *Profile) error
}

// MemoryRepository provides a concurrency-safe in-memory profile store for tests.
type MemoryRepository struct {
	mu       sync.RWMutex
	profiles map[string]*Profile
	byUser   map[string]string
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		profiles: make(map[string]*Profile),
		byUser:   make(map[string]string),
	}
}

func (r *MemoryRepository) ListAll(ctx context.Context) ([]*Profile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	list := make([]*Profile, 0, len(r.profiles))
	for _, p := range r.profiles {
		cpy := *p
		list = append(list, &cpy)
	}
	return list, nil
}

func (r *MemoryRepository) GetByID(ctx context.Context, id string) (*Profile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	p, ok := r.profiles[id]
	if !ok {
		return nil, ErrProfileNotFound
	}
	cpy := *p
	return &cpy, nil
}

func (r *MemoryRepository) GetByUsername(ctx context.Context, username string) (*Profile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	id, ok := r.byUser[username]
	if !ok {
		return nil, ErrProfileNotFound
	}
	p := r.profiles[id]
	cpy := *p
	return &cpy, nil
}

func (r *MemoryRepository) Create(ctx context.Context, p *Profile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, exists := r.byUser[p.Username]; exists {
		return ErrUsernameTaken
	}
	now := time.Now().UTC()
	p.CreatedAt = now
	p.UpdatedAt = now
	cpy := *p
	r.profiles[p.ID] = &cpy
	r.byUser[p.Username] = p.ID
	return nil
}

func (r *MemoryRepository) Update(ctx context.Context, p *Profile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	existing, ok := r.profiles[p.ID]
	if !ok {
		return ErrProfileNotFound
	}
	p.UpdatedAt = time.Now().UTC()
	p.CreatedAt = existing.CreatedAt
	cpy := *p
	r.profiles[p.ID] = &cpy
	return nil
}

// Service provides profile domain logic.
type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) GetProfile(ctx context.Context, userID string) (*Profile, error) {
	return s.repo.GetByID(ctx, userID)
}

func (s *Service) CreateProfile(ctx context.Context, p *Profile) error {
	if p.RestrictionStatus == "" {
		p.RestrictionStatus = RestrictionNormal
	}
	return s.repo.Create(ctx, p)
}

func (s *Service) UpdateProfile(ctx context.Context, p *Profile) error {
	return s.repo.Update(ctx, p)
}

func (s *Service) IncrementWatchMinutes(ctx context.Context, userID string, minutes int64) error {
	p, err := s.repo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	p.TotalWatchMinutes += minutes
	return s.repo.Update(ctx, p)
}

func (s *Service) BuyPremium(ctx context.Context, userID string) (*Profile, error) {
	p, err := s.repo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	expiresAt := time.Now().UTC().Add(30 * 24 * time.Hour)
	p.IsPremium = true
	p.PremiumExpiresAt = &expiresAt
	if err := s.repo.Update(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *Service) FollowUser(ctx context.Context, followerID, targetID string) error {
	follower, err := s.repo.GetByID(ctx, followerID)
	if err != nil {
		return err
	}
	target, err := s.repo.GetByID(ctx, targetID)
	if err != nil {
		return err
	}

	target.FollowersCount++
	if follower.IsPremium {
		target.VerifiedFollowersCount++
	}
	follower.FollowingCount++

	if err := s.repo.Update(ctx, target); err != nil {
		return err
	}
	return s.repo.Update(ctx, follower)
}

func (s *Service) ListAllProfiles(ctx context.Context) ([]*Profile, error) {
	return s.repo.ListAll(ctx)
}

func (s *Service) SetRestriction(ctx context.Context, userID string, status RestrictionStatus) error {
	p, err := s.repo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	p.RestrictionStatus = status
	if status == RestrictionRestricted {
		p.BotRiskScore = 99.0
	} else {
		p.BotRiskScore = 5.0
	}
	return s.repo.Update(ctx, p)
}

func (s *Service) SetVerified(ctx context.Context, userID string, isVerified bool) error {
	p, err := s.repo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	p.IsVerified = isVerified
	return s.repo.Update(ctx, p)
}
