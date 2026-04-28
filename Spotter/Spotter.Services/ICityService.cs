using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface ICityService : IBaseCRUDService<CityResponse, CitySearch, CityInsertRequest, CityUpdateRequest>
    {
    }
}
