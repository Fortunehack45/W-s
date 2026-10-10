package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ws-platform/api/internal/ads"
	"github.com/ws-platform/api/internal/auctions"
	"github.com/ws-platform/api/internal/auth"
	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/chat"
	"github.com/ws-platform/api/internal/moderation"
	"github.com/ws-platform/api/internal/platform/config"
	"github.com/ws-platform/api/internal/predictions"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/server"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/videos"
	"github.com/ws-platform/api/internal/wallet"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	cfg := config.Load()
	logger.Info("Starting W's Platform API", "env", cfg.AppEnv, "addr", cfg.HTTPAddr)

	// Scaffolding domain services with memory repositories
	profileRepo := profiles.NewMemoryRepository()
	profileService := profiles.NewService(profileRepo)

	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, cfg.SignupBonusW)

	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, cfg.CreatorRoyaltyBps)

	antiBotEngine := moderation.NewAntiBotEngine(profileService)
	videoService := videos.NewInMemoryVideoService(poolService, antiBotEngine, profileService)

	cardsService := cards.NewInMemoryCardService()
	chatService := chat.NewInMemoryChatService(poolService, cardsService, profileService)

	adsService := ads.NewInMemoryAdsService(profileService, videoService)
	auctionService := auctions.NewInMemoryAuctionService(cardsService, walletService)
	predictionService := predictions.NewInMemoryPredictionService()

	isDevMode := cfg.AppEnv == "development" || cfg.AppEnv == "test"
	authMiddleware := auth.NewMiddleware(cfg.SupabaseJWTSecret, isDevMode)

	srv := server.NewServer(profileService, walletService, poolService, videoService, cardsService, chatService, adsService, auctionService, predictionService, antiBotEngine, authMiddleware)

	httpServer := &http.Server{
		Addr:         cfg.HTTPAddr,
		Handler:      srv.Router(),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("HTTP server failed", "error", err)
			os.Exit(1)
		}
	}()

	logger.Info("Server listening", "addr", cfg.HTTPAddr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server gracefully...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(ctx); err != nil {
		logger.Error("Server forced shutdown", "error", err)
	}
	logger.Info("Server exited cleanly")
}
