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
    [Route("api/ticket-types")]
    [Authorize]
    public class TicketTypeController : ControllerBase
    {
        private readonly ITicketTypeService _ticketTypeService;

        public TicketTypeController(ITicketTypeService ticketTypeService)
        {
            _ticketTypeService = ticketTypeService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<PageResult<TicketTypeResponse>>> GetAll([FromQuery] TicketTypeSearch? search)
        {
            var result = await _ticketTypeService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<TicketTypeResponse>> GetById(int id)
        {
            var result = await _ticketTypeService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<TicketTypeResponse>> Insert([FromBody] TicketTypeInsertRequest request)
        {
            var result = await _ticketTypeService.InsertAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<TicketTypeResponse>> Update(int id, [FromBody] TicketTypeUpdateRequest request)
        {
            var result = await _ticketTypeService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _ticketTypeService.DeleteAsync(id);
            return NoContent();
        }
    }
}
