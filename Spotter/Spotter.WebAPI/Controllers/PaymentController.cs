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
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(IStripeService stripeService, ILogger<PaymentController> logger)
        {
            _stripeService = stripeService;
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
                await _stripeService.HandleWebhookAsync(payload, stripeSignature!);
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
