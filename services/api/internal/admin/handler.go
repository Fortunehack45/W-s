package admin

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r chi.Router) {
	// Web console route
	r.Get("/admin", h.ServeWebConsole)
	r.Get("/admin/*", h.ServeWebConsole)

	// Admin API routes
	r.Route("/api/v1/admin", func(r chi.Router) {
		r.Get("/stats", h.GetStats)
		r.Get("/users", h.ListUsers)
		r.Get("/activities", h.ListActivities)
		r.Get("/comments", h.ListComments)
		r.Delete("/comments/{commentId}", h.DeleteComment)
		r.Get("/chats", h.ListVideoChats)
		r.Get("/dms", h.ListDMs)
		r.Get("/threads", h.ListThreads)
		r.Post("/users/{userId}/restrict", h.SetUserRestriction)
		r.Post("/users/{userId}/verify", h.SetUserVerified)
		r.Get("/appeals", h.ListAppeals)
		r.Post("/appeals/{appealId}/resolve", h.ResolveAppeal)
	})
}

func (h *Handler) ServeWebConsole(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(DashboardHTML))
}

func (h *Handler) GetStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.service.GetStats(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

func (h *Handler) ListUsers(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("query")
	var filterRestricted *bool
	if restrStr := r.URL.Query().Get("restricted"); restrStr != "" {
		val := restrStr == "true"
		filterRestricted = &val
	}

	users, err := h.service.ListUsers(r.Context(), q, filterRestricted)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, users)
}

func (h *Handler) ListActivities(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if lStr := r.URL.Query().Get("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil && l > 0 {
			limit = l
		}
	}

	acts, err := h.service.ListActivities(r.Context(), limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, acts)
}

func (h *Handler) ListComments(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if lStr := r.URL.Query().Get("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil && l > 0 {
			limit = l
		}
	}

	comments, err := h.service.ListAllComments(r.Context(), limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, comments)
}

func (h *Handler) DeleteComment(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "commentId")
	if err := h.service.DeleteComment(r.Context(), commentID); err != nil {
		writeJSONError(w, http.StatusNotFound, "NOT_FOUND", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "deleted"})
}

func (h *Handler) ListVideoChats(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if lStr := r.URL.Query().Get("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil && l > 0 {
			limit = l
		}
	}

	chats, err := h.service.ListAllVideoChats(r.Context(), limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, chats)
}

func (h *Handler) ListDMs(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if lStr := r.URL.Query().Get("limit"); lStr != "" {
		if l, err := strconv.Atoi(lStr); err == nil && l > 0 {
			limit = l
		}
	}

	dms, err := h.service.ListAllDMs(r.Context(), limit)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, dms)
}

func (h *Handler) ListThreads(w http.ResponseWriter, r *http.Request) {
	threads, err := h.service.ListAllThreads(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, threads)
}

func (h *Handler) SetUserRestriction(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	restrict := r.URL.Query().Get("restrict") == "true"

	if err := h.service.SetUserRestriction(r.Context(), userID, restrict); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"userId": userID, "restricted": restrict})
}

func (h *Handler) SetUserVerified(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	verify := r.URL.Query().Get("verify") == "true"

	if err := h.service.SetUserVerified(r.Context(), userID, verify); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"userId": userID, "verified": verify})
}

func (h *Handler) ListAppeals(w http.ResponseWriter, r *http.Request) {
	appeals, err := h.service.ListAppeals(r.Context())
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, appeals)
}

func (h *Handler) ResolveAppeal(w http.ResponseWriter, r *http.Request) {
	appealID := chi.URLParam(r, "appealId")
	approve := r.URL.Query().Get("approve") == "true"

	if err := h.service.ResolveAppeal(r.Context(), appealID, approve); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"appealId": appealID, "approved": approve})
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeJSONError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, map[string]string{
		"code":    code,
		"message": message,
	})
}
