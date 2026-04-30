using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class OrderSearch : BaseSearchObject
    {
        public int? EventId { get; set; }
        public int? UserId { get; set; }
        public OrderStatus? Status { get; set; }
    }
}
