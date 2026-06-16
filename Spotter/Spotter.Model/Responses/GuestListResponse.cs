namespace Spotter.Model.Responses
{
    public class GuestListResponse
    {
        public int TotalGuests { get; set; }
        public List<GuestItem> Guests { get; set; } = new();
    }

    public class GuestItem
    {
        public int TicketId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public string EventTitle { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public string TicketTypeName { get; set; } = string.Empty;
        public DateTime IssuedAt { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
