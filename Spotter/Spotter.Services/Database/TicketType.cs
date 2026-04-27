using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class TicketType
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int TotalQuantity { get; set; }
        public int SoldQuantity { get; set; }
        public TicketTypeEnum TypeEnum { get; set; }
    }
}
