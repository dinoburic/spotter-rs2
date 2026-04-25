using Spotter.Services;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;

namespace Spotter.WebAPI.Controllers;

public class ProductTypesController : BaseCRUDController<ProductTypeResponse, ProductTypeSearch, ProductTypeInsertRequest, ProductTypeUpdateRequest, IProductTypeService>
{
    public ProductTypesController(IProductTypeService productTypeService) : base(productTypeService)
    {
    }
}
