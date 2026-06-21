namespace Spotter.Model.Requests
{
    public class ReservationInsertRequest
    {
        public int EventId { get; set; }
        public int TicketTypeId { get; set; }
        public int Quantity { get; set; } = 1;
        public string? Note { get; set; }
    }
}
