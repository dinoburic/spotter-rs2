namespace Spotter.Model.Requests
{
    public class TicketTypeUpdateRequest
    {
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int TotalQuantity { get; set; }
    }
}
