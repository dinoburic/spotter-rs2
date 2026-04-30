using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class TicketSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? EventId { get; set; }
        public TicketStatus? Status { get; set; }
    }
}
