package videopools

import "time"

// Pool represents the live dynamic liquidity gauge for a video.
type Pool struct {
	VideoID           string    `json:"videoId"`
	CreatorID         string    `json:"creatorId"`
	CurrentWCount     int64     `json:"currentWCount"` // Publicly displayed active W's
	ReserveBalance    int64     `json:"reserveBalance"` // Authoritative W's backing the pool
	TotalShares       int64     `json:"totalShares"`
	BasePriceW        int64     `json:"basePriceW"` // Default: 1 W
	SlopeScaled       int64     `json:"slopeScaled"` // e.g. 100 representing 0.01
	CreatorRoyaltyBps int       `json:"creatorRoyaltyBps"` // 200 = 2%
	TotalVolumeW      int64     `json:"totalVolumeW"`
	Version           int64     `json:"version"`
	UpdatedAt         time.Time `json:"updatedAt"`
}

// Position tracks a user's shares in a video pool.
type Position struct {
	ID                 string    `json:"id"`
	UserID             string    `json:"userId"`
	VideoID            string    `json:"videoId"`
	SharesOwned        int64     `json:"sharesOwned"`
	WCostBasis         int64     `json:"wCostBasis"`
	TotalWRealizedPnL  int64     `json:"totalWRealizedPnl"`
	CreatedAt          time.Time `json:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

// StakeResult contains output of a successful stake.
type StakeResult struct {
	SharesMinted    int64 `json:"sharesMinted"`
	WDeposited      int64 `json:"wDeposited"`
	CreatorRoyaltyW int64 `json:"creatorRoyaltyW"`
	NewVideoWCount  int64 `json:"newVideoWCount"`
	UserAvailableW  int64 `json:"userAvailableW"`
}

// UnstakeResult contains output of a successful cash-out.
type UnstakeResult struct {
	SharesBurned    int64 `json:"sharesBurned"`
	WPayout         int64 `json:"wPayout"`
	CreatorRoyaltyW int64 `json:"creatorRoyaltyW"`
	NewVideoWCount  int64 `json:"newVideoWCount"`
	UserAvailableW  int64 `json:"userAvailableW"`
}
