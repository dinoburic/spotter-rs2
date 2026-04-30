using Spotter.Model.Enums;

namespace Spotter.Model.Requests
{
    public class TicketTypeInsertRequest
    {
        public int EventId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int TotalQuantity { get; set; }
        public TicketTypeEnum TypeEnum { get; set; }
    }
}
