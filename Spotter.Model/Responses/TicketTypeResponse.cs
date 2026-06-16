using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class TicketTypeResponse
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int TotalQuantity { get; set; }
        public int SoldQuantity { get; set; }
        public int AvailableQuantity { get; set; }
        public TicketTypeEnum TypeEnum { get; set; }
        public string TypeName { get; set; } = string.Empty;
    }
}
