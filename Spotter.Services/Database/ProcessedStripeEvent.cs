namespace Spotter.Services.Database
{
    public class ProcessedStripeEvent
    {
        public int Id { get; set; }
        public string StripeEventId { get; set; } = string.Empty;
        public DateTime ProcessedAt { get; set; }
    }
}
