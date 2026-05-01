using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/points")]
    [Authorize]
    public class SpotterPointsController : ControllerBase
    {
        private readonly ISpotterPointsService _spotterPointsService;

        public SpotterPointsController(ISpotterPointsService spotterPointsService)
        {
            _spotterPointsService = spotterPointsService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<SpotterPointsResponse>>> GetLedger([FromQuery] SpotterPointsSearch? search)
        {
            var result = await _spotterPointsService.GetLedgerAsync(search);
            return Ok(result);
        }

        [HttpGet("balance")]
        public async Task<ActionResult<PointsBalanceResponse>> GetBalance()
        {
            var result = await _spotterPointsService.GetBalanceAsync();
            return Ok(result);
        }

        [HttpGet("balance/{userId}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<PointsBalanceResponse>> GetBalanceForUser(int userId)
        {
            var result = await _spotterPointsService.GetBalanceAsync(userId);
            return Ok(result);
        }
    }
}
