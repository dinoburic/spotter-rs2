using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/reservations")]
    [Authorize]
    public class ReservationController : ControllerBase
    {
        private readonly IReservationService _reservationService;

        public ReservationController(IReservationService reservationService)
        {
            _reservationService = reservationService;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<ReservationResponse>>> GetAll([FromQuery] ReservationSearch? search)
        {
            var result = await _reservationService.GetAllAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ReservationResponse>> GetById(int id)
        {
            var result = await _reservationService.GetByIdAsync(id);
            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<ReservationResponse>> Create([FromBody] ReservationInsertRequest request)
        {
            var result = await _reservationService.CreateAsync(request);
            return Created(string.Empty, result);
        }

        [HttpPost("{id}/confirm")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<ReservationResponse>> Confirm(int id, [FromBody] AuditNoteRequest? request)
        {
            var result = await _reservationService.ConfirmAsync(id, request?.AuditNote);
            return Ok(result);
        }

        [HttpPost("{id}/cancel")]
        public async Task<ActionResult<ReservationResponse>> Cancel(int id, [FromBody] AuditNoteRequest? request)
        {
            var result = await _reservationService.CancelAsync(id, request?.AuditNote);
            return Ok(result);
        }

        [HttpPost("{id}/complete")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<ReservationResponse>> Complete(int id)
        {
            var result = await _reservationService.CompleteAsync(id);
            return Ok(result);
        }
    }

    public class AuditNoteRequest
    {
        public string? AuditNote { get; set; }
    }
}
