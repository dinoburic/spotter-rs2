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
    [Route("api/venues")]
    [Authorize]
    public class VenueController : ControllerBase
    {
        private readonly IVenueService _venueService;

        public VenueController(IVenueService venueService)
        {
            _venueService = venueService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<PageResult<VenueResponse>>> GetAll([FromQuery] VenueSearch? search)
        {
            var result = await _venueService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<VenueResponse>> GetById(int id)
        {
            var result = await _venueService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<VenueResponse>> Insert([FromBody] VenueInsertRequest request)
        {
            var result = await _venueService.InsertAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<VenueResponse>> Update(int id, [FromBody] VenueUpdateRequest request)
        {
            var result = await _venueService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Delete(int id)
        {
            await _venueService.DeleteAsync(id);
            return NoContent();
        }
    }
}
