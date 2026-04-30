namespace Spotter.Model.Responses
{
    public class OrderItemResponse
    {
        public int Id { get; set; }
        public int TicketTypeId { get; set; }
        public string TicketTypeName { get; set; } = string.Empty;
        public string TypeName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Subtotal { get; set; }
    }
}
