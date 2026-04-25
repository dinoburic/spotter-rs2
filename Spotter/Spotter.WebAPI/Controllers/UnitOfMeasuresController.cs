using Spotter.Services;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;

namespace Spotter.WebAPI.Controllers;

public class UnitOfMeasuresController : BaseCRUDController<UnitOfMeasureResponse, UnitOfMeasureSearch, UnitOfMeasureInsertRequest, UnitOfMeasureUpdateRequest, IUnitOfMeasureService>
{
    public UnitOfMeasuresController(IUnitOfMeasureService unitOfMeasureService) : base(unitOfMeasureService)
    {
    }
}
