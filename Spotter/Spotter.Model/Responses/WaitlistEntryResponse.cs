namespace Spotter.Model.Responses
{
    public class WaitlistEntryResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public int TicketTypeId { get; set; }
        public string TicketTypeName { get; set; } = string.Empty;
        public int Position { get; set; }
        public DateTime JoinedAt { get; set; }
        public bool Notified { get; set; }
        public DateTime? NotifiedAt { get; set; }
    }
}
