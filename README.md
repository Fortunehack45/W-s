# W's — Social Video Platform & Dynamic Momentum Economy

[![W's CI Pipeline](https://github.com/Fortunehack45/W-s/actions/workflows/ci.yml/badge.svg)](https://github.com/Fortunehack45/W-s/actions/workflows/ci.yml)
[![Release & Artifact Build](https://github.com/Fortunehack45/W-s/actions/workflows/release.yml/badge.svg)](https://github.com/Fortunehack45/W-s/actions/workflows/release.yml)
[![Go Version](https://img.shields.io/badge/Go-1.22+-00ADD8?style=flat&logo=go)](https://golang.org)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.19+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**W's** is a vertical short-form video platform combining TikTok-inspired discovery with an in-app **Dynamic W's Momentum Economy**, zero-cost resumable video uploads ($0 gas), anti-bot passive preview protections, serialized NFT streak cards with English auction trading, parimutuel prediction markets, and a real-time **Super Admin Control Center**.

---

## 🌟 Core System Pillars

1. **TikTok-Inspired UI/UX Across 12 Screens**:
   - Fullscreen FYP feed with right-side action rail (Like, Comment, Save, Share, spinning Vinyl Record Disc, and **Dynamic W Stake Gauge Pill**).
   - Friends feed with top story heads and location tag pills (`📍 University Library • 36.6 mi`).
   - Camera Studio with duration switcher (`10m`, `60s`, `15s`, `PHOTO`), shutter controls, sound selector, and 100% free chunked uploads.
   - Inbox with status thought bubbles ("What's up?"), notification categories, and DM threads with active streak flames (`🔥 32d`).
   - Tabbed Profile with **Total W's Earned** hero metric (community value created), 5 sub-tabs (Videos, Backed Pools, Reposts, Saved, Liked), and ecosystem drawer.

2. **Dynamic Video W's Momentum Pools**:
   - **Zero-Cost Video Posting**: Videos start at $0\text{ W}$ (100% free to publish).
   - **Linear Bonding Curve**: $P(S) = P_0 + k \cdot S$. Community members discover videos on their FYP and back them with W's.
   - **Dynamic Liquidity Gauge**: As momentum builds, video pool surges (can reach $10\text{k}$ or $1\text{M W's}$). Backers can cash out shares to lock in profit, dynamically decreasing the pool's W count.
   - **Creator Royalties**: $2.0\%$ ($200\text{ bps}$) credited directly to the creator's wallet on every buy/sell trade.
   - **Closed-Loop Economy**: W's cannot be cashed out for fiat money, protecting bonding curve liquidity against bank runs.

3. **Anti-Bot & Passive Preview Mode**:
   - Auto-restricts accounts that spam $>100$ comments per day.
   - Restricted accounts enter **Passive Preview Mode**: they can watch videos and read comments, but their views do **not count** (`is_counted = false`), and they cannot comment or stake.
   - In-app appeals process via modal.

4. **Creator Monetization & USD Fiat Payouts**:
   - **5-Point Gate**: VIP Premium Pass + $\ge 500$ Verified Followers + $\ge 2,000$ Total Followers + $\ge 5,000,000$ Watch Minutes + $\ge 5,000,000$ Total Views.
   - **55% Ad Revenue Split**: Monetized creators earn 55% of native in-app ad revenue paid in real USD fiat cents ($\ge \$20.00$ payout threshold via Stripe/Bank).

5. **Canonical Video Chats & 1-on-1 Streaks**:
   - 1 persistent chat room per video with dynamic top-backer badge pills.
   - 1-on-1 direct messaging streaks minting serialized milestone NFT cards (Common, Rare, Epic, Legendary).

6. **Streak NFT Card English Auction Marketplace**:
   - Peer-to-peer auctions settled in W's with authoritative wallet escrow, instant outbid refund releases, and anti-sniping extensions.

7. **Call It Prediction Markets**:
   - Parimutuel prediction pools on video viral milestones using virtual game tokens.

8. **Super Admin Control Center (`/admin`)**:
   - Live web SPA and mobile admin view inspecting all platform KPIs, user registry (with one-click restrict/unrestrict/verify), live activity audit stream, comments with spam velocity alerts, video chats, and direct message transcripts.

---

## 🏛 Repository Architecture

```
W-s/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Automated Go & Flutter CI validation
│       └── release.yml            # Automated APK, AAB & multiplatform binary builder
├── apps/
│   └── mobile/                    # Flutter Android Mobile Application
│       ├── android/               # Complete Android Gradle & Manifest configuration
│       ├── lib/
│       │   ├── core/              # Design system tokens (WsTokens) & API client
│       │   ├── features/
│       │   │   ├── admin/         # Mobile Admin Console
│       │   │   ├── chat/          # Inbox, DMs, Streaks & Canonical Video Chat
│       │   │   ├── collectibles/  # NFT Streak Cards & English Auction Marketplace
│       │   │   ├── feed/          # FYP Video Feed & Friends Feed
│       │   │   ├── moderation/    # In-app appeal modal & passive preview banners
│       │   │   ├── monetization/  # Creator Studio, Ad Campaign Manager, VIP Premium
│       │   │   ├── predictions/   # Call It Parimutuel Prediction Markets
│       │   │   ├── profiles/      # Profile view with Total W's Earned & 5 Sub-Tabs
│       │   │   ├── search/        # Discovery & trending hashtags
│       │   │   ├── upload/        # Camera studio & zero-cost resumable upload
│       │   │   └── wallet/        # W's wallet dashboard & ledger
│       │   └── routing/           # Declarative GoRouter navigation shell
│       └── pubspec.yaml
├── services/
│   └── api/                       # High-Performance Go Backend Service
│       ├── cmd/server/            # Server entrypoint (builds to bin/server.exe)
│       ├── internal/
│       │   ├── admin/             # Super Admin Service, Endpoints & Web Console SPA
│       │   ├── ads/               # Native in-app ad engine & 55% creator fiat split
│       │   ├── auctions/          # English auction engine with wallet escrow
│       │   ├── cards/             # Serial-numbered NFT card minting
│       │   ├── chat/              # Video chat, DMs, streaks & passive preview checks
│       │   ├── moderation/        # Anti-bot velocity counter & appeals queue
│       │   ├── predictions/       # Call It parimutuel predictions engine
│       │   ├── profiles/          # User profiles & creator qualification checks
│       │   ├── videopools/        # Linear bonding curve momentum pools
│       │   ├── videos/            # Resumable zero-cost uploads & personalized FYP
│       │   └── wallet/            # Authoritative double-entry ledger & escrow
│       └── tests/                 # 17 Automated Integration Test Suites
├── contracts/
│   └── openapi.yaml               # OpenAPI 3.1 specification
├── supabase/
│   └── migrations/                # Production PostgreSQL schema migrations & RLS
└── docker-compose.yml             # Local PostgreSQL container definition
```

---

## 🚀 Quickstart Guide

### 1. Running the Go Backend
```powershell
# Run the pre-compiled server binary
.\services\api\bin\server.exe

# Or compile and run from source:
cd services/api
go run ./cmd/server
```
- **API Health Check**: `http://localhost:8080/health`
- **Super Admin Web Console**: `http://localhost:8080/admin`

### 2. Running Backend Tests (17 Suites)
```powershell
cd services/api
go test -v ./tests
```

### 3. Building Mobile Packages (APK & AAB)
Push a tag `v*` (e.g. `git tag v1.0.0 && git push origin v1.0.0`) or trigger the GitHub Release workflow via GitHub Actions:
- **Universal APK** (direct installation on any Android phone): `ws-app-v1.0.0-universal-release.apk`
- **Google Play App Bundle (AAB)**: `ws-app-v1.0.0-release.aab`

---

## 📄 License
Proprietary & Confidential — All rights reserved.
