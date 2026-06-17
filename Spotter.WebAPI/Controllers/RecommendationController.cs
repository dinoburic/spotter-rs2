using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/recommendations")]
    [Authorize]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;
        private readonly ICurrentUserService _currentUserService;

        public RecommendationController(
            IRecommendationService recommendationService,
            ICurrentUserService currentUserService)
        {
            _recommendationService = recommendationService;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        public async Task<ActionResult<List<RecommendationResponse>>> GetRecommendations()
        {
            var userId = _currentUserService.GetUserId();
            var recommendations = await _recommendationService.GetRecommendationsAsync(userId);
            return Ok(recommendations);
        }

        [HttpPost("train")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Train()
        {
            await _recommendationService.TrainModelAsync();
            return Ok(new { message = "Model training initiated" });
        }
    }
}
