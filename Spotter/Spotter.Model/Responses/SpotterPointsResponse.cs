using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class SpotterPointsResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int Delta { get; set; }
        public PointSource Source { get; set; }
        public string SourceName { get; set; } = string.Empty;
        public string? ReferenceId { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
