package tests

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ws-platform/api/internal/auth"
)

func TestAuthMiddleware_Rejection(t *testing.T) {
	mw := auth.NewMiddleware("test-secret-at-least-32-chars-long", true)

	dummyHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	})

	handler := mw.Handler(dummyHandler)

	// Case 1: Missing Authorization Header
	req1 := httptest.NewRequest("GET", "/api/v1/me", nil)
	rr1 := httptest.NewRecorder()
	handler.ServeHTTP(rr1, req1)
	if rr1.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for missing auth header, got %d", rr1.Code)
	}

	// Case 2: Invalid Format
	req2 := httptest.NewRequest("GET", "/api/v1/me", nil)
	req2.Header.Set("Authorization", "InvalidHeaderFormat")
	rr2 := httptest.NewRecorder()
	handler.ServeHTTP(rr2, req2)
	if rr2.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for invalid header format, got %d", rr2.Code)
	}

	// Case 3: Valid Dev Token
	req3 := httptest.NewRequest("GET", "/api/v1/me", nil)
	req3.Header.Set("Authorization", "Bearer mock-user-12345")
	rr3 := httptest.NewRecorder()
	handler.ServeHTTP(rr3, req3)
	if rr3.Code != http.StatusOK {
		t.Errorf("expected 200 for valid dev token, got %d", rr3.Code)
	}
}
