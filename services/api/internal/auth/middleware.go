package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const (
	UserIDKey    contextKey = "auth_user_id"
	UserEmailKey contextKey = "auth_user_email"
)

// Middleware verifies Bearer JWT tokens.
type Middleware struct {
	jwtSecret string
	isDevMode bool
}

// NewMiddleware constructs auth middleware.
func NewMiddleware(jwtSecret string, isDevMode bool) *Middleware {
	return &Middleware{
		jwtSecret: jwtSecret,
		isDevMode: isDevMode,
	}
}

// Handler returns HTTP middleware enforcing valid authentication.
func (m *Middleware) Handler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Missing authorization header")
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			writeError(w, http.StatusUnauthorized, "INVALID_TOKEN_FORMAT", "Authorization header must be 'Bearer <token>'")
			return
		}

		tokenStr := parts[1]

		// Support Mock/Dev test token format: "mock-user-<uuid>" or "test-token:<uuid>" when in dev/testing mode
		if m.isDevMode && (strings.HasPrefix(tokenStr, "mock-user-") || strings.HasPrefix(tokenStr, "test-user-")) {
			userID := strings.TrimPrefix(tokenStr, "mock-user-")
			userID = strings.TrimPrefix(userID, "test-user-")
			ctx := context.WithValue(r.Context(), UserIDKey, userID)
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		// Standard Supabase JWT verification
		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, errors.New("unexpected signing method")
			}
			return []byte(m.jwtSecret), nil
		})

		if err != nil || !token.Valid {
			writeError(w, http.StatusUnauthorized, "INVALID_TOKEN", "Invalid or expired token")
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			writeError(w, http.StatusUnauthorized, "INVALID_CLAIMS", "Malformed token claims")
			return
		}

		sub, ok := claims["sub"].(string)
		if !ok || sub == "" {
			writeError(w, http.StatusUnauthorized, "MISSING_SUB", "Token missing subject claim")
			return
		}

		ctx := context.WithValue(r.Context(), UserIDKey, sub)
		if email, ok := claims["email"].(string); ok {
			ctx = context.WithValue(ctx, UserEmailKey, email)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// UserIDFromContext retrieves the authenticated user ID.
func UserIDFromContext(ctx context.Context) (string, bool) {
	val := ctx.Value(UserIDKey)
	if val == nil {
		return "", false
	}
	id, ok := val.(string)
	return id, ok
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write([]byte(`{"error":{"code":"` + code + `","message":"` + message + `"}}`))
}
