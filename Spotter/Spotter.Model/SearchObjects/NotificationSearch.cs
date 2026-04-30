using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class NotificationSearch : BaseSearchObject
    {
        public bool? IsRead { get; set; }
        public NotificationType? Type { get; set; }
    }
}
