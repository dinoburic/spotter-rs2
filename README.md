# Spotter – Smart Event Discovery and Booking

> A modern, map-first event discovery and booking platform built for FIT Mostar RS2 seminary project.
> 
> **Student:** Dino Burić (IB230006) | **Course:** Software Development II | **Academic Year:** 2025/2026

---

## Overview

Spotter is a full-stack event discovery and booking platform that enables users to find, explore, and book tickets for local events through an interactive map-first mobile experience. The platform combines real-time geolocation, ML.NET-powered personalized recommendations, Stripe payments, digital QR tickets, and a gamification system — all backed by a microservice architecture.

The system consists of:
- **Mobile app** (Flutter/Android) — for end users and organizers
- **Desktop app** (Flutter/Windows) — for platform administrators
- **REST API** (ASP.NET Core 9) — business logic and data management
- **AI Worker** (RabbitMQ microservice) — geocoding and email notifications
- **ML.NET Recommender** — content-based event recommendations

---

## Features

### Mobile App (User & Organizer)

#### Map-First Event Discovery
- Interactive map with color-coded pins by event category (e.g. purple for Music, orange for Sport)
- Toggle between Map view and List/Feed view
- Search events by name, category, or location
- Advanced filters for precise event discovery

#### Event Details
- Full event information: name, venue, date, time, price
- Distance from user's current location (GPS-based)
- Friends attending the event
- User reviews and ratings
- Buy ticket / Reserve buttons

#### AI Recommendations
- "Recommended for you" section powered by ML.NET (TF-IDF + FastTree)
- "Popular near you" based on city and sales ratio
- Cold start handling via user interests selected at registration
- Explainable recommendations: "Because you like Music", "Popular event in your city"
- Model retrained automatically every 24 hours

#### Ticket Purchase & Waitlist
- Choose ticket type (Regular, VIP) and quantity
- Stripe PaymentSheet integration for in-app payment
- Automatic waitlist notification when a spot becomes available
- QR code ticket generation after payment

#### Digital Wallet (Offline Tickets)
- QR tickets saved locally on device
- Available offline — no internet connection needed at event entrance
- Active / Used / Cancelled ticket tabs

#### Favorites
- Save events for later viewing
- Quick access to saved events

#### Notifications
- Real-time via SignalR
- Order created, payment confirmed, reservation status changes
- New events in user's city
- Waitlist availability alerts

#### Gamification (Spotter Points)
- Earn points by purchasing tickets and leaving reviews
- Redeem points for discounts at checkout (100 points = 1 BAM)
- Badge system: Music Lover, Night Owl, Foodie, Early Bird, etc.
- Points balance and badges displayed on profile

#### User Profile
- Edit personal information, city, phone number
- Change password
- My Interests — select preferred categories (improves recommendations)
- My Orders and My Reservations
- Badges earned
- Friends list

#### Find Friends
- Search users by name or username
- Smart suggestions based on city and mutual friends
- View how many events each user has attended
- Send, accept, or decline friend requests

#### Organizer Features
- Create events directly from mobile app
- Add ticket types after event creation
- My Events screen: activate, cancel, edit, delete own events
- Organizers can only manage their own events

---

### Desktop App (Admin)

#### Dashboard
- Total tickets sold, active events, registered users, pending reservations
- Revenue breakdown (daily, weekly, monthly)
- Sales trend chart over time
- Top 5 most popular events with ticket count and revenue

#### Event Management
- Full CRUD for events with status tracking (Draft → Active → Cancelled/Completed)
- Filter by category, date, status
- AI geocoding: enter venue name and coordinates are automatically fetched via RabbitMQ → Google Maps API
- Manage ticket types per event

#### Order Management
- View all orders with user, event, ticket type, status
- Filter by status (Paid, Pending, Refunded, Cancelled)
- Refund orders (calls Stripe Refund API before updating local state)

#### Ticket Scanner
- Manual QR code input for ticket validation at event entrance
- Works with USB barcode scanners
- Shows validation result with ticket holder details

#### PDF Reports
- **Financial Report**: revenue summary filtered by date range and category
- **Guest List**: attendee list filtered by date range, category, and event
- Both generated client-side as downloadable PDFs

#### User Management
- View, edit, soft-delete users
- Role management (Admin, Organizer, User)
- City assignment

#### Reference Data Management
- CRUD for Cities, Categories, Venues, Ticket Types

---

### Backend Architecture

#### API (Spotter.WebAPI)
- ASP.NET Core 9 REST API
- JWT authentication with server-side token invalidation
- Role-based authorization: Admin, Organizer, User
- FluentValidation for all request objects
- Mapster for DTO mapping
- EF Core with SQL Server
- Pagination on all list endpoints (max 100 per page)
- Soft delete for Users and Events

#### AI Worker (Spotter.Worker)
- Separate RabbitMQ microservice
- **GeocodingConsumer**: receives venue name → calls Google Maps API → writes coordinates to DB
- **EmailConsumer**: sends confirmation emails for paid orders
- Retry logic with max 3 attempts, then discard
- Reconnection resilience with retry loop

#### ML.NET Recommender
- Content-based filtering using TF-IDF text featurization + FastTree binary classifier
- Training data: positive samples from paid orders, negative samples from non-interacted events
- Cold start: interest-based → city popularity → global popularity fallback
- Background service retrains every 24 hours
- Explainable recommendation reasons returned to mobile app

#### Payment (Stripe)
- Payment finalized server-side via webhook only
- Idempotency: duplicate webhook events are ignored
- Pending order expiration: orders unpaid after 30 minutes are automatically cancelled and inventory released
- Oversell prevention: atomic SQL UPDATE with concurrency check inside Serializable transaction

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend API | ASP.NET Core 9, C#, EF Core |
| Database | SQL Server 2022 (Docker) |
| Messaging | RabbitMQ (Docker) |
| AI Worker | .NET Worker Service |
| Mobile | Flutter (Android) |
| Desktop | Flutter (Windows) |
| Payments | Stripe (sandbox) |
| ML | ML.NET (TF-IDF + FastTree) |
| Auth | JWT (custom implementation) |
| Real-time | SignalR |

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Stripe CLI](https://stripe.com/docs/stripe-cli)

---

## Setup

1. Copy `.env.example` to `.env` in the root directory and fill in values
2. Start the full review stack:

```bash
docker compose up -d --build
```

The API runs EF Core migrations automatically on startup. On a clean Docker volume it creates database `230006`, applies all migrations, and seeds the review users listed below.

Verify the stack:

```bash
docker compose ps
docker compose logs api
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SPOTTER_SA_PASSWORD" -C -Q "SELECT name FROM sys.databases WHERE name = '230006'"
```

---

## Manual Run

```bash
docker compose up -d sqlserver rabbitmq
dotnet ef database update --project Spotter.Services --startup-project Spotter.WebAPI
dotnet run --project Spotter.WebAPI --urls="http://0.0.0.0:5126"
dotnet run --project Spotter.Worker
stripe listen --forward-to http://localhost:5126/api/payments/webhook
```

---

## Desktop App

```bash
cd UI/spotter_desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126
```

---

## Mobile App

Android emulator:

```bash
cd UI/spotter_mobile
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:5126
```

Physical Android device: find your laptop WiFi IP with `ipconfig`, then:

```bash
cd UI/spotter_mobile
flutter run -d <DEVICE_ID> \
  --dart-define=API_BASE_URL=http://<YOUR_WIFI_IP>:5126 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=<YOUR_STRIPE_PUBLISHABLE_KEY>
```

---

## API Documentation

- Base URL: `http://localhost:5126`
- Scalar UI: `http://localhost:5126/scalar`

---

## Test Credentials

| App | Username | Password | Role |
|-----|----------|----------|------|
| Desktop | `desktop` | `test` | Admin |
| Mobile | `mobile` | `test` | User |
| Mobile | `organizer` | `test` | Organizer |

Actual credentials and secrets are in `.env-tajne.zip`.

---

## Stripe Test Cards

| Card Number | Scenario |
|-------------|----------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 0002` | Card declined |

Use any future expiry date and any 3-digit CVC.

---

## Project Structure

```
Spotter/
├── Spotter.WebAPI/          # ASP.NET Core REST API
├── Spotter.Services/        # Business logic, EF Core, ML.NET
│   ├── Access/              # Auth, JWT, refresh tokens
│   ├── Events/              # Event management
│   ├── Orders/              # Order processing, Stripe
│   ├── Recommendations/     # ML.NET recommender
│   ├── Notifications/       # SignalR notifications
│   ├── Friendships/         # Social features
│   ├── Reports/             # Financial and guest list reports
│   ├── StateMachines/       # Order, Ticket, Event, Reservation state machines
│   └── ML/                  # ML.NET feature classes
├── Spotter.Model/           # DTOs, requests, responses, enums
├── Spotter.Worker/          # RabbitMQ AI Worker (geocoding, email)
├── UI/
│   ├── spotter_mobile/      # Flutter Android app
│   └── spotter_desktop/     # Flutter Windows admin app
├── docker-compose.yml       # SQL Server, RabbitMQ, API, Worker
├── .env.example             # Environment variable template
├── README.md
└── recommender-dokumentacija.md
```

---

## Building for Submission

### Mobile APK

```bash
cd UI/spotter_mobile
flutter clean
flutter build apk --release \
  --dart-define=API_BASE_URL=http://10.0.2.2:5126 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
```

APK location: `UI/spotter_mobile/build/app/outputs/flutter-apk/app-release.apk`

### Desktop Windows

```bash
cd UI/spotter_desktop
flutter clean
flutter pub get
flutter build windows --release \
  --dart-define=API_BASE_URL=http://localhost:5126
```

**Important:** ZIP the entire Release folder (not just the .exe):
`UI/spotter_desktop/build/windows/x64/runner/Release/`

The folder contains all required DLLs including `printing_plugin.dll`. Running only the .exe without the DLLs will fail.

---

## Recommender System

See [recommender-dokumentacija.md](recommender-dokumentacija.md) for full documentation of the ML.NET recommender system including algorithm description, TF-IDF featurization, FastTree classifier, cold start handling, and API contract.
