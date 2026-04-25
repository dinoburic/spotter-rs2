using Azure;
using Spotter.Model.Access;
using Spotter.Model.Requests;
using Spotter.Services;
using Spotter.Services.QueryOptimization;
using Spotter.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;

namespace Spotter.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class QueryOptimizationController : Controller
    {
        private readonly IQueryOptimizationService _queryOptimizationService;
        public QueryOptimizationController(IQueryOptimizationService queryOptimizationService)
        {
            _queryOptimizationService = queryOptimizationService;
        }

        [HttpGet("AsNoTrackingBadQuerry")]
        public async Task<ActionResult> AsNoTrackingBadQuerry()
        {
            var result = await _queryOptimizationService.AsNoTrackingBadQuerry();
            return Ok(result);
        }

        [HttpGet("AsNoTrackingGoodQuerry")]
        public async Task<ActionResult> AsNoTrackingGoodQuerry()
        {
            var result = await _queryOptimizationService.AsNoTrackingGoodQuerry();
            return Ok(result);
        }

        [HttpGet("GetFilteredProductsBadQuerry")]
        public async Task<ActionResult> GetFilteredProductsBadQuerry()
        {
            var result = await _queryOptimizationService.GetFilteredProductsBadQuerry();
            return Ok(result);
        }

        [HttpGet("GetFilteredProductsGoodQuerry")]
        public async Task<ActionResult> GetFilteredProductsGoodQuerry()
        {
            var result = await _queryOptimizationService.GetFilteredProductsGoodQuerry();
            return Ok(result);
        }

        [HttpGet("GetFullNamesBadQuerry")]
        public async Task<ActionResult> GetFullNamesBadQuerry()
        {
            var result = await _queryOptimizationService.GetFullNamesBadQuerry();
            return Ok(result);
        }

        [HttpGet("GetFullNamesGoodQuerry")]
        public async Task<ActionResult> GetFullNamesGoodQuerry()
        {
            var result = await _queryOptimizationService.GetFullNamesGoodQuerry();
            return Ok(result);
        }

        [HttpGet("SplittingQueries")]
        public async Task<ActionResult> SplittingQueries()
        {
            var result = await _queryOptimizationService.SplittingQueries();
            return Ok(result);
        }

        [HttpGet("UsingSqlQueries")]
        public async Task<ActionResult> UsingSqlQueries()
        {
            var result = await _queryOptimizationService.UsingSqlQueries();
            return Ok(result);
        }

    }
}
