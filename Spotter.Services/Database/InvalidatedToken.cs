namespace Spotter.Services.Database
{
    public class InvalidatedToken
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public string TokenJti { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateTime InvalidatedAt { get; set; }
    }
}
