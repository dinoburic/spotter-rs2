using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class TicketResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public DateTime? EventStartsAt { get; set; }
        public string VenueName { get; set; } = string.Empty;
        public string CityName { get; set; } = string.Empty;
        public string TicketTypeName { get; set; } = string.Empty;
        public string TypeName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string QrCodePayload { get; set; } = string.Empty;
        public TicketStatus Status { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public DateTime IssuedAt { get; set; }
        public DateTime? UsedAt { get; set; }
    }
}
