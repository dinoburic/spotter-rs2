using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class ReservationSearch : BaseSearchObject
    {
        public int? EventId { get; set; }
        public int? UserId { get; set; }
        public ReservationStatus? Status { get; set; }
    }
}
