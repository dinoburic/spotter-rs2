using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Reservation
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public int TicketTypeId { get; set; }
        public TicketType TicketType { get; set; } = null!;
        public int Quantity { get; set; } = 1;
        public int? OrderId { get; set; }
        public Order? Order { get; set; }
        public ReservationStatus Status { get; set; }
        public int? ApprovedByUserId { get; set; }
        public User? ApprovedBy { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public string? AuditNote { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
    }
}
