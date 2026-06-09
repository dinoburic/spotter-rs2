namespace Spotter.Model.Responses
{
    public class FavoriteResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public string? EventCoverImageUrl { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryColorHex { get; set; } = string.Empty;
        public string VenueName { get; set; } = string.Empty;
        public string? CityName { get; set; }
        public DateTime EventStartsAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
