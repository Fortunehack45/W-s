package tests

import (
	"context"
	"fmt"
	"testing"

	"github.com/ws-platform/api/internal/cards"
	"github.com/ws-platform/api/internal/chat"
	"github.com/ws-platform/api/internal/profiles"
	"github.com/ws-platform/api/internal/videopools"
	"github.com/ws-platform/api/internal/wallet"
)

func TestCanonicalVideoChat_BackerBadges(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	cardsService := cards.NewInMemoryCardService()
	chatService := chat.NewInMemoryChatService(poolService, cardsService, profService)

	videoID := "vid-backer-test"
	creatorID := "creator-1"
	_, _ = poolService.InitPool(ctx, videoID, creatorID)

	userTop1 := "user-top1"
	userTop5 := "user-top5"
	userRegular := "user-regular"

	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: userTop1, Username: "top1_whale"})
	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: userTop5, Username: "top5_investor"})
	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: userRegular, Username: "regular_viewer"})

	// Give users W's
	_, _ = walletService.GrantSignupBonus(ctx, userTop1)
	_, _ = walletService.GrantSignupBonus(ctx, userTop5)

	// UserTop1 stakes 60 W's (gets >= 50 shares)
	_, _ = poolService.StakeW(ctx, userTop1, videoID, 45, 1, "top1-stake")

	// UserTop5 stakes 15 W's
	_, _ = poolService.StakeW(ctx, userTop5, videoID, 15, 1, "top5-stake")

	// 1. UserTop1 sends message
	msg1, err := chatService.SendVideoChatMessage(ctx, videoID, userTop1, "top1_whale", "I backed this video first!", "msg-1")
	if err != nil {
		t.Fatalf("SendVideoChatMessage 1 failed: %v", err)
	}
	if msg1.Badge != "⚡ Top 1 Backer" && msg1.Badge != "🔥 Top 5 Backer" {
		t.Fatalf("expected backer badge, got '%s'", msg1.Badge)
	}

	// 2. Regular user (0 shares) sends message
	msg2, err := chatService.SendVideoChatMessage(ctx, videoID, userRegular, "regular_viewer", "Cool video!", "msg-2")
	if err != nil {
		t.Fatalf("SendVideoChatMessage 2 failed: %v", err)
	}
	if msg2.Badge != "" {
		t.Fatalf("expected empty badge for 0-stake user, got '%s'", msg2.Badge)
	}

	// 3. Verify message list
	msgs, err := chatService.ListVideoChatMessages(ctx, videoID, 10)
	if err != nil {
		t.Fatalf("ListVideoChatMessages failed: %v", err)
	}
	if len(msgs) != 2 {
		t.Fatalf("expected 2 messages, got %d", len(msgs))
	}
}

func TestDirectMessages_StreaksAndCardMinting(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	cardsService := cards.NewInMemoryCardService()
	chatService := chat.NewInMemoryChatService(poolService, cardsService, profService)

	userA := "user-alice"
	userB := "user-bob"
	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: userA, Username: "alice"})
	_ = profService.CreateProfile(ctx, &profiles.Profile{ID: userB, Username: "bob"})

	thread, err := chatService.GetOrCreateDirectThread(ctx, userA, userB)
	if err != nil {
		t.Fatalf("GetOrCreateDirectThread failed: %v", err)
	}

	// Day 1: User A sends first message
	d1 := "2026-10-01"
	r1, err := chatService.SendDirectMessage(ctx, thread.ID, userA, "alice", "Hey Bob!", "d1-1", &d1)
	if err != nil {
		t.Fatalf("SendDirectMessage d1 failed: %v", err)
	}
	if r1.Thread.CurrentStreakDays != 1 {
		t.Fatalf("expected Day 1 streak, got %d", r1.Thread.CurrentStreakDays)
	}

	// Same Day 1: User B replies -> Streak stays at 1
	r1b, err := chatService.SendDirectMessage(ctx, thread.ID, userB, "bob", "Hey Alice!", "d1-2", &d1)
	if err != nil {
		t.Fatalf("SendDirectMessage d1-reply failed: %v", err)
	}
	if r1b.Thread.CurrentStreakDays != 1 {
		t.Fatalf("expected streak to remain 1 on same day, got %d", r1b.Thread.CurrentStreakDays)
	}

	// Days 2 through 6: Consecutive daily messaging
	for day := 2; day <= 6; day++ {
		dateStr := fmt.Sprintf("2026-10-%02d", day)
		res, err := chatService.SendDirectMessage(ctx, thread.ID, userA, "alice", fmt.Sprintf("Streak msg day %d", day), fmt.Sprintf("msg-d%d", day), &dateStr)
		if err != nil {
			t.Fatalf("SendDirectMessage day %d failed: %v", day, err)
		}
		if res.Thread.CurrentStreakDays != day {
			t.Fatalf("expected streak %d, got %d", day, res.Thread.CurrentStreakDays)
		}
		if len(res.MintedCards) != 0 {
			t.Fatalf("did not expect card minting on day %d", day)
		}
	}

	// Day 7: Reaching the 7-day milestone triggers the "Streak Spark" Common Card!
	d7 := "2026-10-07"
	r7, err := chatService.SendDirectMessage(ctx, thread.ID, userB, "bob", "We hit Day 7 streak! 🔥", "msg-d7", &d7)
	if err != nil {
		t.Fatalf("SendDirectMessage d7 failed: %v", err)
	}
	if r7.Thread.CurrentStreakDays != 7 {
		t.Fatalf("expected streak 7, got %d", r7.Thread.CurrentStreakDays)
	}
	if len(r7.MintedCards) != 1 || r7.MintedCards[0] != "Streak Spark" {
		t.Fatalf("expected 'Streak Spark' card minted on day 7, got %v", r7.MintedCards)
	}

	// Verify both Alice and Bob received their minted cards with unique serial numbers!
	aliceCards, err := cardsService.GetUserCards(ctx, userA)
	if err != nil || len(aliceCards) != 1 {
		t.Fatalf("expected Alice to have 1 card, got %d", len(aliceCards))
	}
	if aliceCards[0].Definition.Name != "Streak Spark" {
		t.Fatalf("expected 'Streak Spark', got %s", aliceCards[0].Definition.Name)
	}

	bobCards, err := cardsService.GetUserCards(ctx, userB)
	if err != nil || len(bobCards) != 1 {
		t.Fatalf("expected Bob to have 1 card, got %d", len(bobCards))
	}
	if bobCards[0].Definition.Name != "Streak Spark" {
		t.Fatalf("expected 'Streak Spark', got %s", bobCards[0].Definition.Name)
	}

	// Verify unique serial numbers: Alice gets serial #1, Bob gets serial #2
	if aliceCards[0].SerialNumber == bobCards[0].SerialNumber {
		t.Fatalf("expected unique serial numbers, but both got %d", aliceCards[0].SerialNumber)
	}

	// Day 15 (Broken Streak): 8 days gap -> resets streak to 1
	d15 := "2026-10-15"
	rBroken, err := chatService.SendDirectMessage(ctx, thread.ID, userA, "alice", "Sorry I missed a week!", "msg-d15", &d15)
	if err != nil {
		t.Fatalf("SendDirectMessage d15 failed: %v", err)
	}
	if rBroken.Thread.CurrentStreakDays != 1 {
		t.Fatalf("expected streak reset to 1 after gap, got %d", rBroken.Thread.CurrentStreakDays)
	}
	if rBroken.Thread.LongestStreakDays != 7 {
		t.Fatalf("expected LongestStreakDays = 7 preserved, got %d", rBroken.Thread.LongestStreakDays)
	}
}

func TestDirectMessages_PassivePreviewRestriction(t *testing.T) {
	ctx := context.Background()

	profRepo := profiles.NewMemoryRepository()
	profService := profiles.NewService(profRepo)
	walletRepo := wallet.NewMemoryRepository()
	walletService := wallet.NewService(walletRepo, 50)
	poolRepo := videopools.NewMemoryRepository()
	poolService := videopools.NewService(poolRepo, walletService, 200)
	cardsService := cards.NewInMemoryCardService()
	chatService := chat.NewInMemoryChatService(poolService, cardsService, profService)

	restrictedUser := "user-restricted"
	normalUser := "user-normal"

	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:                restrictedUser,
		Username:          "spammer_bot",
		RestrictionStatus: profiles.RestrictionRestricted,
	})
	_ = profService.CreateProfile(ctx, &profiles.Profile{
		ID:                normalUser,
		Username:          "normal_user",
		RestrictionStatus: profiles.RestrictionNormal,
	})

	thread, _ := chatService.GetOrCreateDirectThread(ctx, restrictedUser, normalUser)

	// Restricted user attempts to send DM -> Must be rejected!
	_, err := chatService.SendDirectMessage(ctx, thread.ID, restrictedUser, "spammer_bot", "Spam DM", "key-1", nil)
	if err != chat.ErrAccountRestricted {
		t.Fatalf("expected ErrAccountRestricted, got %v", err)
	}
}
