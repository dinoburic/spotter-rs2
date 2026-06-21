using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public int TicketTypeId { get; set; }
        public string TicketTypeName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public ReservationStatus Status { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public int? ApprovedByUserId { get; set; }
        public string? ApprovedByName { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public string? AuditNote { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
    }
}
