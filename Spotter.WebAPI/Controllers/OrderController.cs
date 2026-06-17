using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/orders")]
    [Authorize]
    public class OrderController : ControllerBase
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<OrderResponse>>> GetAll([FromQuery] OrderSearch? search)
        {
            var result = await _orderService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<OrderResponse>> GetById(int id)
        {
            var result = await _orderService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<OrderResponse>> Create([FromBody] OrderInsertRequest request)
        {
            var result = await _orderService.CreateOrderAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPost("{id}/pay")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<OrderResponse>> MarkAsPaid(int id)
        {
            var result = await _orderService.MarkAsPaidAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/refund")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<OrderResponse>> Refund(int id)
        {
            var result = await _orderService.RefundAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/cancel")]
        public async Task<IActionResult> Cancel(int id)
        {
            await _orderService.CancelAsync(id);
            return NoContent();
        }
    }
}
