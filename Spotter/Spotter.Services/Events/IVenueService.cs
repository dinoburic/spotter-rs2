using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IVenueService : IBaseCRUDService<VenueResponse, VenueSearch, VenueInsertRequest, VenueUpdateRequest>
    {
    }
}
