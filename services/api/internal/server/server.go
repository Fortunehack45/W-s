package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/ws-platform/api/internal/admin"
	"github.com/ws-platform/api/internal/ads"
	"github.com/ws-platform/api/internal/auth"
	"github.com/ws-platform/api/internal/auctions"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/chat"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/predictions"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

type Server struct {
	router            *chi.Mux
	profileService    *profiles.Service
	walletService     *wallet.Service
	poolService       *videopools.Service
	videoService      videos.Service
	cardsService      cards.Service
	chatService       chat.Service
	adsService        ads.Service
	auctionService    auctions.Service
	predictionService predictions.Service
	antiBotEngine     *moderation.AntiBotEngine
	adminService      admin.Service
	adminHandler      *admin.Handler
	authMiddleware    *auth.Middleware
}

func NewServer(
	profileService *profiles.Service,
	walletService *wallet.Service,
	poolService *videopools.Service,
	videoService videos.Service,
	cardsService cards.Service,
	chatService chat.Service,
	adsService ads.Service,
	auctionService auctions.Service,
	predictionService predictions.Service,
	antiBotEngine *moderation.AntiBotEngine,
	authMiddleware *auth.Middleware,
) *Server {
	adminSvc := admin.NewService(profileService, videoService, chatService, poolService, walletService, adsService, antiBotEngine)
	adminHdl := admin.NewHandler(adminSvc)

	s := &Server{
		router:            chi.NewRouter(),
		profileService:    profileService,
		walletService:     walletService,
		poolService:       poolService,
		videoService:      videoService,
		cardsService:      cardsService,
		chatService:       chatService,
		adsService:        adsService,
		auctionService:    auctionService,
		predictionService: predictionService,
		antiBotEngine:     antiBotEngine,
		adminService:      adminSvc,
		adminHandler:      adminHdl,
		authMiddleware:    authMiddleware,
	}

	s.setupRoutes()
	return s
}

func (s *Server) Router() http.Handler {
	return s.router
}

func (s *Server) AdminService() admin.Service {
	return s.adminService
}

func (s *Server) setupRoutes() {
	s.router.Use(middleware.RequestID)
	s.router.Use(middleware.RealIP)
	s.router.Use(middleware.Logger)
	s.router.Use(middleware.Recoverer)

	// Admin Web Console and Admin APIs
	s.adminHandler.RegisterRoutes(s.router)

	// Health check
	s.router.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	// Public video feeds, video lookup, comments, pool metrics, and card definitions
	s.router.Get("/api/v1/videos/fyp", s.handleGetFYP)
	s.router.Get("/api/v1/videos/{videoId}", s.handleGetVideo)
	s.router.Get("/api/v1/videos/{videoId}/w/pool", s.handleGetVideoPool)
	s.router.Get("/api/v1/videos/{videoId}/comments", s.handleListComments)
	s.router.Get("/api/v1/videos/{videoId}/chat", s.handleListVideoChat)
	s.router.Get("/api/v1/cards/definitions", s.handleGetCardDefinitions)
	s.router.Get("/api/v1/ads/active", s.handleListActiveAdCampaigns)
	s.router.Get("/api/v1/auctions/active", s.handleListActiveAuctions)
	s.router.Get("/api/v1/auctions/{listingId}", s.handleGetAuction)
	s.router.Get("/api/v1/predictions/markets", s.handleListPredictionMarkets)
	s.router.Get("/api/v1/predictions/markets/{marketId}", s.handleGetPredictionMarket)

	// Authenticated routes
	s.router.Group(func(r chi.Router) {
		r.Use(s.authMiddleware.Handler)

		r.Get("/api/v1/me", s.handleGetMe)
		r.Post("/api/v1/auth/signup-bonus", s.handleSignupBonus)

		r.Get("/api/v1/wallet", s.handleGetWallet)
		r.Get("/api/v1/wallet/ledger", s.handleGetLedger)

		r.Post("/api/v1/videos/{videoId}/w/stake", s.handleStakeW)
		r.Post("/api/v1/videos/{videoId}/w/unstake", s.handleUnstakeW)
		r.Get("/api/v1/videos/{videoId}/w/position", s.handleGetPosition)

		// Milestone 2: Upload, Engagement, and Personalization
		r.Post("/api/v1/videos/upload/init", s.handleInitUpload)
		r.Patch("/api/v1/videos/upload/{uploadId}", s.handleAppendChunk)
		r.Post("/api/v1/videos/{videoId}/views", s.handleRecordView)
		r.Post("/api/v1/videos/{videoId}/comments", s.handlePostComment)
		r.Post("/api/v1/videos/{videoId}/repost", s.handleRepostVideo)
		r.Post("/api/v1/videos/{videoId}/save", s.handleSaveVideo)
		r.Post("/api/v1/users/me/search-history", s.handleRecordSearch)

		// Milestone 3: Canonical Video Chat, Direct Messaging, Streaks, and Cards
		r.Post("/api/v1/videos/{videoId}/chat", s.handleSendVideoChat)
		r.Get("/api/v1/chat/threads", s.handleListUserThreads)
		r.Post("/api/v1/chat/threads", s.handleCreateDirectThread)
		r.Get("/api/v1/chat/threads/{threadId}/messages", s.handleListDirectMessages)
		r.Post("/api/v1/chat/threads/{threadId}/messages", s.handleSendDirectMessage)
		r.Get("/api/v1/cards/my", s.handleGetMyCards)

		// Milestone 4: Premium, Ads, and Creator Monetization
		r.Post("/api/v1/profiles/premium/buy", s.handleBuyPremium)
		r.Post("/api/v1/profiles/{targetId}/follow", s.handleFollowUser)
		r.Get("/api/v1/monetization/summary", s.handleGetMonetizationSummary)
		r.Post("/api/v1/monetization/apply", s.handleApplyMonetization)
		r.Post("/api/v1/monetization/payouts", s.handleRequestPayout)
		r.Post("/api/v1/ads/campaigns", s.handleCreateAdCampaign)
		r.Get("/api/v1/ads/campaigns/{campaignId}", s.handleGetAdCampaign)
		r.Get("/api/v1/ads/campaigns", s.handleListActiveAdCampaigns)
		r.Post("/api/v1/ads/campaigns/{campaignId}/impressions", s.handleRecordAdImpression)
		r.Post("/api/v1/ads/campaigns/{campaignId}/click", s.handleRecordAdClick)

		// Milestone 5 & 6: English Auction Marketplace
		r.Post("/api/v1/auctions/listings", s.handleCreateAuctionListing)
		r.Post("/api/v1/auctions/{listingId}/bid", s.handlePlaceAuctionBid)
		r.Post("/api/v1/auctions/{listingId}/settle", s.handleSettleAuction)
		r.Post("/api/v1/auctions/{listingId}/cancel", s.handleCancelAuctionListing)

		// Milestone 7: Call It Community Predictions
		r.Post("/api/v1/predictions/markets", s.handleCreatePredictionMarket)
		r.Post("/api/v1/predictions/markets/{marketId}/predict", s.handlePlacePrediction)
		r.Post("/api/v1/predictions/markets/{marketId}/resolve", s.handleResolvePredictionMarket)
		r.Get("/api/v1/predictions/my", s.handleGetMyPredictions)

		r.Get("/api/v1/moderation/status/me", s.handleGetModerationStatus)
		r.Post("/api/v1/moderation/appeals", s.handleSubmitAppeal)
	})
}

func (s *Server) handleGetMe(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	p, err := s.profileService.GetProfile(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Profile not found")
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (s *Server) handleSignupBonus(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	summary, err := s.walletService.GrantSignupBonus(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, summary)
}

func (s *Server) handleGetWallet(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	summary, err := s.walletService.GetSummary(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, summary)
}

func (s *Server) handleGetLedger(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	entries, err := s.walletService.GetLedger(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"entries": entries})
}

func (s *Server) handleGetVideoPool(w http.ResponseWriter, r *http.Request) {
	videoID := chi.URLParam(r, "videoId")
	pool, err := s.poolService.GetPool(r.Context(), videoID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Video pool not found")
		return
	}
	writeJSON(w, http.StatusOK, pool)
}

type StakeRequest struct {
	WAmount        int64  `json:"wAmount"`
	MinSharesOut   int64  `json:"minSharesOut"`
	IdempotencyKey string `json:"idempotencyKey"`
}

func (s *Server) handleStakeW(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	// Verify account is not in Read-Only Preview mode
	p, err := s.profileService.GetProfile(r.Context(), userID)
	if err == nil && p.IsReadOnlyPreview() {
		writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", "Account is restricted to read-only preview mode")
		return
	}

	var req StakeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	res, err := s.poolService.StakeW(r.Context(), userID, videoID, req.WAmount, req.MinSharesOut, req.IdempotencyKey)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "STAKE_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, res)
}

type UnstakeRequest struct {
	SharesAmount   int64  `json:"sharesAmount"`
	MinWOut        int64  `json:"minWOut"`
	IdempotencyKey string `json:"idempotencyKey"`
}

func (s *Server) handleUnstakeW(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	var req UnstakeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	res, err := s.poolService.UnstakeW(r.Context(), userID, videoID, req.SharesAmount, req.MinWOut, req.IdempotencyKey)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "UNSTAKE_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (s *Server) handleGetPosition(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")
	pos, err := s.poolService.GetPosition(r.Context(), userID, videoID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, pos)
}

func (s *Server) handleGetModerationStatus(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	p, err := s.profileService.GetProfile(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Profile not found")
		return
	}

	appeal := s.antiBotEngine.GetUserAppeal(r.Context(), userID)
	activeAppealID := ""
	if appeal != nil {
		activeAppealID = appeal.ID
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"restrictionStatus": p.RestrictionStatus,
		"isReadOnlyPreview": p.IsReadOnlyPreview(),
		"activeAppealId":    activeAppealID,
	})
}

type AppealRequest struct {
	AppealMessage string `json:"appealMessage"`
}

func (s *Server) handleSubmitAppeal(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req AppealRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	appeal, err := s.antiBotEngine.SubmitAppeal(r.Context(), userID, req.AppealMessage)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "APPEAL_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, appeal)
}

func (s *Server) handleGetFYP(w http.ResponseWriter, r *http.Request) {
	viewerID, _ := auth.UserIDFromContext(r.Context())
	if viewerID == "" {
		viewerID = r.URL.Query().Get("viewerId")
	}

	limit := 10
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	offset := 0
	if o := r.URL.Query().Get("offset"); o != "" {
		if parsed, err := strconv.Atoi(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	items, err := s.videoService.GetFYP(r.Context(), viewerID, limit, offset)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"videos": items})
}

func (s *Server) handleGetVideo(w http.ResponseWriter, r *http.Request) {
	videoID := chi.URLParam(r, "videoId")
	video, err := s.videoService.GetVideo(r.Context(), videoID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Video not found")
		return
	}
	writeJSON(w, http.StatusOK, video)
}

func (s *Server) handleListComments(w http.ResponseWriter, r *http.Request) {
	videoID := chi.URLParam(r, "videoId")
	comments, err := s.videoService.ListComments(r.Context(), videoID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"comments": comments})
}

type InitUploadRequest struct {
	Title         string `json:"title"`
	Description   string `json:"description"`
	ExpectedBytes int64  `json:"expectedBytes"`
}

func (s *Server) handleInitUpload(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req InitUploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	p, err := s.profileService.GetProfile(r.Context(), userID)
	username := "creator"
	if err == nil && p != nil {
		username = p.Username
	}

	video, upload, err := s.videoService.InitUpload(r.Context(), userID, username, req.Title, req.Description, req.ExpectedBytes)
	if err != nil {
		if err == videos.ErrAccountRestricted {
			writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", err.Error())
			return
		}
		writeJSONError(w, http.StatusBadRequest, "UPLOAD_INIT_FAILED", err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"video":         video,
		"uploadSession": upload,
	})
}

func (s *Server) handleAppendChunk(w http.ResponseWriter, r *http.Request) {
	uploadID := chi.URLParam(r, "uploadId")
	offsetStr := r.Header.Get("Upload-Offset")
	offset, err := strconv.ParseInt(offsetStr, 10, 64)
	if err != nil {
		offset = 0
	}

	chunkData, err := io.ReadAll(r.Body)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Could not read chunk data")
		return
	}

	session, err := s.videoService.AppendChunk(r.Context(), uploadID, offset, chunkData)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "CHUNK_FAILED", err.Error())
		return
	}

	writeJSON(w, http.StatusOK, session)
}

type RecordViewRequest struct {
	WatchDurationSeconds float64 `json:"watchDurationSeconds"`
	IsCompleted          bool    `json:"isCompleted"`
}

func (s *Server) handleRecordView(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	var req RecordViewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	ipHash := r.RemoteAddr
	session, err := s.videoService.RecordView(r.Context(), videoID, userID, req.WatchDurationSeconds, req.IsCompleted, ipHash)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}

	writeJSON(w, http.StatusOK, session)
}

type PostCommentRequest struct {
	Content string `json:"content"`
}

func (s *Server) handlePostComment(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	var req PostCommentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	p, err := s.profileService.GetProfile(r.Context(), userID)
	username := "user"
	if err == nil && p != nil {
		username = p.Username
	}

	comment, err := s.videoService.PostComment(r.Context(), videoID, userID, username, req.Content, nil)
	if err != nil {
		if err == moderation.ErrCannotPerformAction {
			writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", "Account is restricted for comment spam. You can submit an appeal.")
			return
		}
		writeJSONError(w, http.StatusBadRequest, "COMMENT_FAILED", err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, comment)
}

func (s *Server) handleRepostVideo(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	if err := s.videoService.RepostVideo(r.Context(), videoID, userID); err != nil {
		writeJSONError(w, http.StatusBadRequest, "REPOST_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "reposted"})
}

func (s *Server) handleSaveVideo(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	if err := s.videoService.SaveVideo(r.Context(), videoID, userID); err != nil {
		writeJSONError(w, http.StatusBadRequest, "SAVE_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "saved"})
}

type RecordSearchRequest struct {
	Query string `json:"query"`
}

func (s *Server) handleRecordSearch(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req RecordSearchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	if err := s.videoService.RecordSearch(r.Context(), userID, req.Query); err != nil {
		writeJSONError(w, http.StatusBadRequest, "SEARCH_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "recorded"})
}

func (s *Server) handleListVideoChat(w http.ResponseWriter, r *http.Request) {
	videoID := chi.URLParam(r, "videoId")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	msgs, err := s.chatService.ListVideoChatMessages(r.Context(), videoID, limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"messages": msgs})
}

type SendVideoChatRequest struct {
	Content        string `json:"content"`
	IdempotencyKey string `json:"idempotencyKey"`
}

func (s *Server) handleSendVideoChat(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	videoID := chi.URLParam(r, "videoId")

	var req SendVideoChatRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	p, err := s.profileService.GetProfile(r.Context(), userID)
	username := "viewer"
	if err == nil && p != nil {
		username = p.Username
	}

	if req.IdempotencyKey == "" {
		req.IdempotencyKey = "chat-" + strconv.FormatInt(time.Now().UnixNano(), 10)
	}

	msg, err := s.chatService.SendVideoChatMessage(r.Context(), videoID, userID, username, req.Content, req.IdempotencyKey)
	if err != nil {
		if err == chat.ErrAccountRestricted {
			writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", err.Error())
			return
		}
		writeJSONError(w, http.StatusBadRequest, "CHAT_FAILED", err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, msg)
}

func (s *Server) handleListUserThreads(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	threads, err := s.chatService.ListUserThreads(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"threads": threads})
}

type CreateThreadRequest struct {
	TargetUserID string `json:"targetUserId"`
}

func (s *Server) handleCreateDirectThread(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req CreateThreadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	thread, err := s.chatService.GetOrCreateDirectThread(r.Context(), userID, req.TargetUserID)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "THREAD_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, thread)
}

func (s *Server) handleListDirectMessages(w http.ResponseWriter, r *http.Request) {
	threadID := chi.URLParam(r, "threadId")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	msgs, err := s.chatService.ListDirectMessages(r.Context(), threadID, limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"messages": msgs})
}

type SendDirectMessageRequest struct {
	Content        string  `json:"content"`
	IdempotencyKey string  `json:"idempotencyKey"`
	TestDate       *string `json:"testDate,omitempty"`
}

func (s *Server) handleSendDirectMessage(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	threadID := chi.URLParam(r, "threadId")

	var req SendDirectMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid JSON body")
		return
	}

	p, err := s.profileService.GetProfile(r.Context(), userID)
	username := "user"
	if err == nil && p != nil {
		username = p.Username
	}

	if req.IdempotencyKey == "" {
		req.IdempotencyKey = "dm-" + strconv.FormatInt(time.Now().UnixNano(), 10)
	}

	result, err := s.chatService.SendDirectMessage(r.Context(), threadID, userID, username, req.Content, req.IdempotencyKey, req.TestDate)
	if err != nil {
		if err == chat.ErrAccountRestricted {
			writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", err.Error())
			return
		}
		writeJSONError(w, http.StatusBadRequest, "SEND_FAILED", err.Error())
		return
	}

	writeJSON(w, http.StatusCreated, result)
}

func (s *Server) handleGetMyCards(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	cardsList, err := s.cardsService.GetUserCards(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"cards": cardsList})
}

func (s *Server) handleGetCardDefinitions(w http.ResponseWriter, r *http.Request) {
	defs, err := s.cardsService.GetDefinitions(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"definitions": defs})
}

// Milestone 4 Handlers: Premium, Creator Monetization, and Ads

func (s *Server) handleBuyPremium(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	prof, err := s.profileService.BuyPremium(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, prof)
}

func (s *Server) handleFollowUser(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	targetID := chi.URLParam(r, "targetId")
	if targetID == "" || targetID == userID {
		writeJSONError(w, http.StatusBadRequest, "INVALID_TARGET", "Cannot follow yourself or empty user")
		return
	}
	if err := s.profileService.FollowUser(r.Context(), userID, targetID); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "followed"})
}

func (s *Server) handleGetMonetizationSummary(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	summary, err := s.adsService.GetMonetizationSummary(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, summary)
}

func (s *Server) handleApplyMonetization(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	if err := s.adsService.ApplyForMonetization(r.Context(), userID); err != nil {
		if errors.Is(err, ads.ErrNotEligible) {
			writeJSONError(w, http.StatusBadRequest, "NOT_ELIGIBLE", "Must meet all 5 criteria to monetize")
			return
		}
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "approved"})
}

func (s *Server) handleRequestPayout(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req struct {
		AmountCents int64  `json:"amountCents"`
		Method      string `json:"method"`
		Account     string `json:"account"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid payout body")
		return
	}

	payout, err := s.adsService.RequestPayout(r.Context(), userID, req.AmountCents, req.Method, req.Account)
	if err != nil {
		if errors.Is(err, ads.ErrBelowMinimumPayout) {
			writeJSONError(w, http.StatusBadRequest, "BELOW_MINIMUM", "Minimum payout is $20.00")
			return
		}
		if errors.Is(err, ads.ErrInsufficientBalance) {
			writeJSONError(w, http.StatusBadRequest, "INSUFFICIENT_BALANCE", "Insufficient monetization balance")
			return
		}
		if errors.Is(err, ads.ErrNotMonetized) {
			writeJSONError(w, http.StatusForbidden, "NOT_MONETIZED", "Creator is not approved for monetization")
			return
		}
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, payout)
}

func (s *Server) handleCreateAdCampaign(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	var req struct {
		VideoID           string `json:"videoId"`
		Name              string `json:"name"`
		Headline          string `json:"headline"`
		CallToActionURL   string `json:"callToActionUrl"`
		CallToActionLabel string `json:"callToActionLabel"`
		BudgetCents       int64  `json:"budgetCents"`
		CPMBidCents       int64  `json:"cpmBidCents"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid campaign JSON")
		return
	}

	camp, err := s.adsService.CreateCampaign(
		r.Context(),
		userID,
		req.VideoID,
		req.Name,
		req.Headline,
		req.CallToActionURL,
		req.CallToActionLabel,
		req.BudgetCents,
		req.CPMBidCents,
	)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "CAMPAIGN_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, camp)
}

func (s *Server) handleGetAdCampaign(w http.ResponseWriter, r *http.Request) {
	campaignID := chi.URLParam(r, "campaignId")
	camp, err := s.adsService.GetCampaign(r.Context(), campaignID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Campaign not found")
		return
	}
	writeJSON(w, http.StatusOK, camp)
}

func (s *Server) handleListActiveAdCampaigns(w http.ResponseWriter, r *http.Request) {
	camps, err := s.adsService.ListActiveCampaigns(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"campaigns": camps})
}

func (s *Server) handleRecordAdImpression(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	campaignID := chi.URLParam(r, "campaignId")

	var req struct {
		DurationSeconds float64 `json:"durationSeconds"`
		Completed       bool    `json:"completed"`
		ClickedCTA      bool    `json:"clickedCta"`
		CreatorID       string  `json:"creatorId"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	isRestricted := s.antiBotEngine.IsRestricted(r.Context(), userID)
	imp, err := s.adsService.RecordImpression(
		r.Context(),
		campaignID,
		userID,
		isRestricted,
		req.DurationSeconds,
		req.Completed,
		req.ClickedCTA,
		req.CreatorID,
	)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "IMPRESSION_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, imp)
}

func (s *Server) handleRecordAdClick(w http.ResponseWriter, r *http.Request) {
	campaignID := chi.URLParam(r, "campaignId")
	if err := s.adsService.RecordCTAClick(r.Context(), campaignID); err != nil {
		writeJSONError(w, http.StatusBadRequest, "CLICK_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Milestone 5 & 6 Handlers: English Auction Marketplace

func (s *Server) handleListActiveAuctions(w http.ResponseWriter, r *http.Request) {
	listings, err := s.auctionService.ListActive(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"listings": listings})
}

func (s *Server) handleGetAuction(w http.ResponseWriter, r *http.Request) {
	listingID := chi.URLParam(r, "listingId")
	listing, err := s.auctionService.GetListing(r.Context(), listingID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Auction listing not found")
		return
	}
	writeJSON(w, http.StatusOK, listing)
}

func (s *Server) handleCreateAuctionListing(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	if s.antiBotEngine.IsRestricted(r.Context(), userID) {
		writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", "Account is restricted in passive preview mode")
		return
	}

	var req struct {
		CardInstanceID  string  `json:"cardInstanceId"`
		MinimumBidW     int64   `json:"minimumBidW"`
		DurationMinutes int     `json:"durationMinutes"`
		FeePercentage   float64 `json:"feePercentage"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid listing JSON")
		return
	}

	listing, err := s.auctionService.CreateListing(
		r.Context(),
		userID,
		req.CardInstanceID,
		req.MinimumBidW,
		req.DurationMinutes,
		req.FeePercentage,
	)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "LISTING_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, listing)
}

func (s *Server) handlePlaceAuctionBid(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	if s.antiBotEngine.IsRestricted(r.Context(), userID) {
		writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", "Account is restricted in passive preview mode")
		return
	}

	listingID := chi.URLParam(r, "listingId")
	var req struct {
		BidAmountW int64 `json:"bidAmountW"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid bid JSON")
		return
	}

	bid, err := s.auctionService.PlaceBid(r.Context(), userID, listingID, req.BidAmountW)
	if err != nil {
		if errors.Is(err, wallet.ErrInsufficientBalance) {
			writeJSONError(w, http.StatusBadRequest, "INSUFFICIENT_W", "Insufficient available W balance for bid")
			return
		}
		if errors.Is(err, auctions.ErrBidTooLow) {
			writeJSONError(w, http.StatusBadRequest, "BID_TOO_LOW", "Bid must be higher than current highest bid")
			return
		}
		if errors.Is(err, auctions.ErrSelfBiddingBlocked) {
			writeJSONError(w, http.StatusBadRequest, "SELF_BID_BLOCKED", "Cannot bid on your own auction")
			return
		}
		writeJSONError(w, http.StatusBadRequest, "BID_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, bid)
}

func (s *Server) handleSettleAuction(w http.ResponseWriter, r *http.Request) {
	listingID := chi.URLParam(r, "listingId")
	listing, err := s.auctionService.SettleAuction(r.Context(), listingID)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "SETTLEMENT_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, listing)
}

func (s *Server) handleCancelAuctionListing(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	listingID := chi.URLParam(r, "listingId")
	if err := s.auctionService.CancelListing(r.Context(), userID, listingID); err != nil {
		writeJSONError(w, http.StatusBadRequest, "CANCEL_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "cancelled"})
}

// Milestone 7 Handlers: Call It Community Predictions (Virtual Game Points)

func (s *Server) handleListPredictionMarkets(w http.ResponseWriter, r *http.Request) {
	markets, err := s.predictionService.ListOpenMarkets(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"markets": markets})
}

func (s *Server) handleGetPredictionMarket(w http.ResponseWriter, r *http.Request) {
	marketID := chi.URLParam(r, "marketId")
	m, err := s.predictionService.GetMarket(r.Context(), marketID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", "Prediction market not found")
		return
	}
	writeJSON(w, http.StatusOK, m)
}

func (s *Server) handleCreatePredictionMarket(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Title           string   `json:"title"`
		Description     string   `json:"description"`
		Category        string   `json:"category"`
		Options         []string `json:"options"`
		DurationMinutes int      `json:"durationMinutes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid market request")
		return
	}

	market, err := s.predictionService.CreateMarket(
		r.Context(),
		req.Title,
		req.Description,
		req.Category,
		req.Options,
		req.DurationMinutes,
	)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "CREATE_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, market)
}

func (s *Server) handlePlacePrediction(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	if s.antiBotEngine.IsRestricted(r.Context(), userID) {
		writeJSONError(w, http.StatusForbidden, "ACCOUNT_RESTRICTED", "Account is restricted in passive preview mode")
		return
	}

	marketID := chi.URLParam(r, "marketId")
	var req struct {
		OptionID string `json:"optionId"`
		Points   int64  `json:"points"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid prediction request")
		return
	}

	entry, err := s.predictionService.PlacePrediction(r.Context(), userID, marketID, req.OptionID, req.Points)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "PREDICTION_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, entry)
}

func (s *Server) handleResolvePredictionMarket(w http.ResponseWriter, r *http.Request) {
	marketID := chi.URLParam(r, "marketId")
	var req struct {
		WinningOptionID string `json:"winningOptionId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "INVALID_BODY", "Invalid resolve request")
		return
	}

	resolved, err := s.predictionService.ResolveMarket(r.Context(), marketID, req.WinningOptionID)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "RESOLVE_FAILED", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, resolved)
}

func (s *Server) handleGetMyPredictions(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromContext(r.Context())
	entries, err := s.predictionService.GetUserPredictions(r.Context(), userID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"predictions": entries})
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeJSONError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"error": map[string]string{
			"code":    code,
			"message": message,
		},
	})
}
