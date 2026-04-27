namespace Spotter.Services.Database
{
    public class WaitlistEntry
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public int TicketTypeId { get; set; }
        public TicketType TicketType { get; set; } = null!;
        public DateTime JoinedAt { get; set; }
        public int Position { get; set; }
        public bool Notified { get; set; }
        public DateTime? NotifiedAt { get; set; }
    }
}
