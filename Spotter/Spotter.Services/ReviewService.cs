using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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

        public ReviewService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            IValidator<ReviewInsertRequest> insertValidator,
            IValidator<ReviewUpdateRequest> updateValidator,
            INotificationService notificationService)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
            _notificationService = notificationService;
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
            await _insertValidator.ValidateAndThrowAsync(request);

            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == request.EventId && !e.IsDeleted);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (eventEntity.Status != EventStatus.Completed && eventEntity.Status != EventStatus.Active)
                throw new ClientException("Reviews can only be left for active or completed events.");

            var userId = _currentUserService.GetUserId();

            var hasAttended = await _dbContext.Tickets.AnyAsync(t =>
                t.UserId == userId &&
                t.OrderItem.Order.EventId == request.EventId &&
                (t.Status == TicketStatus.Active || t.Status == TicketStatus.Used));

            if (!hasAttended)
                throw new ClientException("You can only review events you have attended.");

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

            _dbContext.Reviews.Add(review);
            await _dbContext.SaveChangesAsync();

            var pointsEntry = new SpotterPoints
            {
                UserId = userId,
                Delta = 10,
                Source = PointSource.Review,
                ReferenceId = review.Id,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SpotterPoints.Add(pointsEntry);

            var user = await _dbContext.Users.FindAsync(userId);
            if (user != null)
            {
                user.SpotterPointsBalance += 10;
            }

            await _dbContext.SaveChangesAsync();

            var createdReview = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .FirstAsync(r => r.Id == review.Id);

            await _notificationService.CreateAsync(
                userId: userId,
                title: "Review Submitted",
                body: $"You earned 10 Spotter Points for reviewing {eventEntity.Title}.",
                type: NotificationType.General,
                referenceId: review.Id.ToString()
            );

            return _mapper.Map<ReviewResponse>(createdReview);
        }

        public async Task<ReviewResponse> UpdateAsync(int id, ReviewUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var review = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .Where(r => !r.IsDeleted)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                throw new NotFoundException("Review not found.");

            if (review.UserId != _currentUserService.GetUserId() && !_currentUserService.IsAdmin())
                throw new ClientException("You can only edit your own reviews.");

            review.Rating = request.Rating;
            review.Comment = request.Comment;

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<ReviewResponse>(review);
        }

        public async Task DeleteAsync(int id)
        {
            var review = await _dbContext.Reviews
                .Where(r => !r.IsDeleted)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                throw new NotFoundException("Review not found.");

            if (review.UserId != _currentUserService.GetUserId() && !_currentUserService.IsAdmin())
                throw new ClientException("You can only delete your own reviews.");

            review.IsDeleted = true;
            review.DeletedAt = DateTime.UtcNow;

            var pointsEntry = new SpotterPoints
            {
                UserId = review.UserId,
                Delta = -10,
                Source = PointSource.Review,
                ReferenceId = review.Id,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SpotterPoints.Add(pointsEntry);

            var user = await _dbContext.Users.FindAsync(review.UserId);
            if (user != null)
            {
                user.SpotterPointsBalance = Math.Max(0, user.SpotterPointsBalance - 10);
            }

            await _dbContext.SaveChangesAsync();
        }
    }
}
