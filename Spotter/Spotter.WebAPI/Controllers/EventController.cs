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
    [Route("api/events")]
    [Authorize]
    public class EventController : ControllerBase
    {
        private readonly IEventService _eventService;

        public EventController(IEventService eventService)
        {
            _eventService = eventService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<PageResult<EventResponse>>> GetAll([FromQuery] EventSearch? search)
        {
            var result = await _eventService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<EventResponse>> GetById(int id)
        {
            var result = await _eventService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Insert([FromBody] EventInsertRequest request)
        {
            var result = await _eventService.InsertAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Update(int id, [FromBody] EventUpdateRequest request)
        {
            var result = await _eventService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _eventService.DeleteAsync(id);
            return NoContent();
        }

        [HttpPost("{id}/activate")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Activate(int id)
        {
            var result = await _eventService.ActivateAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/cancel")]
        [Authorize]
        public async Task<ActionResult<EventResponse>> Cancel(int id)
        {
            var result = await _eventService.CancelAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/complete")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<EventResponse>> Complete(int id)
        {
            var result = await _eventService.CompleteAsync(id);
            return Ok(result);
        }
    }
}
