namespace Spotter.Model.Responses
{
    public class FavoriteResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int EventId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public string? EventCoverImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
