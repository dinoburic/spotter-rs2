using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Services.Database;
using Spotter.Services.ML;

namespace Spotter.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly ILogger<RecommendationService> _logger;
        private static readonly MLContext _mlContext = new MLContext(seed: 42);
        private static ITransformer? _model;
        private static DateTime _lastTrainingTime = DateTime.MinValue;
        private static readonly SemaphoreSlim _trainingSemaphore = new SemaphoreSlim(1, 1);

        public RecommendationService(SpotterDbContext dbContext, ILogger<RecommendationService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task TrainModelAsync()
        {
            await _trainingSemaphore.WaitAsync();
            try
            {
                _logger.LogInformation("Starting ML.NET model training");

                var trainingData = await BuildTrainingDataAsync();

                _logger.LogInformation("Built {Count} training samples", trainingData.Count);

                if (trainingData.Count < 5)
                {
                    _logger.LogWarning("Not enough training data ({Count} samples), skipping training", trainingData.Count);
                    return;
                }

                var dataView = _mlContext.Data.LoadFromEnumerable(trainingData);

                var pipeline = _mlContext.Transforms.Text.FeaturizeText(
                        outputColumnName: "FeaturesVector",
                        inputColumnName: nameof(EventFeatures.Features))
                    .Append(_mlContext.BinaryClassification.Trainers.FastTree(
                        labelColumnName: nameof(EventFeatures.Label),
                        featureColumnName: "FeaturesVector",
                        numberOfTrees: 50,
                        numberOfLeaves: 20,
                        minimumExampleCountPerLeaf: 1));

                _model = pipeline.Fit(dataView);
                _lastTrainingTime = DateTime.UtcNow;

                _logger.LogInformation("ML.NET model trained successfully with {Count} samples", trainingData.Count);
            }
            finally
            {
                _trainingSemaphore.Release();
            }
        }

        public async Task<List<RecommendationResponse>> GetRecommendationsAsync(int userId)
        {
            _logger.LogInformation("Getting recommendations for user {UserId}", userId);

            if (_model == null)
            {
                await TrainModelAsync();
            }

            var user = await _dbContext.Users
                .Include(u => u.UserInterests).ThenInclude(ui => ui.Category)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                _logger.LogWarning("User {UserId} not found", userId);
                return new List<RecommendationResponse>();
            }

            _logger.LogInformation("User {UserId} has {InterestCount} interests, CityId={CityId}",
                userId, user.UserInterests?.Count ?? 0, user.CityId);

            var attendedEventIds = await _dbContext.Orders
                .Where(o => o.UserId == userId && o.Status == OrderStatus.Paid)
                .Select(o => o.EventId)
                .Distinct()
                .ToListAsync();

            _logger.LogInformation("User {UserId} has {AttendedCount} attended events", userId, attendedEventIds.Count);

            var allEventsDebug = await _dbContext.Events
                .Where(e => !e.IsDeleted)
                .Select(e => new { e.Id, e.Title, e.Status, e.StartsAt })
                .Take(10)
                .ToListAsync();

            _logger.LogInformation("Debug: Found {Count} non-deleted events. Sample: {Events}",
                allEventsDebug.Count,
                string.Join(", ", allEventsDebug.Select(e => $"[{e.Id}:{e.Status}:{e.StartsAt:yyyy-MM-dd HH:mm}]")));

            _logger.LogInformation("Debug: Current UTC time is {UtcNow}, local time is {LocalNow}",
                DateTime.UtcNow, DateTime.Now);

            var activeEvents = await _dbContext.Events
                .Include(e => e.Category)
                .Include(e => e.Venue).ThenInclude(v => v.City)
                .Include(e => e.TicketTypes)
                .Where(e => e.Status == EventStatus.Active &&
                            !e.IsDeleted &&
                            !attendedEventIds.Contains(e.Id))
                .ToListAsync();

            _logger.LogInformation("Found {EventCount} active events to score", activeEvents.Count);

            if (!activeEvents.Any())
            {
                _logger.LogWarning("No active events found for recommendations");
                return new List<RecommendationResponse>();
            }

            var userInterests = user.UserInterests?.ToList() ?? new List<UserInterest>();

            if (!attendedEventIds.Any() && !userInterests.Any())
            {
                _logger.LogInformation("Cold start: no history or interests for user {UserId}", userId);
                return GetPopularityBasedRecommendations(activeEvents, user);
            }

            if (_model != null)
            {
                var results = GetMLBasedRecommendations(user, activeEvents, attendedEventIds, userInterests);
                _logger.LogInformation("Generated {Count} ML-based recommendations", results.Count);
                return results;
            }

            var interestResults = GetInterestBasedRecommendations(user, activeEvents, attendedEventIds, userInterests);
            _logger.LogInformation("Generated {Count} interest-based recommendations", interestResults.Count);
            return interestResults;
        }

        private List<RecommendationResponse> GetMLBasedRecommendations(
            User user,
            List<Event> activeEvents,
            List<int> attendedEventIds,
            List<UserInterest> userInterests)
        {
            var predictionEngine = _mlContext.Model.CreatePredictionEngine<EventFeatures, EventPrediction>(_model!);

            var userProfile = BuildUserProfile(user, attendedEventIds);
            var results = new List<RecommendationResponse>();

            foreach (var evt in activeEvents)
            {
                var features = BuildEventFeatures(evt, userProfile);
                var prediction = predictionEngine.Predict(features);

                results.Add(new RecommendationResponse
                {
                    EventId = evt.Id,
                    Title = evt.Title,
                    CategoryName = evt.Category?.Name ?? string.Empty,
                    CategoryColorHex = evt.Category?.ColorHex ?? string.Empty,
                    CoverImageUrl = evt.CoverImageUrl,
                    StartsAt = evt.StartsAt,
                    VenueName = evt.Venue?.Name ?? string.Empty,
                    CityName = evt.Venue?.City?.Name ?? string.Empty,
                    Score = prediction.Probability,
                    Explanation = GenerateExplanation(user, evt, attendedEventIds, userInterests)
                });
            }

            return results.OrderByDescending(r => r.Score).Take(5).ToList();
        }

        private List<RecommendationResponse> GetInterestBasedRecommendations(
            User user,
            List<Event> activeEvents,
            List<int> attendedEventIds,
            List<UserInterest> userInterests)
        {
            var interestCategoryIds = userInterests.Select(ui => ui.CategoryId).ToHashSet();

            var results = activeEvents.Select(evt =>
            {
                float score = 0.1f;

                if (interestCategoryIds.Contains(evt.CategoryId))
                    score += 0.6f;

                if (evt.Venue?.City?.Id == user.CityId)
                    score += 0.2f;

                var soldRatio = evt.TotalCapacity > 0
                    ? (float)(evt.TicketTypes?.Sum(tt => tt.SoldQuantity) ?? 0) / evt.TotalCapacity
                    : 0;
                score += soldRatio * 0.1f;

                return new RecommendationResponse
                {
                    EventId = evt.Id,
                    Title = evt.Title,
                    CategoryName = evt.Category?.Name ?? string.Empty,
                    CategoryColorHex = evt.Category?.ColorHex ?? string.Empty,
                    CoverImageUrl = evt.CoverImageUrl,
                    StartsAt = evt.StartsAt,
                    VenueName = evt.Venue?.Name ?? string.Empty,
                    CityName = evt.Venue?.City?.Name ?? string.Empty,
                    Score = score,
                    Explanation = GenerateExplanation(user, evt, attendedEventIds, userInterests)
                };
            });

            return results.OrderByDescending(r => r.Score).Take(5).ToList();
        }

        private List<RecommendationResponse> GetPopularityBasedRecommendations(List<Event> activeEvents, User user)
        {
            var results = activeEvents.Select(evt =>
            {
                float score = 0.1f;

                if (evt.Venue?.City?.Id == user.CityId)
                    score += 0.4f;

                var soldRatio = evt.TotalCapacity > 0
                    ? (float)(evt.TicketTypes?.Sum(tt => tt.SoldQuantity) ?? 0) / evt.TotalCapacity
                    : 0;
                score += soldRatio * 0.5f;

                return new RecommendationResponse
                {
                    EventId = evt.Id,
                    Title = evt.Title,
                    CategoryName = evt.Category?.Name ?? string.Empty,
                    CategoryColorHex = evt.Category?.ColorHex ?? string.Empty,
                    CoverImageUrl = evt.CoverImageUrl,
                    StartsAt = evt.StartsAt,
                    VenueName = evt.Venue?.Name ?? string.Empty,
                    CityName = evt.Venue?.City?.Name ?? string.Empty,
                    Score = score,
                    Explanation = "Popular in your area"
                };
            });

            return results.OrderByDescending(r => r.Score).Take(5).ToList();
        }

        private async Task<List<EventFeatures>> BuildTrainingDataAsync()
        {
            var trainingData = new List<EventFeatures>();

            var paidOrders = await _dbContext.Orders
                .Include(o => o.Event).ThenInclude(e => e!.Category)
                .Include(o => o.User).ThenInclude(u => u!.UserInterests).ThenInclude(ui => ui.Category)
                .Where(o => o.Status == OrderStatus.Paid && o.Event != null && o.User != null)
                .ToListAsync();

            _logger.LogInformation("Found {Count} paid orders for training", paidOrders.Count);

            foreach (var order in paidOrders)
            {
                if (order.Event == null || order.User == null) continue;

                var userProfile = BuildUserProfile(order.User, new List<int>());
                var eventFeatures = BuildEventFeatures(order.Event, userProfile);
                eventFeatures.Label = true;
                trainingData.Add(eventFeatures);
            }

            var allEvents = await _dbContext.Events
                .Include(e => e.Category)
                .Where(e => !e.IsDeleted)
                .Take(100)
                .ToListAsync();

            _logger.LogInformation("Found {Count} events for negative samples", allEvents.Count);

            var random = new Random(42);
            var negativeCount = Math.Max(trainingData.Count, 10);

            foreach (var evt in allEvents.Take(negativeCount))
            {
                var fakeProfile = $"category{random.Next(1, 7)} interest{random.Next(1, 7)}";
                trainingData.Add(new EventFeatures
                {
                    Label = false,
                    Features = $"{fakeProfile} {evt.Category?.Name ?? string.Empty} {evt.Title}"
                });
            }

            return trainingData;
        }

        private string BuildUserProfile(User? user, List<int> attendedEventIds)
        {
            if (user == null) return string.Empty;

            var parts = new List<string>();

            if (user.UserInterests != null)
            {
                foreach (var interest in user.UserInterests)
                {
                    if (interest.Category?.Name != null)
                        parts.Add(interest.Category.Name);
                }
            }

            return string.Join(" ", parts.Where(p => !string.IsNullOrEmpty(p)));
        }

        private EventFeatures BuildEventFeatures(Event evt, string userProfile)
        {
            var features = new List<string>
            {
                userProfile,
                evt.Category?.Name ?? string.Empty,
                evt.Title ?? string.Empty,
                evt.Description ?? string.Empty
            };

            return new EventFeatures
            {
                Label = false,
                Features = string.Join(" ", features.Where(f => !string.IsNullOrEmpty(f)))
            };
        }

        private string GenerateExplanation(User user, Event evt, List<int> attendedEventIds, List<UserInterest> userInterests)
        {
            if (userInterests.Any(ui => ui.CategoryId == evt.CategoryId))
                return $"Because you like {evt.Category?.Name}";

            if (attendedEventIds.Any())
                return "Because you attended similar events";

            if (evt.Venue?.City?.Id == user.CityId)
                return "Popular event in your city";

            return "Recommended for you";
        }
    }
}
