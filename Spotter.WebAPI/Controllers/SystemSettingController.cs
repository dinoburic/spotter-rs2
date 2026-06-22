using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/system-settings")]
    [Authorize(Roles = Roles.Admin)]
    public class SystemSettingController : ControllerBase
    {
        private readonly ISystemSettingService _service;

        public SystemSettingController(ISystemSettingService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<List<SystemSettingResponse>>> GetAll()
        {
            var result = await _service.GetAllAsync();
            return Ok(result);
        }

        [HttpPut("{key}")]
        public async Task<ActionResult<SystemSettingResponse>> Update(string key, [FromBody] SystemSettingUpdateRequest request)
        {
            var result = await _service.UpdateAsync(key, request);
            return Ok(result);
        }
    }
}
