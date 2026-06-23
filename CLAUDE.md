# CLAUDE.md

## 1. Project Overview

Spotter is a full-stack event discovery and booking platform. The repository is a monorepo with four C# projects (`Spotter.Common.Services`, `Spotter.Model`, `Spotter.Services`, `Spotter.WebAPI`) forming the backend, and two Flutter apps under `UI/` (`spotter_desktop` — Windows admin panel, `spotter_mobile` — Android user app). A single `docker-compose.yml` at the root runs SQL Server 2022 on port 1435.

---

## 2. Architecture

- **Main API**: ASP.NET Core 9 (`Spotter.WebAPI`), port 5126 by default; talks to SQL Server via EF Core.
- **AI Worker**: Separate ASP.NET Core service (not yet scaffolded); listens to RabbitMQ, calls Google Maps Geocoding API, writes Latitude/Longitude back to Events and sets `GeocodingPending = false`.
- **Messaging**: RabbitMQ for async communication between Main API and AI Worker.
- **Real-time**: SignalR hub at `/hubs/notifications` for push notifications; JWT token passed via query string `access_token` for WebSocket authentication.
- **Auth**: Custom JWT (not ASP.NET Identity); HMAC-SHA256 tokens; refresh token table in DB; `InvalidatedTokens` table for server-side token invalidation.
- **Payments**: Stripe sandbox; always finalized server-side via webhook or server-side Stripe API verification.
- **ML**: ML.NET content-based recommender (TF-IDF + logistic regression); retrained every 24 h via `RecommendationTrainingService`.
- **Flutter**: `spotter_desktop` targets Windows (Admin); `spotter_mobile` targets Android (User). API base URL injected via `--dart-define=API_BASE_URL`.

---

## 3. Mandatory Patterns

- Controller → Service → DbContext; no business logic or DbContext in controllers.
- Services that use DbContext are registered as Scoped.
- DTOs for all request/response objects; never return an Entity directly from a controller.
- Custom exceptions: `ClientException` (client errors, 400) and `NotFoundException` (404); handled by `ExceptionFilter` registered globally.
- `ILogger<T>` for all logging; `Console.WriteLine` and `print()` are forbidden.
- `async`/`await` everywhere; `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` are forbidden.
- EF: always use async methods (`FirstOrDefaultAsync`, `ToListAsync`, `FindAsync`, `SaveChangesAsync`, etc.).
- Multiple `SaveChangesAsync()` in one operation → wrap in an explicit `IDbContextTransaction`.
- `IHttpClientFactory`; never `new HttpClient()`.
- `IHttpContextAccessor` to read the current `userId` from the JWT claim; never accept `userId` from route or body for the authenticated user.
- Magic numbers → enums or constants; role strings → a static `Roles` class.
- N+1 queries forbidden; use `Include`, projection, or batch queries.
- Filter at DB level (`Where` before materialisation); never load all rows then filter in memory.
- Pagination required on every list endpoint; max `PageSize = 100`.
- CORS defined once in `Program.cs`; `AddCors`/`UseCors` must not be called twice.

---

## 4. Authentication & Authorization Rules

- `[Authorize]` on every controller that accesses user data.
- `[AllowAnonymous]` only on `Login`, `LoginWithRefreshToken`, and `Register` endpoints.
- Admin-only endpoints: `[Authorize(Roles = Roles.Admin)]`.
- `Register` must not accept a role field from the client; role is always assigned server-side.
- File uploads: validate MIME type and magic bytes, not just file extension.

---

## 5. Database Conventions

- DB name: `230006`.
- All foreign keys defined via EF Fluent API in `eCommerceConfiguration.cs`; referential integrity enforced at DB level.
- Reference data (City, Category, TicketType, etc.) stored in separate tables with FK relationships; never a plain string column.
- Soft delete: `IsDeleted` + `DeletedAt`; hard delete of domain entities is an error; purge order must respect FK hierarchy (children before parents).
- Seed data must be consistent: same password-hash format in `HasData` and at runtime; include images if the domain uses them.
- Password hashing: HMAC-SHA1 via `CryptoService`; salt generated via `CryptoService.GenerateSlat()`.

---

## 6. Flutter Conventions

- Booleans → `Checkbox`/`Switch`; dates → `DateTimePicker`; FK/reference data → `DropdownButton` populated from API.
- Geographic coordinates → map picker modal or address-based input; never a plain `TextFormField`.
- Confirmation dialog required for: delete, payment, and order submission.
- Validation messages shown below the relevant field; not inside the field, not in an `AlertDialog`.
- Lists auto-refresh after add/edit without requiring a manual reload.
- Forms must not display raw database ID values.
- Every screen with navigation must have a Back button.
- All list views must be paginated.
- API base URL read from `String.fromEnvironment("API_BASE_URL")`; default `http://localhost:5126/` for desktop, `http://10.0.2.2:5126/` for Android emulator.

---

## 7. Stripe / Payment Rules

- Payment finalized server-side via Stripe webhook or server-side Stripe API call.
- Client must never record a successful payment.
- Server determines price from its own catalogue; never trust a price from the client.
- Idempotency: if payment status is already `Completed`, do not re-apply effects.
- Mobile: use Stripe `PaymentSheet` (in-app only).

---

## 8. Reservation State Machine

- States: `Pending` → `Confirmed` → `Cancelled` / `Completed`.
- Hard delete of a reservation is an error; use status transitions only.
- All transition logic is centralised (not scattered across controllers).
- Audit trail fields: `ApprovedByUserId`, `ApprovedAt`, `AuditNote`.

---

## 9. Notifications

- Fields: `IsRead`, `Title`, `Body`, `CreatedAt`, `Type`, `ReferenceId`.
- Auto-refresh via SignalR or polling; manual refresh is not acceptable.

---

## 10. Spotter-Specific Features

- **Mobile map view**: color-coded pins by category; toggle between map and list/feed.
- **Recommender**: ML.NET TF-IDF + logistic regression; retrained every 24 h; each recommendation includes an explainable reason string (e.g. "Because you attended similar concerts").
- **Cold start**: show popular events in the user's city and interest categories selected at registration.
- **AI Worker flow**: Main API publishes location name to RabbitMQ → AI Worker calls Google Maps Geocoding API → writes `Latitude`/`Longitude` back to `Events` table → sets `GeocodingPending = false`.
- **Waitlist**: automatic notification to the first person on the list when a spot becomes available.
- **Spotter points**: earned via ticket purchases and reviews; redeemable for discounts; stored as a ledger (each earn/redeem is a new `SpotterPoints` row with a `Delta` column).
- **QR tickets**: `QrCodePayload` stored in `Tickets` table; saved locally on the device for offline use.
- **PDF reports**: Financial Report and Guest List, filterable by date range and category.

---

## 11. What NOT To Do

- Never write code comments of any kind: no XML doc comments, no inline comments, no block comments, no TODO comments, no commented-out code.
- Never leave `WeatherForecastController`, `WeatherForecast.cs`, or `Class1.cs` template files.
- Never use `NotImplementedException`.
- Never use `dynamic` types.
- Never hardcode secrets, connection strings, or API keys; always read from environment variables or `appsettings` backed by environment overrides.
- Never put `.env` files in the repository.
- Never accept `userId` from the request body or route for the currently authenticated user.
- Never return Entity objects from API endpoints.
- Never call `new HttpClient()`.
- Never use `Console.WriteLine` or Flutter `print()` for logging.
- Never add unused imports or dead code.
- Never use synchronous EF methods (`Find`, `SaveChanges`, `ToList` without `Async`).
- Never filter after materialisation (no `ToList()` then `.Where(...)`).

---

## 12. Current Project State

### Implemented and Working
- JWT auth (access token + refresh token + logout with token invalidation); custom `ExceptionFilter`; `AuthorizationAttribute` for role-based access.
- `AccessController` with `[AllowAnonymous]` attribute; endpoints: `Login`, `Refresh`, `Logout`, `Register`.
- `AccessService` in service layer with proper `ILogger<AccessService>`, throws `ClientException`/`NotFoundException` for errors.
- `CurrentUserService` (`ICurrentUserService`) reads JWT claims (`sub`, `unique_name`, `role`) via `IHttpContextAccessor`; `IsAdmin()` checks against `Roles.Admin`.
- `Roles` static class in `Spotter.Model.Static` with constants: `Admin`, `User`, `Organizer`.
- Generic `BaseCRUDController` / `BaseCRUDService` / `BaseReadService` pattern with `PageResult<T>` pagination; `ApplyFilters` operates on `IQueryable<TEntity>`; `GetAllAsync` pipeline stays as `IQueryable` until `ToListAsync`; `PageSize` capped at 100 (defaults to 20); all `Find` calls replaced with `FindAsync`; null-safe search parameter handling.
- `ClientException` (400) and `NotFoundException` (404) in `Spotter.Model.Exceptions`; both handled by `ExceptionFilter`.
- FluentValidation for `UserInsertRequest`, `UserUpdateRequest`, `UserLoginRequest`, `RegisterRequest`, `CityInsertRequest`, `CityUpdateRequest`, `CategoryInsertRequest`, `CategoryUpdateRequest`, `VenueInsertRequest`, `VenueUpdateRequest`, `EventInsertRequest`, `EventUpdateRequest`, `TicketTypeInsertRequest`, `TicketTypeUpdateRequest`, `OrderInsertRequest`, `ReviewInsertRequest`, `ReviewUpdateRequest`, `ReservationInsertRequest`, `WaitlistJoinRequest`; validators wired in `Program.cs`.
- Mapster DTO mapping; `SpotterDbContext` with Fluent API configuration and seed data (`SpotterSeed.cs`).
- All domain entities scaffolded and present in `SpotterDbContext` with an initial migration applied: `User`, `Role`, `UserRole`, `RefreshToken`, `InvalidatedToken`, `Product`, `ProductType`, `UnitOfMeasure`, `Category`, `Asset`, `Cart`, `CartItem`, `Order`, `OrderItem`, `Review`, `Badge`, `UserBadge`, `UserInterest`, `Event`, `Venue`, `Ticket`, `TicketType`, `Reservation`, `Notification`, `Favorite`, `Friendship`, `EventTag`, `Recommendation`, `SpotterPoints`, `WaitlistEntry`, `City`, `SystemSetting`, `SpotterConfiguration`.
- Enums in `Spotter.Model.Enums`: `EventStatus`, `FriendshipStatus`, `NotificationType` (General, WaitlistSpotAvailable, ReservationConfirmed, ReservationCancelled, NewBadge, OrderCreated, OrderPaid, WaitlistUpdate), `OrderStatus`, `PointSource`, `RecommendationSection`, `ReservationStatus`, `TicketStatus`, `TicketTypeEnum`.
- Product state machine: `InitialProductState` → `DraftProductState` → `ActiveProductState`.
- **Centralized state machines** in `Spotter.Services.StateMachines`: `BaseStateMachine<TEntity, TStatus>` abstract base class with `AllowedTransitions` dictionary and `Transition()` method that throws `ClientException` on invalid transitions; `EventStateMachine` (Draft→Active/Cancelled, Active→Cancelled/Completed); `OrderStateMachine` (Pending→Paid/Refunded, Paid→Refunded); `TicketStateMachine` (Active→Used/Cancelled, sets `UsedAt` on Used); `ReservationStateMachine` (Pending→Confirmed/Cancelled, Confirmed→Completed/Cancelled, sets `ApprovedAt` on Confirmed); all registered as Scoped in `Program.cs`.
- `CryptoService` (HMAC-SHA1 password hashing).
- `QueryOptimizationService` (demonstration of good/bad EF query patterns).
- **City CRUD**: `CityController` (route `api/cities`), `CityService`, DTOs (`CityInsertRequest`, `CityUpdateRequest`, `CityResponse`, `CitySearch`), validators; delete protection checks User/Venue references; GET is `[AllowAnonymous]` for dropdowns.
- **Category CRUD**: `CategoryController` (route `api/categories`), `CategoryService`, DTOs (`CategoryInsertRequest`, `CategoryUpdateRequest`, `CategoryResponse`, `CategorySearch`), validators with ColorHex regex `^#[0-9A-Fa-f]{6}$`; delete protection checks Event/UserInterest references.
- **Venue CRUD**: `VenueController` (route `api/venues`), `VenueService` with `Include(City)` for `CityName` mapping, DTOs (`VenueInsertRequest`, `VenueUpdateRequest`, `VenueResponse`, `VenueSearch`), validators; CityId validation on insert/update; delete protection checks Event references.
- **Event CRUD**: `EventController` (route `api/events`), `EventService` with `Include(Category, Venue.City, Organizer, TicketTypes)` for response mapping; DTOs (`EventInsertRequest`, `EventUpdateRequest`, `EventResponse`, `EventSearch`); validators with future-date check on insert; `InsertAsync` sets `OrganizerId` from `ICurrentUserService`, `Status = Draft`; `UpdateAsync` checks organizer ownership or admin; `DeleteAsync` is soft delete (`IsDeleted`, `DeletedAt`, `Status = Cancelled`) with paid-orders protection; `ActivateAsync` requires at least one ticket type and uses `EventStateMachine`; `CancelAsync` uses `EventStateMachine`; `CompleteAsync` (admin-only) uses `EventStateMachine`; GET endpoints are `[AllowAnonymous]`, POST requires `Roles.Organizer`.
- **TicketType CRUD**: `TicketTypeController` (route `api/ticket-types`), `TicketTypeService` with `Include(Event)` for `EventTitle` mapping; DTOs (`TicketTypeInsertRequest`, `TicketTypeUpdateRequest`, `TicketTypeResponse`, `TicketTypeSearch`); validators with enum validation; `InsertAsync` blocks cancelled events; `UpdateAsync` blocks reducing `TotalQuantity` below `SoldQuantity`; `DeleteAsync` is hard delete but blocks if `SoldQuantity > 0`; GET endpoints are `[AllowAnonymous]`, write endpoints require `Roles.Organizer`.
- **Order flow**: `OrderController` (route `api/orders`), `OrderService` (does not extend BaseCRUDService); DTOs (`OrderInsertRequest`, `OrderItemRequest`, `OrderResponse`, `OrderItemResponse`, `OrderSearch`); validator with nested item validation; `CreateOrderAsync` validates event is active, checks ticket availability, creates order + order items + tickets in explicit transaction, updates `SoldQuantity`, generates QR payloads; `MarkAsPaidAsync` uses `OrderStateMachine` for `Pending` → `Paid`, earns SpotterPoints (1 per 10 BAM, min 1), triggers badge evaluation; `RefundAsync` uses `OrderStateMachine` for `Paid` → `Refunded` and `TicketStateMachine` for cancelling tickets, restores `SoldQuantity`, notifies next waitlist entry; non-admin users can only see their own orders.
- **Ticket flow**: `TicketController` (route `api/tickets`), `TicketService` (does not extend BaseCRUDService); DTOs (`TicketResponse`, `TicketSearch`, `UseTicketRequest`); `GetAllAsync`/`GetByIdAsync` enforce user ownership for non-admins; `UseTicketAsync` is admin-only, checks event start time (within 2 hours), uses `TicketStateMachine` to transition `Active` → `Used` (sets `UsedAt` automatically), triggers badge evaluation.
- **Review CRUD**: `ReviewController` (route `api/reviews`), `ReviewService`; DTOs (`ReviewInsertRequest`, `ReviewUpdateRequest`, `ReviewResponse`, `ReviewSearch`); validators with Rating 1-5; `InsertAsync` checks user attended event (has Active/Used ticket), prevents duplicate reviews, awards 10 SpotterPoints via `ISpotterPointsService`, triggers badge evaluation; `DeleteAsync` is soft delete, reverses SpotterPoints if balance allows; GET endpoints are `[AllowAnonymous]`.
- **Favorite flow**: `FavoriteController` (route `api/favorites`), `FavoriteService`; DTOs (`FavoriteResponse`, `FavoriteSearch`); `GetMyFavoritesAsync` returns current user's favorites; `AddFavoriteAsync` prevents duplicates; `RemoveFavoriteAsync` is hard delete.
- **Friendship flow**: `FriendshipController` (route `api/friendships`), `FriendshipService`; DTOs (`FriendshipResponse`, `FriendshipSearch`); state machine: `Pending` → `Accepted`/`Rejected`/`Blocked`; `SendRequestAsync` prevents self-requests and duplicates, sends notification to addressee; `AcceptAsync`/`RejectAsync` only by addressee, `AcceptAsync` notifies requester; `BlockAsync` by either party; `DeleteAsync` is hard delete.
- **Notification system**: `NotificationController` (route `api/notifications`), `NotificationService` with SignalR real-time push; DTOs (`NotificationResponse`, `NotificationSearch`); `GetMyNotificationsAsync` returns current user's notifications with pagination; `GetUnreadCountAsync` returns count; `MarkAsReadAsync`/`MarkAllAsReadAsync` update `IsRead` flag; `CreateAsync` persists notification and pushes via SignalR `IHubContext<NotificationHub>` to user-specific group.
- **SignalR hub**: `NotificationHub` at `/hubs/notifications` with `[Authorize]`; `OnConnectedAsync` adds connection to group named by userId; `OnDisconnectedAsync` removes from group; clients receive `ReceiveNotification` event with `NotificationResponse` payload.
- **Notification integrations**: `OrderService.CreateOrderAsync` sends "Order Created" notification (`NotificationType.OrderCreated`); `OrderService.MarkAsPaidAsync` sends "Payment Successful" notification (`NotificationType.OrderPaid`); `ReviewService.InsertAsync` sends "Review Submitted" with SpotterPoints info; `FriendshipService.SendRequestAsync` sends "New Friend Request"; `FriendshipService.AcceptAsync` sends "Friend Request Accepted"; `ReservationService` sends notifications on create/confirm/cancel (`ReservationConfirmed`, `ReservationCancelled`); `BadgeService.EvaluateAndAwardAsync` sends "New Badge Earned!" notification (`NewBadge`); `WaitlistService.JoinAsync` sends "Added to Waitlist" notification (`WaitlistUpdate`); `WaitlistService.NotifyNextInLineAsync` sends "Spot Available!" notification (`WaitlistSpotAvailable`).
- **Reservation flow**: `ReservationController` (route `api/reservations`), `ReservationService`; DTOs (`ReservationInsertRequest`, `ReservationResponse`, `ReservationSearch`); validator with EventId > 0 and Note max 500 chars; `CreateAsync` checks event is active, prevents duplicate active reservations, sends notification; `ConfirmAsync` (admin-only) uses `ReservationStateMachine`, sets `ApprovedByUserId`/`ApprovedAt`, sends notification; `CancelAsync` uses `ReservationStateMachine`, admin can cancel others' reservations with notification; `CompleteAsync` (admin-only) uses `ReservationStateMachine`; non-admin users can only see their own reservations; soft delete via `IsDeleted`; Mapster config maps `EventTitle`, `UserFullName`, `StatusName`, `ApprovedByName`.
- **SpotterPoints flow**: `SpotterPointsController` (route `api/points`), `SpotterPointsService`; DTOs (`SpotterPointsResponse`, `PointsBalanceResponse`, `SpotterPointsSearch`); `GetLedgerAsync` returns paginated ledger entries (non-admin sees only own); `GetBalanceAsync` returns balance/totalEarned/totalRedeemed; `EarnAsync` creates positive delta entry and updates `User.SpotterPointsBalance`; `RedeemAsync` validates sufficient balance, creates negative delta entry; integrated into `ReviewService` and `OrderService`.
- **Badge flow**: `BadgeController` (route `api/badges`), `BadgeService`; DTOs (`BadgeResponse`, `UserBadgeResponse`, `BadgeSearch`); `BadgeCriteria` static class with constants (FirstPurchase=1, TenReviews=2, NightOwl=3, Foodie=4, EarlyBird=5, MusicLover=6); `GetAllBadgesAsync` returns all badges (`[AllowAnonymous]`); `GetUserBadgesAsync` returns user's earned badges; `EvaluateAndAwardAsync` checks all criteria and awards missing badges with notification; triggered after `MarkAsPaidAsync`, `ReviewService.InsertAsync`, and `TicketService.UseTicketAsync`.
- **Waitlist flow**: `WaitlistController` (route `api/waitlist`), `WaitlistService`; DTOs (`WaitlistJoinRequest`, `WaitlistEntryResponse`, `WaitlistSearch`); validator with EventId/TicketTypeId > 0; `GetAllAsync` returns paginated entries (non-admin sees only own); `JoinAsync` validates event is active, tickets are sold out, no duplicate entries, assigns position, sends notification; `LeaveAsync` removes entry and reorders remaining positions; `NotifyNextInLineAsync` marks first unnotified entry as notified and sends `WaitlistSpotAvailable` notification; called from `OrderService.RefundAsync` when tickets become available.
- Active API controllers: `AccessController`, `UsersController`, `CityController`, `CategoryController`, `VenueController`, `EventController`, `TicketTypeController`, `OrderController`, `TicketController`, `ReviewController`, `FavoriteController`, `FriendshipController`, `NotificationController`, `ReservationController`, `SpotterPointsController`, `BadgeController`, `WaitlistController`, `PaymentController`, `RecommendationController`.
- **ML.NET Recommendation System**: `RecommendationService` with content-based recommender using TF-IDF + FastTree binary classifier; `RecommendationTrainingService` (BackgroundService) retrains every 24h; `RecommendationController` at `api/recommendations` with `GET /` (user recommendations) and `POST /train` (admin-only); `RecommendationResponse` DTO with EventId, Title, CategoryName, CategoryColorHex, CoverImageUrl, StartsAt, VenueName, CityName, Score, Explanation; ML models in `Spotter.Services/ML/` (`EventFeatures`, `EventPrediction`); cold start fallback for new users based on city and interest categories; `User.UserInterests` navigation property added; explanations like "Because you like Music" or "Popular event in your city".
- **Stripe payment integration**: `PaymentController` (route `api/payments`), `IStripeService`/`StripeService`; `CreatePaymentIntentRequest` and `PaymentIntentResponse` DTOs; `POST /api/payments/create-intent` creates Stripe PaymentIntent with order metadata; `POST /api/payments/webhook` handles `payment_intent.succeeded` and `payment_intent.payment_failed` events; webhook endpoint uses raw body buffering middleware; order is marked as paid via `IOrderService.MarkAsPaidAsync` when webhook confirms payment; environment variables `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` configure Stripe; Order entity has `StripePaymentIntentId` field.
- CORS policy defined in `Program.cs` (`SpotterPolicy` with specific origins `localhost:5126`, `10.0.2.2:5126`, `localhost:3000` and `AllowCredentials` for SignalR WebSocket support).
- `IHttpContextAccessor` wired in DI via `builder.Services.AddHttpContextAccessor()`.
- **Desktop Flutter** (`UI/spotter_desktop`): Complete admin panel with Dio HTTP client, Provider state management, and Material 3 theme (purple seed `#7C3AED`). Structure: `lib/core/constants/` (ApiConstants, AppColors), `lib/core/models/` (27 DTOs), `lib/core/providers/` (13 providers), `lib/widgets/` (reusable components), `lib/features/` (10 feature modules). Screens: Login → Dashboard (stats cards + orders chart via fl_chart) → navigation drawer with sections (Overview, Management, Operations, Reports). CRUD screens for Users, Cities, Categories, Venues (with flutter_map OpenStreetMap picker), Events (with status actions: Activate/Cancel/Complete), Ticket Types. Operations screens for Orders (detail + Mark as Paid/Refund), Tickets (Mark as Used), Reservations (detail + Confirm/Cancel/Complete), Reviews. **Reports screen** generates styled PDFs using pdf/printing packages: Financial Report (date range + category filter, summary box with total orders/revenue, styled table with purple header and alternating rows, dd.MM.yyyy date format, BAM currency); Guest List (event selector, summary with Active/Used/Cancelled counts, ticket holder table). Provider methods: `OrderProvider.loadForReport()` with date filtering, `TicketProvider.loadForGuestList()`. All lists paginated (10 items), debounced search (400ms), confirmation dialogs on delete/destructive actions. Login restricted to Admin role only. Run with: `flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126`.
- **Mobile Flutter** (`UI/spotter_mobile`): Complete Android user app with Dio HTTP client, Provider state management, Material 3 theme (purple seed `#7C3AED`). Structure: `lib/core/constants/` (ApiConstants, AppColors, navigatorKey), `lib/core/models/` (19 DTOs), `lib/core/providers/` (11 providers: Auth, Base, Event, Ticket, Order, Reservation, Favorite, Notification, Profile, Review, Payment), `lib/features/` (11 feature modules). Auth: Login with SharedPreferences token persistence, Register with city dropdown from API, auto-login on app start, **automatic redirect to login on 401 (session expiry)** via global navigator key in BaseProvider interceptor. Home: Bottom navigation with 5 tabs (Map, Events, Tickets, Favorites, Profile) + notification bell with unread badge. Map: Full-screen flutter_map with OpenStreetMap tiles, colored markers by category, category filter chips, "Near me" geolocation button, toggle to list view. Events: Event list with search (400ms debounce), category filters, infinite scroll pagination, pull-to-refresh; Event detail with cover image, venue map preview, ticket types list, reviews section, Buy Tickets / Reserve / Favorite buttons. Orders: Checkout with quantity selectors per ticket type, Spotter Points redemption toggle, Stripe PaymentSheet integration via flutter_stripe, confirmation dialog; Order history and detail screens. Tickets: Tabbed view (Active/Used/Cancelled), ticket detail with QR code via qr_flutter, QR payload cached in SharedPreferences for offline. Favorites: List with remove confirmation dialog. Notifications: List with unread highlighting, mark as read, polling every 30s. Reservations: List with status chips (color-coded), cancel pending reservations. Profile: Avatar with initials, points balance, badges horizontal scroll, Edit Profile / My Orders / My Reservations actions, logout with confirmation. All lists have pull-to-refresh and empty states. Validation messages below fields. No code comments. Run with: `flutter run -d <device> --dart-define=API_BASE_URL=http://10.0.2.2:5126 --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY`.
- Docker Compose: SQL Server 2022 on port 1435, RabbitMQ 3.13 on ports 5672/15672.
- **AI Worker project** (`Spotter.Worker`): ASP.NET Core Worker Service consuming RabbitMQ queues; `GeocodingConsumer` processes `spotter.geocoding` queue, calls Google Maps Geocoding API via `GeocodingService`, writes `Latitude`/`Longitude` back to Events; `EmailConsumer` processes `spotter.email` queue via `EmailService` (SMTP); `WorkerDbContext` has minimal DbSets (Event, Notification, User); uses RabbitMQ.Client v7 async API (`IChannel`, `AsyncEventingBasicConsumer`).
- **RabbitMQ publisher** in main API: `IRabbitMqPublisher`/`RabbitMqPublisher` singleton; `EventService.InsertAsync` publishes `GeocodingRequestMessage` after event creation.
- **Message contracts** in `Spotter.Model/Messages/`: `GeocodingRequestMessage`, `EmailMessage`, `QueueNames` (constants: `spotter.geocoding`, `spotter.email`).
- Default connection string uses DB name `230006`.

### Stubbed or Partially Done
- `AssetsController`, `ProductTypesController`, `ProductsController`, `QueryOptimizationController`, `UnitOfMeasuresController` have been deleted — their services may still exist but are inaccessible via API.
- `Cart`, `CartItem` entities exist in `DbContext` but have no services, controllers, or Flutter screens.

### Missing Entirely
- Services, controllers, DTOs, and validators for Cart.
- Soft delete (`IsDeleted` / `DeletedAt`) on remaining domain entities (Event, Review, and Reservation already implement soft delete).
- Mobile Flutter: Friendships screen, waitlist management screen, SignalR real-time notifications (currently uses polling).

### Recently Fixed Violations
- `WeatherForecast.cs` and `Class1.cs` deleted.
- `appsettings.json` now uses environment variable fallbacks for connection string (`SPOTTER_CONNECTION_STRING`) and JWT secret (`SPOTTER_JWT_KEY`); hardcoded values removed.
- `appsettings.Development.json` simplified to logging config only.
- `docker-compose.yml` uses `env_file: .env` for `SA_PASSWORD`; `.env.example` added as template.
- `BaseReadService.SortBy` now uses `_allowedSortColumns` whitelist to sanitise input (allows: Id, CreatedAt, UpdatedAt, Name, Title, StartsAt, Price, Rating).
- All service classes now have `ILogger<T>` injection: `AccessService`, `UserService`, `CityService`, `CategoryService`, `VenueService`, `EventService`, `TicketTypeService`, `OrderService`, `TicketService`, `ReviewService`, `FavoriteService`, `FriendshipService`, `NotificationService`, `ReservationService`, `RefreshTokenService`, `SpotterPointsService`, `BadgeService`, `WaitlistService`.
- `DraftProductState` and `ProductService` files no longer exist (controllers deleted previously).
- **Desktop Flutter completely rebuilt**: Deleted all template leftovers (Product, Asset, UnitOfMeasure, ProductType screens/models/providers); removed all `print()` calls; fixed `BaseProvider` to use `String.fromEnvironment("API_BASE_URL")`; no code comments in any Flutter file; all screens follow Flutter conventions (validation below fields, confirmation dialogs, pagination, dropdowns from API, map picker for coordinates). Login restricted to Admin role only.
- **Mobile Flutter completely rebuilt**: Deleted all template leftovers (Product, Asset screens/models/providers); implemented 55 Dart files from scratch with proper architecture (`core/constants`, `core/models`, `core/providers`, `features/*`); Dio HTTP client with BaseProvider pattern; SharedPreferences for token persistence and offline QR codes; flutter_map for OpenStreetMap with colored category markers; qr_flutter for ticket QR codes; geolocator for "Near me" functionality; intl for date formatting; cached_network_image for event covers; no `print()` calls; no code comments; all screens follow Flutter conventions.
- **Mobile session expiry handling**: `BaseProvider` has `onUnauthorized` callback and `_handleUnauthorized()` method; on 401 response (except login/register), clears SharedPreferences, calls `AuthProvider._clearSession()`, and navigates to LoginScreen via global `navigatorKey`; `_isRedirecting` flag prevents duplicate redirects from concurrent requests; `navigatorKey` defined in `lib/core/constants/navigator_key.dart` and assigned to `MaterialApp` in `main.dart`.
- **Desktop PDF reports enhanced**: `ReportsScreen` rewritten with two side-by-side cards (Financial Report, Guest List); Financial Report has From/To date pickers with validation, optional category dropdown; Guest List has required event selector with validation error display; loading indicators on Generate buttons; styled PDFs with SPOTTER header, primary color `#7C3AED`, alternating row colors, footer with page numbers.
- **ML.NET recommendation system implemented**: `IRecommendationService`/`RecommendationService` with TF-IDF text featurization + FastTree binary classifier; `RecommendationTrainingService` (BackgroundService) trains model on startup and every 24h; training data built from paid orders (positive) and random event/user pairs (negative); `SemaphoreSlim` prevents concurrent training; cold start for users without order history uses city + interest categories; `User` entity now has `UserInterests` navigation property; NuGet packages: `Microsoft.ML` 4.0.0, `Microsoft.ML.FastTree` 4.0.0, `Microsoft.Extensions.Hosting.Abstractions` 9.0.0.
- **Mobile recommendations section**: `RecommendationProvider` fetches recommendations from API; `RecommendationResponse` model; `EventListScreen` converted to `CustomScrollView` with SliverList; "Recommended for you" horizontal scroll section at top with `_RecommendationCard` widgets (180px wide, 220px tall container, 110px image, compact text) showing title and explanation; loads on screen init and pull-to-refresh.
- **Mobile UI fixes**: `_RecommendationCard` overflow fixed with `mainAxisSize: MainAxisSize.min` on Columns, reduced font sizes, and increased container height; `EventDetailScreen` ticket type ListTile trailing Column overflow fixed with smaller font sizes (14/11); Reserve button text wrapping fixed by removing `Expanded` wrapper and adding explicit padding.
- **Event description optional**: `EventInsertRequest`, `EventUpdateRequest`, and `Event` entity have nullable `string? Description`; validators use `.MaximumLength(2000).When(x => x.Description != null)` instead of `.NotEmpty()`; desktop event form already labels field as "(optional)".
- **UsersController fixes**: Added `[Authorize]` attribute at controller level; `GetAll` now has `[Authorization(Roles.Admin)]`; added `GET /me` and `PUT /me` endpoints using `ICurrentUserService.GetUserId()` instead of accepting userId from route; `UserService.ApplyFilters` now excludes soft-deleted users (`!u.IsDeleted`).
- **Desktop event creation workflow**: `EventProvider.insert()` now returns `EventResponse`; `EventFormScreen` shows dialog after successful event creation offering to add ticket types; `TicketTypeFormScreen` has new `preselectedEventId` parameter.
- **Mobile profile endpoints**: `ProfileProvider.loadProfile()` and `updateProfile()` now use `/api/users/me` instead of `/api/users/{userId}`; removed userId parameters from method signatures.
- **Event activation notifications**: `EventService.ActivateAsync` now sends `NewEventInCity` notifications to users in the event's city after activation (not just on creation), since most events start as Draft.
- **UserUpdateRequest fixes**: Added `CityId` field as nullable int; `UserUpdateValidator` now uses conditional validation (`.When(x => !string.IsNullOrEmpty(x.Field))`) so all fields are optional for partial updates.
- **Dashboard totalCount fix**: `DashboardProvider.loadStats()` now passes `includeTotalCount: true` to all API requests so `BaseReadService` actually runs `CountAsync()` and returns the total.
- **Desktop session expiry handling**: Added `shared_preferences` package; `BaseProvider` has 401 interceptor that clears SharedPreferences and redirects to LoginScreen via `navigatorKey`; `_isRedirecting` flag prevents duplicate redirects; `navigatorKey` defined in `lib/core/constants/navigator_key.dart` and assigned to `MaterialApp` in `main.dart`.
- **NotificationResponse parsing fix**: `referenceId` field in `NotificationResponse.fromJson` now handles both `int` and `String` types (backend returns String via Mapster config), preventing JSON parsing errors.
- **Change password feature**: `ChangePasswordRequest` model, `ChangePasswordValidator`, `IUserService.ChangePasswordAsync`, `UserService.ChangePasswordAsync` implementation, `POST /api/users/change-password` endpoint; mobile `ChangePasswordScreen` with validation below fields, obscured password inputs, and navigation from profile screen.
