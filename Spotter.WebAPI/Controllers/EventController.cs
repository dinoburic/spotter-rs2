using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/events")]
    [Authorize]
    public class EventController : ControllerBase
    {
        private readonly IEventService _eventService;
        private readonly IWebHostEnvironment _webHostEnvironment;

        public EventController(IEventService eventService, IWebHostEnvironment webHostEnvironment)
        {
            _eventService = eventService;
            _webHostEnvironment = webHostEnvironment;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<PageResult<EventResponse>>> GetAll([FromQuery] EventSearch? search)
        {
            var result = await _eventService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<EventResponse>> GetById(int id)
        {
            var result = await _eventService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Insert([FromBody] EventInsertRequest request)
        {
            var result = await _eventService.InsertAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Update(int id, [FromBody] EventUpdateRequest request)
        {
            var result = await _eventService.UpdateAsync(id, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _eventService.DeleteAsync(id);
            return NoContent();
        }

        [HttpPost("{id}/activate")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Activate(int id)
        {
            var result = await _eventService.ActivateAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/cancel")]
        [Authorize(Roles = $"{Roles.Organizer},{Roles.Admin}")]
        public async Task<ActionResult<EventResponse>> Cancel(int id)
        {
            var result = await _eventService.CancelAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/complete")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<EventResponse>> Complete(int id)
        {
            var result = await _eventService.CompleteAsync(id);
            return Ok(result);
        }

        [HttpGet("{id}/friends-attending")]
        public async Task<ActionResult<List<UserResponse>>> GetFriendsAttending(int id)
        {
            var result = await _eventService.GetFriendsAttendingAsync(id);
            return Ok(result);
        }

        [HttpPost("{id}/cover-image")]
        [Authorize(Roles = $"{Roles.Admin},{Roles.Organizer}")]
        public async Task<ActionResult<object>> UploadCoverImage(int id, IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new ClientException("No file uploaded.");

            var allowedMimeTypes = new[] { "image/jpeg", "image/png", "image/webp" };
            if (!allowedMimeTypes.Contains(file.ContentType.ToLower()))
                throw new ClientException("Only JPEG, PNG, and WebP images are allowed.");

            using var stream = file.OpenReadStream();
            var buffer = new byte[4];
            await stream.ReadExactlyAsync(buffer);
            stream.Position = 0;

            var isJpeg = buffer[0] == 0xFF && buffer[1] == 0xD8;
            var isPng = buffer[0] == 0x89 && buffer[1] == 0x50;
            var isWebP = buffer[0] == 0x52 && buffer[1] == 0x49;

            if (!isJpeg && !isPng && !isWebP)
                throw new ClientException("Invalid image file.");

            var url = await _eventService.UploadCoverImageAsync(id, file, _webHostEnvironment.WebRootPath);
            return Ok(new { url });
        }
    }
}
