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
    [Route("api/tickets")]
    [Authorize]
    public class TicketController : ControllerBase
    {
        private readonly ITicketService _ticketService;

        public TicketController(ITicketService ticketService)
        {
            _ticketService = ticketService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<TicketResponse>>> GetAll([FromQuery] TicketSearch? search)
        {
            var result = await _ticketService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TicketResponse>> GetById(int id)
        {
            var result = await _ticketService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost("use")]
        [Authorize(Roles = $"{Roles.Admin},{Roles.Organizer}")]
        public async Task<ActionResult<TicketResponse>> UseTicket([FromBody] UseTicketRequest request)
        {
            var result = await _ticketService.UseTicketAsync(request.QrCodePayload);
            return Ok(result);
        }
    }
}
