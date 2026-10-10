package wallet

import "time"

// EventType categorizes ledger transactions.
type EventType string

const (
	EventSignupBonus       EventType = "signup_bonus"
	EventPromotionalReward EventType = "promotional_reward"
	EventAchievement       EventType = "achievement"
	EventVerifiedPurchase  EventType = "verified_purchase"
	EventVideoWStake       EventType = "video_w_stake"
	EventVideoWUnstake     EventType = "video_w_unstake"
	EventCreatorRoyalty    EventType = "creator_video_royalty"
	EventAuctionBidReserve EventType = "auction_bid_reserve"
	EventAuctionBidRelease EventType = "auction_bid_release"
	EventAuctionDebit      EventType = "auction_settlement_debit"
	EventAuctionCredit     EventType = "auction_settlement_credit"
	EventRefund            EventType = "refund"
	EventAdminCorrection   EventType = "admin_correction"
)

// BalanceSource distinguishes virtual currency origins.
type BalanceSource string

const (
	SourceSignupBonus BalanceSource = "signup_bonus"
	SourceEarned      BalanceSource = "earned"
	SourcePurchased   BalanceSource = "purchased"
)

// Account represents the cached balance row for a user.
type Account struct {
	UserID             string    `json:"userId"`
	AvailableW         int64     `json:"availableW"`
	ReservedW          int64     `json:"reservedW"`
	EarnedWBalance     int64     `json:"earnedWBalance"`
	PurchasedWBalance  int64     `json:"purchasedWBalance"`
	Version            int64     `json:"version"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

// Summary is the client-facing balance representation.
type Summary struct {
	AvailableW        int64 `json:"availableW"`
	ReservedW         int64 `json:"reservedW"`
	EarnedWBalance    int64 `json:"earnedWBalance"`
	PurchasedWBalance int64 `json:"purchasedWBalance"`
}

// LedgerEntry represents an immutable financial record.
type LedgerEntry struct {
	ID             string        `json:"id"`
	UserID         string        `json:"userId"`
	EventType      EventType     `json:"eventType"`
	PointAmount    int64         `json:"pointAmount"` // positive for credit, negative for debit
	BalanceSource  BalanceSource `json:"balanceSource"`
	ReferenceType  string        `json:"referenceType"`
	ReferenceID    string        `json:"referenceId"`
	IdempotencyKey string        `json:"idempotencyKey"`
	CreatedAt      time.Time     `json:"createdAt"`
}
