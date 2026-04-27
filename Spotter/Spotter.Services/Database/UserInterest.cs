namespace Spotter.Services.Database
{
    public class UserInterest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int CategoryId { get; set; }
        public Category Category { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }
}
