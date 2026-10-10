package cards

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
)

type Rarity string

const (
	RarityCommon    Rarity = "common"
	RarityRare      Rarity = "rare"
	RarityEpic      Rarity = "epic"
	RarityLegendary Rarity = "legendary"
)

// CardDefinition defines the blueprint and artwork for collectible cards.
type CardDefinition struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Rarity      Rarity    `json:"rarity"`
	ArtworkURL  string    `json:"artworkUrl"`
	Series      string    `json:"series"`
	TotalMinted int       `json:"totalMinted"`
	CreatedAt   time.Time `json:"createdAt"`
}

// CardInstance represents an individual numbered NFT-style card owned by a user.
type CardInstance struct {
	ID                 string    `json:"id"`
	CardDefinitionID   string    `json:"cardDefinitionId"`
	OwnerID            string    `json:"ownerId"`
	SerialNumber       int       `json:"serialNumber"`
	Status             string    `json:"status"` // owned, listed, retired
	AcquisitionMethod  string    `json:"acquisitionMethod"`
	AcquiredAt         time.Time `json:"acquiredAt"`
}

// CardInstanceWithDef combines the instance with its full artwork and definition.
type CardInstanceWithDef struct {
	CardInstance
	Definition CardDefinition `json:"definition"`
}

var (
	ErrDefinitionNotFound = errors.New("card definition not found")
	ErrCardNotFound       = errors.New("card instance not found")
)

type Service interface {
	GetDefinitions(ctx context.Context) ([]*CardDefinition, error)
	GetDefinitionByName(ctx context.Context, name string) (*CardDefinition, error)
	MintCard(ctx context.Context, defName, ownerID, acquisitionMethod string) (*CardInstanceWithDef, error)
	GetUserCards(ctx context.Context, ownerID string) ([]*CardInstanceWithDef, error)
	GetInstance(ctx context.Context, instanceID string) (*CardInstanceWithDef, error)
	UpdateCardStatus(ctx context.Context, instanceID string, status string) error
	TransferOwnership(ctx context.Context, instanceID, newOwnerID, acquisitionMethod string) error
}

type inMemoryCardService struct {
	mu          sync.RWMutex
	definitions map[string]*CardDefinition       // key: name
	instances   map[string]*CardInstance         // key: instanceID
	userCards   map[string][]*CardInstance       // key: ownerID
}

func NewInMemoryCardService() Service {
	s := &inMemoryCardService{
		definitions: make(map[string]*CardDefinition),
		instances:   make(map[string]*CardInstance),
		userCards:   make(map[string][]*CardInstance),
	}

	// Seed streak rewards definitions
	now := time.Now().UTC()
	s.definitions["Streak Spark"] = &CardDefinition{
		ID:          "def-streak-7",
		Name:        "Streak Spark",
		Description: "Awarded for completing a 7-day messaging streak.",
		Rarity:      RarityCommon,
		ArtworkURL:  "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400",
		Series:      "Streak Pioneers",
		TotalMinted: 0,
		CreatedAt:   now,
	}

	s.definitions["Flame Keeper"] = &CardDefinition{
		ID:          "def-streak-30",
		Name:        "Flame Keeper",
		Description: "Awarded for sustaining a 30-day messaging streak.",
		Rarity:      RarityRare,
		ArtworkURL:  "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400",
		Series:      "Streak Pioneers",
		TotalMinted: 0,
		CreatedAt:   now,
	}

	s.definitions["Century Blaze"] = &CardDefinition{
		ID:          "def-streak-100",
		Name:        "Century Blaze",
		Description: "Awarded for achieving a 100-day messaging streak.",
		Rarity:      RarityEpic,
		ArtworkURL:  "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=400",
		Series:      "Streak Legends",
		TotalMinted: 0,
		CreatedAt:   now,
	}

	s.definitions["Immortal Bond"] = &CardDefinition{
		ID:          "def-streak-200",
		Name:        "Immortal Bond",
		Description: "Awarded for reaching the pinnacle 200-day messaging streak.",
		Rarity:      RarityLegendary,
		ArtworkURL:  "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400",
		Series:      "Streak Legends",
		TotalMinted: 0,
		CreatedAt:   now,
	}

	return s
}

func (s *inMemoryCardService) GetDefinitions(ctx context.Context) ([]*CardDefinition, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	res := make([]*CardDefinition, 0, len(s.definitions))
	for _, d := range s.definitions {
		res = append(res, d)
	}
	return res, nil
}

func (s *inMemoryCardService) GetDefinitionByName(ctx context.Context, name string) (*CardDefinition, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	def, exists := s.definitions[name]
	if !exists {
		return nil, ErrDefinitionNotFound
	}
	return def, nil
}

func (s *inMemoryCardService) MintCard(ctx context.Context, defName, ownerID, acquisitionMethod string) (*CardInstanceWithDef, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	def, exists := s.definitions[defName]
	if !exists {
		return nil, ErrDefinitionNotFound
	}

	def.TotalMinted++
	serial := def.TotalMinted
	instID := uuid.New().String()
	now := time.Now().UTC()

	inst := &CardInstance{
		ID:                instID,
		CardDefinitionID:  def.ID,
		OwnerID:           ownerID,
		SerialNumber:      serial,
		Status:            "owned",
		AcquisitionMethod: acquisitionMethod,
		AcquiredAt:        now,
	}

	s.instances[instID] = inst
	s.userCards[ownerID] = append(s.userCards[ownerID], inst)

	return &CardInstanceWithDef{
		CardInstance: *inst,
		Definition:   *def,
	}, nil
}

func (s *inMemoryCardService) GetUserCards(ctx context.Context, ownerID string) ([]*CardInstanceWithDef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	cards := s.userCards[ownerID]
	res := make([]*CardInstanceWithDef, 0, len(cards))

	for _, c := range cards {
		var def CardDefinition
		for _, d := range s.definitions {
			if d.ID == c.CardDefinitionID {
				def = *d
				break
			}
		}
		res = append(res, &CardInstanceWithDef{
			CardInstance: *c,
			Definition:   def,
		})
	}

	return res, nil
}

func (s *inMemoryCardService) GetInstance(ctx context.Context, instanceID string) (*CardInstanceWithDef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	inst, exists := s.instances[instanceID]
	if !exists {
		return nil, ErrCardNotFound
	}
	var def CardDefinition
	for _, d := range s.definitions {
		if d.ID == inst.CardDefinitionID {
			def = *d
			break
		}
	}
	return &CardInstanceWithDef{
		CardInstance: *inst,
		Definition:   def,
	}, nil
}

func (s *inMemoryCardService) UpdateCardStatus(ctx context.Context, instanceID string, status string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	inst, exists := s.instances[instanceID]
	if !exists {
		return ErrCardNotFound
	}
	inst.Status = status
	return nil
}

func (s *inMemoryCardService) TransferOwnership(ctx context.Context, instanceID, newOwnerID, acquisitionMethod string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	inst, exists := s.instances[instanceID]
	if !exists {
		return ErrCardNotFound
	}

	oldOwnerID := inst.OwnerID

	// Remove from old owner's list
	var updatedOld []*CardInstance
	for _, c := range s.userCards[oldOwnerID] {
		if c.ID != instanceID {
			updatedOld = append(updatedOld, c)
		}
	}
	s.userCards[oldOwnerID] = updatedOld

	// Update instance
	inst.OwnerID = newOwnerID
	inst.Status = "owned"
	inst.AcquisitionMethod = acquisitionMethod
	inst.AcquiredAt = time.Now().UTC()

	// Append to new owner
	s.userCards[newOwnerID] = append(s.userCards[newOwnerID], inst)
	return nil
}

