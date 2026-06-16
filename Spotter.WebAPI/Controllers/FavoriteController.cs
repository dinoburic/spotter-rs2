using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/favorites")]
    [Authorize]
    public class FavoriteController : ControllerBase
    {
        private readonly IFavoriteService _favoriteService;

        public FavoriteController(IFavoriteService favoriteService)
        {
            _favoriteService = favoriteService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<FavoriteResponse>>> GetMyFavorites([FromQuery] FavoriteSearch? search)
        {
            var result = await _favoriteService.GetMyFavoritesAsync(search);
            return Ok(result);
        }

        [HttpPost("{eventId}")]
        public async Task<ActionResult<FavoriteResponse>> AddFavorite(int eventId)
        {
            var result = await _favoriteService.AddFavoriteAsync(eventId);
            return Created(string.Empty, result);
        }

        [HttpDelete("{eventId}")]
        public async Task<IActionResult> RemoveFavorite(int eventId)
        {
            await _favoriteService.RemoveFavoriteAsync(eventId);
            return NoContent();
        }
    }
}
