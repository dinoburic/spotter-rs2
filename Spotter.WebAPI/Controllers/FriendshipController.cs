using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/friendships")]
    [Authorize]
    public class FriendshipController : ControllerBase
    {
        private readonly IFriendshipService _friendshipService;

        public FriendshipController(IFriendshipService friendshipService)
        {
            _friendshipService = friendshipService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<FriendshipResponse>>> GetMyFriendships([FromQuery] FriendshipSearch? search)
        {
            var result = await _friendshipService.GetMyFriendshipsAsync(search);
            return Ok(result);
        }

        [HttpGet("friends")]
        public async Task<ActionResult<PageResult<UserSuggestionResponse>>> GetFriends([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var result = await _friendshipService.GetFriendsAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("pending")]
        public async Task<ActionResult<PageResult<FriendshipResponse>>> GetPendingRequests([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var result = await _friendshipService.GetPendingRequestsAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("suggestions")]
        public async Task<ActionResult<PageResult<UserSuggestionResponse>>> GetSuggestions([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var result = await _friendshipService.GetSuggestionsAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("search")]
        public async Task<ActionResult<PageResult<UserSuggestionResponse>>> SearchUsers([FromQuery] string query, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (string.IsNullOrWhiteSpace(query))
                return Ok(new PageResult<UserSuggestionResponse> { Items = new List<UserSuggestionResponse>() });

            var result = await _friendshipService.SearchUsersAsync(query, page, pageSize);
            return Ok(result);
        }

        [HttpPost("request/{addresseeId}")]
        public async Task<ActionResult<FriendshipResponse>> SendRequest(int addresseeId)
        {
            var result = await _friendshipService.SendRequestAsync(addresseeId);
            return Created(string.Empty, result);
        }

        [HttpPost("{id}/accept")]
        public async Task<ActionResult<FriendshipResponse>> Accept(int id)
        {
            var result = await _friendshipService.AcceptAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/reject")]
        public async Task<ActionResult<FriendshipResponse>> Reject(int id)
        {
            var result = await _friendshipService.RejectAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/block")]
        public async Task<ActionResult<FriendshipResponse>> Block(int id)
        {
            var result = await _friendshipService.BlockAsync(id);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _friendshipService.DeleteAsync(id);
            return NoContent();
        }
    }
}
