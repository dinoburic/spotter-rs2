using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class ReviewService : IReviewService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly IValidator<ReviewInsertRequest> _insertValidator;
        private readonly IValidator<ReviewUpdateRequest> _updateValidator;
        private readonly INotificationService _notificationService;
        private readonly ISpotterPointsService _spotterPointsService;
        private readonly IBadgeService _badgeService;
        private readonly ILogger<ReviewService> _logger;

        public ReviewService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            IValidator<ReviewInsertRequest> insertValidator,
            IValidator<ReviewUpdateRequest> updateValidator,
            INotificationService notificationService,
            ISpotterPointsService spotterPointsService,
            IBadgeService badgeService,
            ILogger<ReviewService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
            _notificationService = notificationService;
            _spotterPointsService = spotterPointsService;
            _badgeService = badgeService;
            _logger = logger;
        }

        public async Task<PageResult<ReviewResponse>> GetAllAsync(ReviewSearch? search = null)
        {
            var query = _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .Where(r => !r.IsDeleted)
                .AsQueryable();

            if (search != null)
            {
                if (search.EventId.HasValue)
                    query = query.Where(r => r.EventId == search.EventId.Value);

                if (search.UserId.HasValue)
                    query = query.Where(r => r.UserId == search.UserId.Value);

                if (search.MinRating.HasValue)
                    query = query.Where(r => r.Rating >= search.MinRating.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var reviews = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<ReviewResponse>
            {
                Items = reviews.Select(r => _mapper.Map<ReviewResponse>(r)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<ReviewResponse> GetByIdAsync(int id)
        {
            var review = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .Where(r => !r.IsDeleted)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                throw new NotFoundException("Review not found.");

            return _mapper.Map<ReviewResponse>(review);
        }

        public async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
        {
            var userId = _currentUserService.GetUserId();
            _logger.LogInformation("Creating review for event {EventId} by user {UserId}", request.EventId, userId);
            await _insertValidator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);
            if (eventEntity == null)
            {
                _logger.LogWarning("Event {EventId} not found", request.EventId);
                throw new NotFoundException("Event not found.");
            }

            if (eventEntity.EndsAt > DateTime.UtcNow)
                throw new ClientException("You can only review events after they have ended.");

            var hasAttended = await _dbContext.Tickets.AnyAsync(t =>
                t.UserId == userId &&
                t.OrderItem.Order.EventId == request.EventId &&
                t.Status == TicketStatus.Used);

            if (!hasAttended)
                throw new ClientException("You can only review events you have attended (ticket must be used).");

            var alreadyReviewed = await _dbContext.Reviews.AnyAsync(r =>
                r.UserId == userId &&
                r.EventId == request.EventId &&
                !r.IsDeleted);

            if (alreadyReviewed)
                throw new ClientException("You have already reviewed this event.");

            var review = new Review
            {
                UserId = userId,
                EventId = request.EventId,
                Rating = request.Rating,
                Comment = request.Comment,
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                _dbContext.Reviews.Add(review);
                await _dbContext.SaveChangesAsync();

                await _spotterPointsService.EarnAsync(userId, 10, PointSource.Review, review.Id.ToString(), "Review submitted");

                await _notificationService.CreateAsync(
                    userId: userId,
                    title: "Review Submitted",
                    body: $"You earned 10 Spotter Points for reviewing {eventEntity.Title}.",
                    type: NotificationType.General,
                    referenceId: review.Id.ToString()
                );

                await _badgeService.EvaluateAndAwardAsync(userId);

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }

            var createdReview = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .FirstAsync(r => r.Id == review.Id);

            _logger.LogInformation("Review {ReviewId} created successfully", review.Id);
            return _mapper.Map<ReviewResponse>(createdReview);
        }

        public async Task<ReviewResponse> UpdateAsync(int id, ReviewUpdateRequest request)
        {
            _logger.LogInformation("Updating review {ReviewId}", id);
            await _updateValidator.ValidateAndThrowAsync(request);

            var review = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .Where(r => !r.IsDeleted)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
            {
                _logger.LogWarning("Review {ReviewId} not found", id);
                throw new NotFoundException("Review not found.");
            }

            if (review.UserId != _currentUserService.GetUserId() && !_currentUserService.IsAdmin())
                throw new ClientException("You can only edit your own reviews.");

            review.Rating = request.Rating;
            review.Comment = request.Comment;

            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Review {ReviewId} updated successfully", id);
            return _mapper.Map<ReviewResponse>(review);
        }

        public async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting review {ReviewId}", id);
            var review = await _dbContext.Reviews
                .Where(r => !r.IsDeleted)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
            {
                _logger.LogWarning("Review {ReviewId} not found", id);
                throw new NotFoundException("Review not found.");
            }

            if (review.UserId != _currentUserService.GetUserId() && !_currentUserService.IsAdmin())
                throw new ForbiddenException("You can only delete your own reviews.");

            review.IsDeleted = true;
            review.DeletedAt = DateTime.UtcNow;

            var earnedEntry = await _dbContext.SpotterPoints
                .FirstOrDefaultAsync(sp =>
                    sp.UserId == review.UserId &&
                    sp.Source == PointSource.Review &&
                    sp.ReferenceId == review.Id &&
                    sp.Delta > 0);

            if (earnedEntry != null)
            {
                var currentBalance = await _dbContext.SpotterPoints
                    .Where(sp => sp.UserId == review.UserId)
                    .SumAsync(sp => sp.Delta);

                var pointsToDeduct = Math.Min(earnedEntry.Delta, currentBalance);

                if (pointsToDeduct > 0)
                {
                    _dbContext.SpotterPoints.Add(new SpotterPoints
                    {
                        UserId = review.UserId,
                        Delta = -pointsToDeduct,
                        Source = PointSource.Review,
                        ReferenceId = review.Id,
                        Description = $"Points reversed for deleted review",
                        CreatedAt = DateTime.UtcNow
                    });

                    var user = await _dbContext.Users.FindAsync(review.UserId);
                    if (user != null)
                    {
                        user.SpotterPointsBalance -= pointsToDeduct;
                    }

                    _logger.LogInformation("Reversed {Points} points for deleted review {ReviewId}", pointsToDeduct, id);
                }
            }

            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Review {ReviewId} deleted (soft) successfully", id);
        }
    }
}
