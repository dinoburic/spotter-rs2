namespace Spotter.Model.Requests
{
    public class OrderInsertRequest
    {
        public int EventId { get; set; }
        public List<OrderItemRequest> Items { get; set; } = new List<OrderItemRequest>();
        public int SpotterPointsToRedeem { get; set; }
    }
}
