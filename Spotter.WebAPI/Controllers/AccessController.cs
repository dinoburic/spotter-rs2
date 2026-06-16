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

        public AccessController(IAccessService accessService)
        {
            _accessService = accessService;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<UserLoginResponse>> Login([FromBody] UserLoginRequest request)
        {
            var result = await _accessService.LoginAsync(request);
            return Ok(result);
        }

        [HttpPost("refresh")]
        public async Task<ActionResult<UserLoginResponse>> Refresh([FromBody] RefreshAccessTokenRequest request)
        {
            var result = await _accessService.LoginWithRefreshTokenAsync(request.RefreshToken);
            return Ok(result);
        }


        [AllowAnonymous]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] RefreshAccessTokenRequest request)
        {
            var accessToken = Request.Headers.Authorization.ToString().Replace("Bearer ", "");
            await _accessService.LogoutAsync(accessToken, request.RefreshToken);
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
