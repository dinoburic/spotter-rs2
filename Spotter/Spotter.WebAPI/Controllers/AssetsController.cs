using Spotter.Services;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Microsoft.AspNetCore.Mvc;
using Spotter.Model.Requests;

namespace Spotter.WebAPI.Controllers;

public class AssetsController : BaseCRUDController<AssetResponse, AssetSearch, AssetInsertRequest, AssetUpdateRequest, IAssetService>
{
    public AssetsController(IAssetService assetService) : base(assetService)
    {
    }
}
