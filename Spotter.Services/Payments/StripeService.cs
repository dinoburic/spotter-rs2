using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Services.Database;
using Stripe;

namespace Spotter.Services
{
    public class StripeService : IStripeService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IOrderService _orderService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeService> _logger;
        private readonly string _webhookSecret;

        public StripeService(
            SpotterDbContext dbContext,
            IOrderService orderService,
            ICurrentUserService currentUserService,
            IConfiguration configuration,
            ILogger<StripeService> logger)
        {
            _dbContext = dbContext;
            _orderService = orderService;
            _currentUserService = currentUserService;
            _configuration = configuration;
            _logger = logger;

            StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY")
                ?? configuration["Stripe:SecretKey"]
                ?? throw new InvalidOperationException("Stripe secret key not configured.");

            _webhookSecret = Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET")
                ?? configuration["Stripe:WebhookSecret"]
                ?? string.Empty;

            _logger.LogInformation("Stripe webhook secret configured: {HasSecret}", !string.IsNullOrEmpty(_webhookSecret));
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(int orderId)
        {
            _logger.LogInformation("Creating payment intent for order {OrderId}", orderId);

            var order = await _dbContext.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
            if (order == null)
            {
                _logger.LogWarning("Order {OrderId} not found", orderId);
                throw new NotFoundException("Order not found.");
            }

            var currentUserId = _currentUserService.GetUserId();
            if (order.UserId != currentUserId)
            {
                _logger.LogWarning("User {UserId} attempted to create payment intent for order {OrderId} owned by {OwnerId}", currentUserId, orderId, order.UserId);
                throw new ClientException("You can only pay for your own orders.");
            }

            if (order.Status != OrderStatus.Pending)
            {
                throw new ClientException("This order cannot be paid.");
            }

            var paymentIntentService = new PaymentIntentService();

            if (!string.IsNullOrEmpty(order.StripePaymentIntentId))
            {
                try
                {
                    var existing = await paymentIntentService.GetAsync(order.StripePaymentIntentId);
                    if (existing.Status == "requires_payment_method" || existing.Status == "requires_confirmation")
                    {
                        _logger.LogInformation("Reusing existing payment intent {PaymentIntentId} for order {OrderId}", existing.Id, orderId);
                        return new PaymentIntentResponse
                        {
                            ClientSecret = existing.ClientSecret,
                            PaymentIntentId = existing.Id
                        };
                    }
                    if (existing.Status != "succeeded" && existing.Status != "canceled")
                    {
                        await paymentIntentService.CancelAsync(order.StripePaymentIntentId);
                        _logger.LogInformation("Cancelled stale payment intent {PaymentIntentId} for order {OrderId}", order.StripePaymentIntentId, orderId);
                    }
                }
                catch (StripeException ex)
                {
                    _logger.LogWarning(ex, "Failed to retrieve existing payment intent {PaymentIntentId}, creating new one", order.StripePaymentIntentId);
                }
            }

            var amountInCents = (long)(order.TotalAmount * 100);

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = "bam",
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                },
                Metadata = new Dictionary<string, string>
                {
                    { "orderId", orderId.ToString() }
                }
            };

            var intent = await paymentIntentService.CreateAsync(options);

            order.StripePaymentIntentId = intent.Id;
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation("Payment intent {PaymentIntentId} created for order {OrderId}", intent.Id, orderId);

            return new PaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            };
        }

        public async Task HandleWebhookAsync(string payload, string stripeSignature)
{
    _logger.LogInformation("Processing Stripe webhook");

    Stripe.Event stripeEvent;
    try
    {
        stripeEvent = EventUtility.ConstructEvent(
            payload,
            stripeSignature,
            _webhookSecret,
            throwOnApiVersionMismatch: false
        );
    }
    catch (StripeException ex)
    {
        _logger.LogError(ex, "Failed to construct Stripe event");
        throw;
    }

    var alreadyProcessed = await _dbContext.ProcessedStripeEvents
        .AnyAsync(e => e.StripeEventId == stripeEvent.Id);
    if (alreadyProcessed)
    {
        _logger.LogInformation("Stripe event {EventId} already processed, skipping", stripeEvent.Id);
        return;
    }

    if (stripeEvent.Type == EventTypes.PaymentIntentSucceeded)
    {
        var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
        if (paymentIntent?.Metadata.TryGetValue("orderId", out var orderIdStr) == true &&
            int.TryParse(orderIdStr, out var orderId))
        {
            var order = await _dbContext.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
            if (order != null)
            {
                if (order.StripePaymentIntentId != paymentIntent.Id)
                {
                    _logger.LogWarning("PaymentIntent {PaymentIntentId} does not match order {OrderId} current intent {CurrentIntentId}",
                        paymentIntent.Id, orderId, order.StripePaymentIntentId);
                }
                else
                {
                    var expectedAmount = (long)(order.TotalAmount * 100);
                    if (paymentIntent.Amount != expectedAmount || paymentIntent.Currency != "bam")
                    {
                        _logger.LogWarning("PaymentIntent {PaymentIntentId} amount/currency mismatch. Expected {Expected} bam, got {Actual} {Currency}",
                            paymentIntent.Id, expectedAmount, paymentIntent.Amount, paymentIntent.Currency);
                    }
                    else if (order.Status == OrderStatus.Pending)
                    {
                        await _orderService.MarkAsPaidAsync(orderId);
                        _logger.LogInformation("Order {OrderId} marked as paid via Stripe webhook", orderId);
                    }
                }
            }
        }
    }
    else if (stripeEvent.Type == EventTypes.PaymentIntentPaymentFailed ||
             stripeEvent.Type == "payment_intent.canceled")
    {
        var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
        if (paymentIntent?.Metadata.TryGetValue("orderId", out var orderIdStr) == true &&
            int.TryParse(orderIdStr, out var orderId))
        {
            var order = await _dbContext.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
            if (order != null && order.StripePaymentIntentId == paymentIntent.Id && order.Status == OrderStatus.Pending)
            {
                await _orderService.CancelBySystemAsync(orderId);
                _logger.LogInformation("Order {OrderId} cancelled via webhook", orderId);
            }
        }
    }

    _dbContext.ProcessedStripeEvents.Add(new Database.ProcessedStripeEvent
    {
        StripeEventId = stripeEvent.Id,
        ProcessedAt = DateTime.UtcNow
    });
    await _dbContext.SaveChangesAsync();
}

        public async Task RefundPaymentAsync(string paymentIntentId)
        {
            _logger.LogInformation("Creating Stripe refund for PaymentIntent {PaymentIntentId}", paymentIntentId);

            var refundService = new RefundService();
            var refundOptions = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId
            };

            await refundService.CreateAsync(refundOptions);
            _logger.LogInformation("Stripe refund created for PaymentIntent {PaymentIntentId}", paymentIntentId);
        }
    }
}
