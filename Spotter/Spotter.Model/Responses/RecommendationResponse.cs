namespace Spotter.Model.Responses
{
    public class RecommendationResponse
    {
        public int EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryColorHex { get; set; } = string.Empty;
        public string? CoverImageUrl { get; set; }
        public DateTime StartsAt { get; set; }
        public string VenueName { get; set; } = string.Empty;
        public string CityName { get; set; } = string.Empty;
        public float Score { get; set; }
        public string Explanation { get; set; } = string.Empty;
    }
}
