using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/notifications")]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<NotificationResponse>>> GetMyNotifications([FromQuery] NotificationSearch? search)
        {
            var result = await _notificationService.GetMyNotificationsAsync(search);
            return Ok(result);
        }

        [HttpGet("unread-count")]
        public async Task<ActionResult<UnreadCountResponse>> GetUnreadCount()
        {
            var count = await _notificationService.GetUnreadCountAsync();
            return Ok(new UnreadCountResponse { Count = count });
        }

        [HttpPost("{id}/read")]
        public async Task<ActionResult<NotificationResponse>> MarkAsRead(int id)
        {
            var result = await _notificationService.MarkAsReadAsync(id);
            return Ok(result);
        }

        [HttpPost("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            await _notificationService.MarkAllAsReadAsync();
            return NoContent();
        }
    }
}
