using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Access;
using Spotter.Model.Requests;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/access")]

    public class AccessController : ControllerBase
    {
        private readonly IAccessService _accessService;
        private readonly ICurrentUserService _currentUserService;

        public AccessController(IAccessService accessService, ICurrentUserService currentUserService)
        {
            _accessService = accessService;
            _currentUserService = currentUserService;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<UserLoginResponse>> Login([FromBody] UserLoginRequest request)
        {
            var result = await _accessService.LoginAsync(request);
            return Ok(result);
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<ActionResult<UserLoginResponse>> Refresh([FromBody] RefreshAccessTokenRequest request)
        {
            var result = await _accessService.LoginWithRefreshTokenAsync(request.RefreshToken);
            return Ok(result);
        }


        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] LogoutRequest request)
        {
            var userId = _currentUserService.GetUserId();
            await _accessService.LogoutAsync(userId, request.RefreshToken);
            return NoContent();
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<ActionResult<UserLoginResponse>> Register([FromBody] RegisterRequest request)
        {
            var result = await _accessService.RegisterAsync(request);
            return Created(string.Empty, result);
        }
    }
}
