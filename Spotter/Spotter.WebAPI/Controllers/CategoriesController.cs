using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Spotter.WebAPI.Controllers;

public class CategoriesController : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoriesInsertRequest, CategoriesUpdateRequest, ICategoryService>
{
    public CategoriesController(ICategoryService categoryService) : base(categoryService)
    {
    }

    [HttpPost("ExceptionTestingInsert")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CategoryResponse>> ExceptionTestingInsert([FromBody] CategoriesInsertRequest request)
    {
        var result = await _service.ExceptionTestingInsertAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [AllowAnonymous]
    public override Task<PageResult<CategoryResponse>> GetAll([FromQuery] CategorySearchObject? search)
    {
        return base.GetAll(search);
    }
}