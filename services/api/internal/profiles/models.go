package profiles

import "time"

// RestrictionStatus represents account restriction states.
type RestrictionStatus string

const (
	RestrictionNormal       RestrictionStatus = "normal"
	RestrictionUnderReview  RestrictionStatus = "under_review"
	RestrictionShadowbanned RestrictionStatus = "shadowbanned"
	RestrictionRestricted   RestrictionStatus = "restricted"
	RestrictionSuspended    RestrictionStatus = "suspended"
)

// Profile represents a platform user's social profile.
type Profile struct {
	ID                     string            `json:"id"`
	Username               string            `json:"username"`
	DisplayName            string            `json:"displayName"`
	AvatarURL              string            `json:"avatarUrl"`
	Bio                    string            `json:"bio"`
	VideoCount             int               `json:"videoCount"`
	FollowersCount         int               `json:"followersCount"`
	FollowingCount         int               `json:"followingCount"`
	NetWEarned             int64             `json:"netWEarned"` // Lifetime Net Realized W's Gained + Royalties
	IsVerified             bool              `json:"isVerified"`
	IsPremium              bool              `json:"isPremium"`
	PremiumExpiresAt       *time.Time        `json:"premiumExpiresAt,omitempty"`
	VerifiedFollowersCount int               `json:"verifiedFollowersCount"`
	TotalWatchMinutes      int64             `json:"totalWatchMinutes"`
	IsMonetizationApproved bool              `json:"isMonetizationApproved"`
	RestrictionStatus      RestrictionStatus `json:"restrictionStatus"`
	RestrictedUntil        *time.Time        `json:"restrictedUntil,omitempty"`
	BotRiskScore           float64           `json:"botRiskScore"`
	IsSuspended            bool              `json:"isSuspended"`
	CreatedAt              time.Time         `json:"createdAt"`
	UpdatedAt              time.Time         `json:"updatedAt"`
}

// IsReadOnlyPreview returns true if account actions (posting, commenting, staking) are restricted.
func (p *Profile) IsReadOnlyPreview() bool {
	return p.RestrictionStatus == RestrictionRestricted ||
		p.RestrictionStatus == RestrictionSuspended ||
		p.RestrictionStatus == RestrictionShadowbanned
}
