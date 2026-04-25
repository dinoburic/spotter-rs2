using Spotter.Services;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;

namespace Spotter.WebAPI.Controllers;

public class ProductsController : BaseCRUDController<ProductResponse, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest, IProductService>
{
    public ProductsController(IProductService productService) : base(productService)
    {
    }

    /// <summary>
    /// Retrieves the product that has the longest name matching the given search criteria.
    /// </summary>
    /// <param name="search">Optional search criteria to filter products.</param>
    /// <returns>The longest description product</returns>
    /// <remarks>
    /// Sample response:
    ///
    ///     POST /Todo
    ///     {
    ///         "id": 2,
    ///         "name": "Mechanical Keyboard",
    ///         "description": "RGB backlit mechanical keyboard with blue switches.",
    ///         "price": 79.99,
    ///         "stockQuantity": 75,
    ///         "isActive": true,
    ///         "createdAt": "2026-02-27T12:15:43.4170502Z",
    ///         "updatedAt": null,
    ///         "sku": "MK-2002",
    ///         "weight": 1200,
    ///         "productTypeId": 2,
    ///         "unitOfMeasureId": 1
    ///     }
    ///
    /// </remarks>
    /// <response code="200">Product found - returns the product with the longest name.</response>
    /// <response code="404">No product matches the provided search criteria.</response>

    [HttpGet("MaxName")]
    [Produces("application/json")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductResponse>> GetWithMaxName([FromQuery] ProductSearchObject? search)
    {
        var result = await _service.GetWithMaxNameAsync(search);
        return Ok(result);

    }


    [HttpPost("{id}/Activate")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductResponse>> Activate(int id)
    {
        var result = await _service.ActivateAsync(id);
        return Ok(result);
    }

    [HttpPost("{id}/Deactivate")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductResponse>> Deactivate(int id)
    {
        var result = await _service.DeactivateAsync(id);
        return Ok(result); 
    }

    [HttpGet("{id}/AllowedActions")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
    {        
        var result = await _service.GetAllowedActionsAsync(id);
        return Ok(result);
    }

}
