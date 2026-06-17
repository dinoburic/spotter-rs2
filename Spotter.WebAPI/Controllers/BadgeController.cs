using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/badges")]
    [Authorize]
    public class BadgeController : ControllerBase
    {
        private readonly IBadgeService _badgeService;

        public BadgeController(IBadgeService badgeService)
        {
            _badgeService = badgeService;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<List<BadgeResponse>>> GetAll()
        {
            var result = await _badgeService.GetAllBadgesAsync();
            return Ok(result);
        }

        [HttpGet("my")]
        public async Task<ActionResult<List<UserBadgeResponse>>> GetMyBadges()
        {
            var result = await _badgeService.GetUserBadgesAsync();
            return Ok(result);
        }

        [HttpGet("user/{userId}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<List<UserBadgeResponse>>> GetUserBadges(int userId)
        {
            var result = await _badgeService.GetUserBadgesAsync(userId);
            return Ok(result);
        }
    }
}
