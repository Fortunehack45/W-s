package admin

import (
	"time"
)

// PlatformStats aggregates real-time health and economy metrics across W's.
type PlatformStats struct {
	TotalUsers          int   `json:"totalUsers"`
	VerifiedUsers       int   `json:"verifiedUsers"`
	RestrictedUsers     int   `json:"restrictedUsers"`
	TotalVideos         int   `json:"totalVideos"`
	TotalComments       int   `json:"totalComments"`
	TotalVideoViews     int64 `json:"totalVideoViews"`
	ActiveStreaks       int   `json:"activeStreaks"`
	TotalCardsMinted    int   `json:"totalCardsMinted"`
	ActiveAuctions      int   `json:"activeAuctions"`
	TotalAdCampaigns    int   `json:"totalAdCampaigns"`
	TotalAdRevenueCents int64 `json:"totalAdRevenueCents"`
}

// AdminUserView represents an enriched user record for administrative inspection.
type AdminUserView struct {
	ID                     string    `json:"id"`
	Username               string    `json:"username"`
	DisplayName            string    `json:"displayName"`
	IsVerified             bool      `json:"isVerified"`
	IsPremium              bool      `json:"isPremium"`
	RestrictionStatus      string    `json:"restrictionStatus"`
	BotRiskScore           float64   `json:"botRiskScore"`
	FollowersCount         int64     `json:"followersCount"`
	VerifiedFollowersCount int64     `json:"verifiedFollowersCount"`
	FollowingCount         int64     `json:"followingCount"`
	TotalWatchMinutes      int64     `json:"totalWatchMinutes"`
	TotalEarnedW           int64     `json:"totalEarnedW"`
	VideoCount             int       `json:"videoCount"`
	CreatedAt              time.Time `json:"createdAt"`
}

// AdminCommentView presents a comment alongside spam velocity metrics.
type AdminCommentView struct {
	ID             string    `json:"id"`
	VideoID        string    `json:"videoId"`
	AuthorID       string    `json:"authorId"`
	AuthorUsername string    `json:"authorUsername"`
	Content        string    `json:"content"`
	SpamVelocity   int       `json:"spamVelocity"`
	IsFlagged      bool      `json:"isFlagged"`
	CreatedAt      time.Time `json:"createdAt"`
}

// AdminActivityEvent represents an action in the platform's audit trail.
type AdminActivityEvent struct {
	ID        string    `json:"id"`
	Type      string    `json:"type"` // "upload", "stake", "comment", "dm", "bid", "restriction"
	UserID    string    `json:"userId"`
	Username  string    `json:"username"`
	Details   string    `json:"details"`
	Timestamp time.Time `json:"timestamp"`
}
