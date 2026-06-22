using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/organizer")]
    [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
    public class OrganizerController : ControllerBase
    {
        private readonly IOrganizerService _organizerService;

        public OrganizerController(IOrganizerService organizerService)
        {
            _organizerService = organizerService;
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<OrganizerDashboardResponse>> GetDashboard()
        {
            var result = await _organizerService.GetDashboardAsync();
            return Ok(result);
        }
    }
}
