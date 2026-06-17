# Recommender System Documentation

**Project:** Spotter – Smart Event Discovery and Booking
**Course:** Software Development II
**Student:** Dino Burić (IB230006)
**Academic Year:** 2025/2026
**Mentors:** prof. dr. Elmir Babović, prof. dr. Denis Mušić

---

## 1. Introduction

This document describes the design, implementation, and operation of the recommender system built into the Spotter platform — a smart event discovery and booking application developed as part of the Software Development II seminary project.

The recommender system is one of the key features of Spotter. Its purpose is to increase user engagement by displaying events that match each user's individual tastes and behavior, rather than showing a generic list of all available events. The system answers a simple but important question for every user opening the mobile app: "Which of the hundreds of upcoming events should I actually care about?"

The recommender is implemented as a background process inside the ASP.NET Core Web API using ML.NET — Microsoft's open-source machine learning framework for .NET. It uses a content-based filtering approach combined with a binary classification model (FastTree) trained on historical paid order data. Recommendations are exposed through a dedicated REST endpoint and consumed by the Flutter mobile application, which displays them in a horizontally scrollable "Recommended for you" section at the top of the Events tab.

---

## 2. Goals of the Recommender System

The primary goals of the recommender component are:

- Provide each user with a short list of relevant upcoming events tailored to their interests and purchase history.
- Explain why each event is being recommended (e.g. "Because you like Music") to build user trust in the system.
- Solve the cold-start problem for new users who have no interaction history.
- Automatically retrain the model on a fixed schedule so recommendations stay fresh as new events and orders are added.
- Operate efficiently with minimal latency on a single request to the API.

---

## 3. System Architecture

The recommender consists of four main components, all running inside the `Spotter.WebAPI` process:

### 3.1. RecommendationService

The core service that builds training data, trains the ML.NET pipeline, and produces recommendations on demand. It is registered as a singleton in the dependency injection container because the trained model is held in memory across requests.

### 3.2. RecommendationTrainingService

An ASP.NET Core `BackgroundService` that runs the training cycle automatically every 24 hours. On application startup it performs an initial training pass so the system has a usable model from the first request.

### 3.3. RecommendationController

Exposes two REST endpoints:

- `GET /api/recommendations` — returns the top recommendations for the currently authenticated user.
- `POST /api/recommendations/train` — triggers manual model retraining (Admin only).

### 3.4. ML.NET Pipeline

A content-based filtering pipeline that featurizes textual data using TF-IDF (Term Frequency–Inverse Document Frequency) and feeds the resulting numeric vectors into a FastTree binary classifier. The pipeline outputs a probability score between 0 and 1 indicating how likely a user is to be interested in a given event.

---

## 4. Algorithm Description

### 4.1. Content-Based Filtering

Content-based filtering recommends items to a user based on the textual characteristics of items the user has previously interacted with, rather than on what similar users have done (which would be collaborative filtering). For Spotter, the content of each event includes its title, description, category name, venue name, and city. The content of each user is represented by the categories they have selected as interests at registration and the categories of events they have previously purchased tickets for.

The advantage of content-based filtering for Spotter is that it works even when users have very little overlap in attended events — which is typical for a regional event platform with hundreds of users and only a handful of events per city per month.

### 4.2. TF-IDF Featurization

All textual inputs are transformed into numeric feature vectors using TF-IDF, applied to character n-grams via the ML.NET `FeaturizeText` transformer. TF-IDF assigns higher weight to words that appear frequently within a single document but rarely across the entire corpus, which makes domain-specific terms (e.g. "jazz", "hackathon", "marathon") more influential than generic words.

Each event is represented as a single concatenated string of the form:

```
"{userProfile} {categoryName} {title} {venueName} {cityName}"
```

This string is then featurized into a sparse numeric vector that the classifier can consume.

### 4.3. FastTree Binary Classifier

FastTree is a gradient-boosted decision tree implementation from ML.NET. It is well suited to the small-to-medium training datasets typical of an early-stage platform like Spotter, and it produces a probability output that is directly interpretable as a relevance score.

The classifier is trained on a binary label:

- **Label = 1 (positive):** The user actually purchased a ticket for this event (extracted from paid orders in the database).
- **Label = 0 (negative):** Randomly sampled events the user did not interact with, used as negative examples to give the model contrast.

### 4.4. Training Pipeline

The training pipeline is built using the ML.NET fluent API and consists of three stages:

```csharp
var pipeline = mlContext.Transforms.Text
    .FeaturizeText("Features", "Features")
    .Append(mlContext.BinaryClassification.Trainers
        .FastTree(labelColumnName: "Label",
                  featureColumnName: "Features"));
```

During training, the service:

- Loads all paid orders from the database, joining each order with its event, category, user, and the user's selected interests.
- Builds a positive training example for each (user, purchased event) pair.
- Generates an equal number of negative examples from random events the user did not purchase.
- Trains the FastTree classifier on the combined dataset.
- Replaces the previously held in-memory model with the newly trained one.

Concurrent training calls are prevented by a `SemaphoreSlim` guard so that two requests cannot trigger overlapping retraining cycles.

### 4.5. Scoring and Ranking

When a user opens the Events tab, the mobile app calls `GET /api/recommendations`. The service then:

- Loads the authenticated user including their selected interests and city.
- Loads the user's previously attended events (paid orders only) so they can be excluded from recommendations.
- Loads all currently active, upcoming, non-deleted events with their categories, venues, and ticket types.
- Builds a feature vector for each candidate event using the user's profile string.
- Runs each feature vector through the trained model's prediction engine to obtain a probability score.
- Sorts all candidate events by score descending and returns the top 5.

---

## 5. Cold Start Problem

The cold start problem occurs when a new user has no ticket purchase history, so the model has nothing to learn their taste from. Spotter handles this in three layers, in order of preference:

### 5.1. Layer 1 — Interest-Based Recommendations

During registration, every user selects categories they are interested in (e.g. Music, Sport, Food). These selected categories are stored in the `UserInterests` table and are included in the user profile string passed to the model. This means that even on the very first session, recommendations can be biased toward events matching the user's declared preferences.

When no purchase history exists, the service falls back to a deterministic interest-based scoring routine that ranks events by the following weighted criteria:

- Category match against the user's selected interests (highest weight).
- Same city as the user's home city.
- Sales ratio (popularity proxy — fraction of available tickets already sold).

### 5.2. Layer 2 — Popularity in the User's City

If the user has neither purchase history nor selected interests, the service falls back to pure popularity-based recommendations within the user's home city. Events with the highest ticket sales ratio in the user's city are surfaced first.

### 5.3. Layer 3 — Global Popularity

As a last-resort fallback, if no city-local events exist, the service returns globally popular events sorted by ticket sales ratio. This guarantees the user never sees an empty recommendation section.

---

## 6. Explainable Recommendations

Every recommendation returned to the user is accompanied by a short, human-readable explanation. This is an explicit project requirement and a key trust-building feature. The explanation is generated server-side and chosen based on the strongest matching signal for that user-event pair:

| Signal | Explanation Shown |
|---|---|
| Event category matches a user interest | "Because you like {category}" |
| User has attended at least one event | "Because you attended similar events" |
| Event is in the user's home city | "Popular event in your city" |
| Generic fallback | "Recommended for you" |

---

## 7. Implementation Details

### 7.1. Backend (.NET)

The recommender lives in the `Spotter.Services` project under the following files:

- `IRecommendationService.cs` — public interface for the service.
- `RecommendationService.cs` — full implementation of training, scoring, and ranking.
- `RecommendationTrainingService.cs` — `BackgroundService` that schedules retraining.
- `ML/EventFeatures.cs` — ML.NET input class with the `Features` and `Label` columns.
- `ML/EventPrediction.cs` — ML.NET output class with the predicted `Probability`.

The controller (`Spotter.WebAPI/Controllers/RecommendationController.cs`) exposes the two endpoints. The DTO returned to the client is `Spotter.Model.Responses.RecommendationResponse`.

### 7.2. Database Tables Used

- **Users** — user identity, home city, role.
- **UserInterests** — many-to-many between users and categories, populated at registration.
- **Orders + OrderItems** — purchase history, filtered to `Status = Paid`.
- **Events** — candidate events, filtered to Active, non-deleted, and starting in the future.
- **Categories** — used both for interest matching and for explanation strings.
- **Venues + Cities** — used for geographic relevance scoring.
- **TicketTypes** — used to compute the sales ratio (popularity proxy).

### 7.3. Retraining Schedule

`RecommendationTrainingService` is registered in `Program.cs` as a hosted background service. It runs an initial training pass on application startup, then sleeps for 24 hours and retrains. Retraining can also be triggered manually by an administrator via `POST /api/recommendations/train`, which is useful immediately after seeding new test data.

### 7.4. Frontend (Flutter Mobile)

The mobile app's `RecommendationProvider` calls `GET /api/recommendations` on the Events screen, both on first load and during pull-to-refresh. The recommendations are rendered in a horizontally scrolling "Recommended for you" section at the top of the screen, with each card showing the event cover image, title, explanation, and venue. Tapping a card navigates the user directly to the event detail screen.

---

## 8. API Contract

### 8.1. GET /api/recommendations

Returns the top recommended events for the currently authenticated user.

**Authentication:** Bearer JWT required.

**Response (200 OK):**

```json
[
  {
    "eventId": 5,
    "title": "Mostar Summer Fest",
    "categoryName": "Music",
    "categoryColorHex": "#7C3AED",
    "coverImageUrl": "https://...",
    "startsAt": "2026-07-15T18:00:00Z",
    "venueName": "Stadion Kantarevac",
    "cityName": "Mostar",
    "score": 0.87,
    "explanation": "Because you like Music"
  }
]
```

### 8.2. POST /api/recommendations/train

Manually triggers a full retraining pass. Restricted to Admin users.

**Authentication:** Bearer JWT with Admin role.

**Response (200 OK):**

```json
{ "message": "Model training initiated" }
```

---

## 9. Limitations and Future Work

The current implementation is a content-based system tailored to the size and growth stage of the Spotter platform. As the user base and event catalog grow, several improvements would be natural next steps:

- **Collaborative filtering** — use co-attendance patterns between users to surface events through other users with similar taste, complementing the content-based signal.
- **Incremental training** — instead of rebuilding the model from scratch every 24 hours, perform smaller incremental updates as new orders arrive.
- **Implicit feedback** — incorporate signals beyond paid orders, such as favorites, screen views, and reservations, weighted by confidence.
- **A/B testing** — measure click-through and conversion rates of recommended events against a baseline to quantify the recommender's impact.
- **Diversity penalty** — currently the top 5 may all belong to the same category. A diversity-aware re-ranker would ensure a broader spread.

---

## 10. Conclusion

The Spotter recommender system delivers personalized event suggestions through a content-based ML.NET pipeline combining TF-IDF text featurization with a FastTree binary classifier, retrained automatically every 24 hours. The cold-start problem is handled through layered fallbacks based on user-declared interests, city, and global popularity. Every recommendation is accompanied by a human-readable explanation, satisfying the explainability requirement defined in the project proposal.

The architecture is intentionally simple and self-contained — no external ML infrastructure is required, the model is trained and held in-memory inside the API process, and recommendations are produced with sub-second latency on a single request. This makes the system practical to deploy and operate as part of the broader Spotter platform without adding operational complexity.
