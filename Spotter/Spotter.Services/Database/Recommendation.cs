using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Recommendation
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public float Score { get; set; }
        public string Reason { get; set; } = string.Empty;
        public RecommendationSection SectionType { get; set; }
        public DateTime GeneratedAt { get; set; }
    }
}
