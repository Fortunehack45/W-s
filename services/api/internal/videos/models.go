package videos

import (
	"time"

	"github.com/ws-platform/api/internal/videopools"
)

// VideoStatus represents the state of video ingestion and publishing.
type VideoStatus string

const (
	StatusDraft      VideoStatus = "draft"
	StatusUploading  VideoStatus = "uploading"
	StatusProcessing VideoStatus = "processing"
	StatusPublished  VideoStatus = "published"
	StatusRejected   VideoStatus = "rejected"
	StatusRemoved    VideoStatus = "removed"
	StatusFailed     VideoStatus = "failed"
)

// Video represents a vertical short-form video in the platform.
type Video struct {
	ID              string      `json:"id"`
	CreatorID       string      `json:"creatorId"`
	CreatorUsername string      `json:"creatorUsername"`
	Title           string      `json:"title"`
	Description     string      `json:"description"`
	VideoURL        string      `json:"videoUrl"`
	ThumbnailURL    string      `json:"thumbnailUrl"`
	DurationSeconds float64     `json:"durationSeconds"`
	Status          VideoStatus `json:"status"`
	ViewCount       int64       `json:"viewCount"`
	LikeCount       int64       `json:"likeCount"`
	CommentCount    int64       `json:"commentCount"`
	RepostCount     int64       `json:"repostCount"`
	ShareCount      int64       `json:"shareCount"`
	PublishedAt     *time.Time  `json:"publishedAt,omitempty"`
	CreatedAt       time.Time   `json:"createdAt"`
	UpdatedAt       time.Time   `json:"updatedAt"`
}

// VideoWithPool combines the video metadata with its dynamic W's momentum pool.
type VideoWithPool struct {
	Video
	WPool videopools.Pool `json:"wPool"`
}

// UploadSession tracks chunked, resumable TUS video uploads.
type UploadSession struct {
	ID            string    `json:"id"`
	VideoID       string    `json:"videoId"`
	UserID        string    `json:"userId"`
	ExpectedBytes int64     `json:"expectedBytes"`
	UploadedBytes int64     `json:"uploadedBytes"`
	Status        string    `json:"status"` // "active", "completed", "failed"
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// Comment represents a comment on a video.
type Comment struct {
	ID        string    `json:"id"`
	VideoID   string    `json:"videoId"`
	AuthorID  string    `json:"authorId"`
	Username  string    `json:"username"`
	ParentID  *string   `json:"parentId,omitempty"`
	Content   string    `json:"content"`
	LikeCount int64     `json:"likeCount"`
	CreatedAt time.Time `json:"createdAt"`
}

// ViewSession represents a viewer watching a video.
type ViewSession struct {
	ID                   string    `json:"id"`
	VideoID              string    `json:"videoId"`
	ViewerID             string    `json:"viewerId"`
	WatchDurationSeconds float64   `json:"watchDurationSeconds"`
	IsCompleted          bool      `json:"isCompleted"`
	IsCounted            bool      `json:"isCounted"` // False if viewer is a restricted/bot account
	IPHash               string    `json:"ipHash"`
	CreatedAt            time.Time `json:"createdAt"`
}

// Repost represents a user reposting a video into their followers' feeds.
type Repost struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	VideoID   string    `json:"videoId"`
	CreatedAt time.Time `json:"createdAt"`
}

// Save represents a bookmarked video.
type Save struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	VideoID   string    `json:"videoId"`
	CreatedAt time.Time `json:"createdAt"`
}

// SearchQuery represents a logged search keyword used to tailor the FYP algorithm.
type SearchQuery struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	QueryText string    `json:"queryText"`
	CreatedAt time.Time `json:"createdAt"`
}
