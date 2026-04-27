namespace Spotter.Services.Database
{
    public class EventTag
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public string Tag { get; set; } = string.Empty;
    }
}
