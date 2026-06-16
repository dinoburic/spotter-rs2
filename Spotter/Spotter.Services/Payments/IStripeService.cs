using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface IStripeService
    {
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(int orderId);
        Task HandleWebhookAsync(string payload, string stripeSignature);
        Task RefundPaymentAsync(string paymentIntentId);
    }
}
