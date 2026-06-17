using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Notification
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public NotificationType Type { get; set; }
        public int? ReferenceId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
