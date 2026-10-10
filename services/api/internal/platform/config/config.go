package config

import (
	"os"
	"strconv"
)

// Config represents runtime application configuration.
type Config struct {
	AppEnv            string
	HTTPAddr          string
	DatabaseURL       string
	SupabaseURL       string
	SupabaseAnonKey   string
	SupabaseJWTSecret string
	CreatorRoyaltyBps int
	BaseWPrice        int64
	SignupBonusW      int64
}

// Load reads configuration from environment variables with sensible defaults.
func Load() *Config {
	return &Config{
		AppEnv:            getEnv("APP_ENV", "development"),
		HTTPAddr:          getEnv("HTTP_ADDR", ":8080"),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/ws_db?sslmode=disable"),
		SupabaseURL:       getEnv("SUPABASE_URL", "https://localhost:8000"),
		SupabaseAnonKey:   getEnv("SUPABASE_ANON_KEY", "dev-anon-key"),
		SupabaseJWTSecret: getEnv("SUPABASE_JWT_SECRET", "dev-jwt-secret-at-least-32-chars-long"),
		CreatorRoyaltyBps: getEnvInt("CREATOR_ROYALTY_BPS", 200), // 2.0% = 200 basis points
		BaseWPrice:        int64(getEnvInt("BASE_W_PRICE", 1)),
		SignupBonusW:      int64(getEnvInt("SIGNUP_BONUS_W", 50)),
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if parsed, err := strconv.Atoi(val); err == nil {
			return parsed
		}
	}
	return defaultVal
}
