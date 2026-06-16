using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Responses;
using Spotter.Model.Static;
using Spotter.Services;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("api/reports")]
    [Authorize(Roles = Roles.Admin)]
    public class ReportController : ControllerBase
    {
        private readonly IReportService _reportService;

        public ReportController(IReportService reportService)
        {
            _reportService = reportService;
        }

        [HttpGet("financial")]
        public async Task<ActionResult<FinancialReportResponse>> GetFinancial(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to,
            [FromQuery] int? categoryId)
        {
            var result = await _reportService.GetFinancialReportAsync(from, to, categoryId);
            return Ok(result);
        }

        [HttpGet("guest-list")]
        public async Task<ActionResult<GuestListResponse>> GetGuestList(
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to,
            [FromQuery] int? categoryId)
        {
            var result = await _reportService.GetGuestListAsync(from, to, categoryId);
            return Ok(result);
        }
    }
}
