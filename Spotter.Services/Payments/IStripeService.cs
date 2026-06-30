using Spotter.Model.Responses;

namespace Spotter.Services
{
    public enum WebhookAction
    {
        None,
        MarkAsPaid,
        CancelOrder
    }

    public class WebhookResult
    {
        public WebhookAction Action { get; set; }
        public int? OrderId { get; set; }
    }

    public interface IStripeService
    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(int orderId);
        Task<WebhookResult> HandleWebhookAsync(string payload, string stripeSignature);
        Task RefundPaymentAsync(string paymentIntentId);
    }
}
