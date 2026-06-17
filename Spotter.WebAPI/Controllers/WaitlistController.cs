using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/waitlist")]
    [Authorize]
    public class WaitlistController : ControllerBase
    {
        private readonly IWaitlistService _waitlistService;

        public WaitlistController(IWaitlistService waitlistService)
        {
            _waitlistService = waitlistService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<WaitlistEntryResponse>>> GetAll([FromQuery] WaitlistSearch? search)
        {
            var result = await _waitlistService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpPost("join")]
        public async Task<ActionResult<WaitlistEntryResponse>> Join([FromBody] WaitlistJoinRequest request)
        {
            var result = await _waitlistService.JoinAsync(request);
            return Created(string.Empty, result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Leave(int id)
        {
            await _waitlistService.LeaveAsync(id);
            return NoContent();
        }
    }
}
