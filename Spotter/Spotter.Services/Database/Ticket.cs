using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Ticket
    {
        public int Id { get; set; }
        public int OrderItemId { get; set; }
        public OrderItem OrderItem { get; set; } = null!;
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public string QrCodePayload { get; set; } = string.Empty;
        public TicketStatus Status { get; set; }
        public DateTime IssuedAt { get; set; }
        public DateTime? UsedAt { get; set; }
    }
}
