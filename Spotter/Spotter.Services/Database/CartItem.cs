namespace Spotter.Services.Database
{
    public class CartItem
    {
        public int Id { get; set; }
        public int Quantity { get; set; } = 1;
        public DateTime AddedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public int CartId { get; set; }
        public Cart Cart { get; set; } = null!;
    }
}
