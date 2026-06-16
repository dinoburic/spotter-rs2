using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class SpotterPoints
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int Delta { get; set; }
        public PointSource Source { get; set; }
        public int? ReferenceId { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
