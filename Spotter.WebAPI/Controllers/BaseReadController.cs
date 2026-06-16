using Microsoft.AspNetCore.Mvc;
using Spotter.Services;
using Spotter.Model.SearchObjects;
using Spotter.Model.Responses;
using Microsoft.AspNetCore.Authorization;

namespace Spotter.WebAPI.Controllers;

[ApiController]
[Route("[controller]")]
public abstract class BaseReadController<TResponse, TSearch, TService> : ControllerBase
    where TSearch : BaseSearchObject
    where TService : IBaseReadService<TResponse, TSearch>
{
    protected readonly TService _service;

    protected BaseReadController(TService service)
    {
        _service = service;
    }

    [HttpGet]
    public virtual async Task<PageResult<TResponse>> GetAll([FromQuery] TSearch? search)
    {
        var results = await _service.GetAllAsync(search);
        return results;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TResponse>> GetById(int id)
    {
        var result = await _service.GetByIdAsync(id);
        return Ok(result);
    }
}
