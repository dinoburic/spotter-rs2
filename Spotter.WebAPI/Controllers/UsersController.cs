using Spotter.Model.Access;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services;
using Spotter.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Spotter.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : BaseCRUDController<UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest, IUserService>
{
    private readonly ICurrentUserService _currentUserService;

    public UsersController(IUserService userService, ICurrentUserService currentUserService) : base(userService)
    {
        _currentUserService = currentUserService;
    }

    [HttpGet]
    [Authorize(Roles = Roles.Admin)]
    public override Task<PageResult<UserResponse>> GetAll([FromQuery] UserSearch? search)
    {
        return base.GetAll(search);
    }

    [Authorize(Roles = Roles.Admin)]
    public override Task<ActionResult<UserResponse>> Create([FromBody] UserInsertRequest request)
    {
        return base.Create(request);
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetCurrentUser()
    {
        var userId = _currentUserService.GetUserId();
        var result = await _service.GetWithRoleByIdAsync(userId);
        if (result == null)
            return NotFound();
        return Ok(result);
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserResponse>> UpdateCurrentUser([FromBody] UserUpdateRequest request)
    {
        var userId = _currentUserService.GetUserId();
        var result = await _service.UpdateAsync(userId, request);
        return Ok(result);
    }

    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = _currentUserService.GetUserId();
        await _service.ChangePasswordAsync(userId, request);
        return Ok(new { message = "Password changed successfully." });
    }

    [HttpGet("me/interests")]
    public async Task<ActionResult<List<UserInterestResponse>>> GetMyInterests()
    {
        var userId = _currentUserService.GetUserId();
        var result = await _service.GetInterestsAsync(userId);
        return Ok(result);
    }

    [HttpPut("me/interests")]
    public async Task<IActionResult> UpdateMyInterests([FromBody] UpdateInterestsRequest request)
    {
        var userId = _currentUserService.GetUserId();
        await _service.UpdateInterestsAsync(userId, request);
        return Ok();
    }
}