package chat

import (
	"time"
)

// ChatRoom represents the canonical persistent chat room for a video.
type ChatRoom struct {
	ID           string    `json:"id"`
	VideoID      string    `json:"videoId"`
	Title        string    `json:"title"`
	IsArchived   bool      `json:"isArchived"`
	MessageCount int64     `json:"messageCount"`
	CreatedAt    time.Time `json:"createdAt"`
}

// ChatMessage represents a message sent within a video's canonical chat room.
type ChatMessage struct {
	ID             string    `json:"id"`
	RoomID         string    `json:"roomId"`
	VideoID        string    `json:"videoId"`
	AuthorID       string    `json:"authorId"`
	AuthorUsername string    `json:"authorUsername"`
	Content        string    `json:"content"`
	Badge          string    `json:"badge"` // "⚡ Top 1 Backer", "🔥 Top 5 Backer", "Backer", or empty
	IdempotencyKey string    `json:"idempotencyKey"`
	CreatedAt      time.Time `json:"createdAt"`
}

// DirectThread represents a 1-on-1 DM channel between two users tracking daily streaks.
type DirectThread struct {
	ID                string    `json:"id"`
	User1ID           string    `json:"user1Id"`
	User2ID           string    `json:"user2Id"`
	CurrentStreakDays int       `json:"currentStreakDays"`
	LongestStreakDays int       `json:"longestStreakDays"`
	LastMessageAt     time.Time `json:"lastMessageAt"`
	LastStreakDate    string    `json:"lastStreakDate"` // YYYY-MM-DD
	CreatedAt         time.Time `json:"createdAt"`
}

// DirectMessage represents a private message within a 1-on-1 thread.
type DirectMessage struct {
	ID             string    `json:"id"`
	ThreadID       string    `json:"threadId"`
	SenderID       string    `json:"senderId"`
	SenderUsername string    `json:"senderUsername"`
	Content        string    `json:"content"`
	IdempotencyKey string    `json:"idempotencyKey"`
	IsRead         bool      `json:"isRead"`
	CreatedAt      time.Time `json:"createdAt"`
}

// SendMessageResult returns the message sent along with any streak milestone card awards.
type SendMessageResult struct {
	Message        *DirectMessage `json:"message"`
	Thread         *DirectThread  `json:"thread"`
	StreakAdvanced bool           `json:"streakAdvanced"`
	MintedCards    []string       `json:"mintedCards,omitempty"` // e.g. ["Streak Spark"]
}
