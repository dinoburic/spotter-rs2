using MapsterMapper;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using Spotter.Services.Hubs;

namespace Spotter.Services
{
    public class NotificationService : INotificationService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            IHubContext<NotificationHub> hubContext,
            ILogger<NotificationService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task<PageResult<NotificationResponse>> GetMyNotificationsAsync(NotificationSearch? search = null)
        {
            var userId = _currentUserService.GetUserId();

            var query = _dbContext.Notifications
                .Where(n => n.UserId == userId)
                .AsQueryable();

            if (search != null)
            {
                if (search.IsRead.HasValue)
                    query = query.Where(n => n.IsRead == search.IsRead.Value);

                if (search.Type.HasValue)
                    query = query.Where(n => n.Type == search.Type.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var notifications = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<NotificationResponse>
            {
                Items = notifications.Select(n => _mapper.Map<NotificationResponse>(n)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<NotificationResponse> MarkAsReadAsync(int id)
        {
            var userId = _currentUserService.GetUserId();

            var notification = await _dbContext.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (notification == null)
                throw new NotFoundException("Notification not found.");

            notification.IsRead = true;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<NotificationResponse>(notification);
        }

        public async Task MarkAllAsReadAsync()
        {
            var userId = _currentUserService.GetUserId();

            var unreadNotifications = await _dbContext.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            await _dbContext.SaveChangesAsync();
        }

        public async Task<NotificationResponse> CreateAsync(int userId, string title, string body, NotificationType type, string? referenceId = null)
        {
            _logger.LogInformation("Creating notification for user {UserId}: {Title}", userId, title);
            int? refId = null;
            if (!string.IsNullOrEmpty(referenceId) && int.TryParse(referenceId, out var parsedRefId))
            {
                refId = parsedRefId;
            }

            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Body = body,
                IsRead = false,
                Type = type,
                ReferenceId = refId,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Notifications.Add(notification);
            await _dbContext.SaveChangesAsync();

            var response = _mapper.Map<NotificationResponse>(notification);

            await _hubContext.Clients
                .Group(userId.ToString())
                .SendAsync("ReceiveNotification", response);

            _logger.LogInformation("Notification {NotificationId} created and sent to user {UserId}", notification.Id, userId);
            return response;
        }

        public async Task<int> GetUnreadCountAsync()
        {
            var userId = _currentUserService.GetUserId();
            return await _dbContext.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead);
        }
    }
}
