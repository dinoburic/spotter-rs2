using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Order
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int EventId { get; set; }
        public Event Event { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public OrderStatus Status { get; set; }
        public decimal TotalAmount { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public string? StripeCheckoutSessionId { get; set; }
        public int SpotterPointsRedeemed { get; set; }
        public decimal DiscountApplied { get; set; }
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
