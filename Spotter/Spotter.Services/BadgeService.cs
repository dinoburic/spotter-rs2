using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class BadgeService : IBadgeService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationService _notificationService;

        public BadgeService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            INotificationService notificationService)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _notificationService = notificationService;
        }

        public async Task<List<BadgeResponse>> GetAllBadgesAsync()
        {
            var badges = await _dbContext.Badges.ToListAsync();
            return badges.Select(b => _mapper.Map<BadgeResponse>(b)).ToList();
        }

        public async Task<List<UserBadgeResponse>> GetUserBadgesAsync(int? userId = null)
        {
            var targetUserId = userId ?? _currentUserService.GetUserId();

            var userBadges = await _dbContext.UserBadges
                .Include(ub => ub.Badge)
                .Where(ub => ub.UserId == targetUserId)
                .ToListAsync();

            return userBadges.Select(ub => _mapper.Map<UserBadgeResponse>(ub)).ToList();
        }

        public async Task EvaluateAndAwardAsync(int userId)
        {
            var earnedBadgeIds = await _dbContext.UserBadges
                .Where(ub => ub.UserId == userId)
                .Select(ub => ub.BadgeId)
                .ToListAsync();

            await CheckFirstPurchaseAsync(userId, earnedBadgeIds);
            await CheckTenReviewsAsync(userId, earnedBadgeIds);
            await CheckNightOwlAsync(userId, earnedBadgeIds);
            await CheckFoodieAsync(userId, earnedBadgeIds);
            await CheckEarlyBirdAsync(userId, earnedBadgeIds);
            await CheckMusicLoverAsync(userId, earnedBadgeIds);
        }

        private async Task CheckFirstPurchaseAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.FirstPurchase);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var hasPurchase = await _dbContext.Orders.AnyAsync(o => o.UserId == userId && o.Status == OrderStatus.Paid);
            if (hasPurchase)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task CheckTenReviewsAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.TenReviews);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var reviewCount = await _dbContext.Reviews.CountAsync(r => r.UserId == userId && !r.IsDeleted);
            if (reviewCount >= 10)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task CheckNightOwlAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.NightOwl);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var nightEventCount = await _dbContext.Tickets
                .Where(t => t.UserId == userId && t.Status == TicketStatus.Used)
                .Where(t => t.OrderItem.Order.Event.StartsAt.Hour >= 21)
                .CountAsync();

            if (nightEventCount >= 3)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task CheckFoodieAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.Foodie);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var foodCategoryId = await _dbContext.Categories
                .Where(c => c.Name == "Food")
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            if (foodCategoryId == 0)
                return;

            var foodEventCount = await _dbContext.Tickets
                .Where(t => t.UserId == userId && t.Status == TicketStatus.Used)
                .Where(t => t.OrderItem.Order.Event.CategoryId == foodCategoryId)
                .CountAsync();

            if (foodEventCount >= 2)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task CheckEarlyBirdAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.EarlyBird);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var earlyPurchaseCount = await _dbContext.Orders
                .Where(o => o.UserId == userId && o.Status == OrderStatus.Paid)
                .Where(o => EF.Functions.DateDiffHour(o.Event.CreatedAt, o.CreatedAt) <= 24)
                .CountAsync();

            if (earlyPurchaseCount >= 2)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task CheckMusicLoverAsync(int userId, List<int> earnedBadgeIds)
        {
            var badge = await _dbContext.Badges.FirstOrDefaultAsync(b => b.Criteria == BadgeCriteria.MusicLover);
            if (badge == null || earnedBadgeIds.Contains(badge.Id))
                return;

            var musicCategoryId = await _dbContext.Categories
                .Where(c => c.Name == "Music")
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            if (musicCategoryId == 0)
                return;

            var musicEventCount = await _dbContext.Tickets
                .Where(t => t.UserId == userId && t.Status == TicketStatus.Used)
                .Where(t => t.OrderItem.Order.Event.CategoryId == musicCategoryId)
                .CountAsync();

            if (musicEventCount >= 3)
            {
                await AwardBadgeAsync(userId, badge);
            }
        }

        private async Task AwardBadgeAsync(int userId, Badge badge)
        {
            _dbContext.UserBadges.Add(new UserBadge
            {
                UserId = userId,
                BadgeId = badge.Id,
                EarnedAt = DateTime.UtcNow
            });
            await _dbContext.SaveChangesAsync();

            await _notificationService.CreateAsync(
                userId,
                "New Badge Earned!",
                $"You earned the '{badge.Name}' badge.",
                NotificationType.NewBadge,
                badge.Id.ToString()
            );
        }
    }
}
