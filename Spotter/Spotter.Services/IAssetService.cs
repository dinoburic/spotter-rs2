using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Spotter.Services
{
    public interface IAssetService : IBaseCRUDService<AssetResponse, AssetSearch, AssetInsertRequest, AssetUpdateRequest>
    {
    }
}
