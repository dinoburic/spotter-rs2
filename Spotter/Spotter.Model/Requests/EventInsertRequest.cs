namespace Spotter.Model.Requests
{
    public class EventInsertRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public int VenueId { get; set; }
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
        public int TotalCapacity { get; set; }
        public string? CoverImageUrl { get; set; }
    }
}
