using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Services;
using Stripe;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/payments")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IStripeService _stripeService;
        private readonly IOrderService _orderService;
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(
            IStripeService stripeService,
            IOrderService orderService,
            ILogger<PaymentController> logger)
        {
            _stripeService = stripeService;
            _orderService = orderService;
            _logger = logger;
        }

        [HttpPost("create-intent")]
        public async Task<ActionResult<PaymentIntentResponse>> CreateIntent([FromBody] CreatePaymentIntentRequest request)
        {
            var result = await _stripeService.CreatePaymentIntentAsync(request.OrderId);
            return Ok(result);
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            var payload = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
            var stripeSignature = Request.Headers["Stripe-Signature"];

            try
            {
                var result = await _stripeService.HandleWebhookAsync(payload, stripeSignature!);

                if (result.OrderId.HasValue)
                {
                    switch (result.Action)
                    {
                        case WebhookAction.MarkAsPaid:
                            await _orderService.MarkAsPaidAsync(result.OrderId.Value);
                            _logger.LogInformation("Order {OrderId} marked as paid via webhook", result.OrderId.Value);
                            break;
                        case WebhookAction.CancelOrder:
                            await _orderService.CancelBySystemAsync(result.OrderId.Value);
                            _logger.LogInformation("Order {OrderId} cancelled via webhook", result.OrderId.Value);
                            break;
                    }
                }

                return Ok();
            }
            catch (StripeException ex)
            {
                _logger.LogError(ex, "Stripe webhook error");
                return BadRequest();
            }
        }
    }
}
