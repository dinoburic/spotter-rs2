using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface INotificationService
    {
        Task<PageResult<NotificationResponse>> GetMyNotificationsAsync(NotificationSearch? search = null);
        Task<NotificationResponse> MarkAsReadAsync(int id);
        Task MarkAllAsReadAsync();
        Task<NotificationResponse> CreateAsync(int userId, string title, string body, NotificationType type, string? referenceId = null);
        Task<int> GetUnreadCountAsync();
    }
}
