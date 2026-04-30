using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface ITicketTypeService : IBaseCRUDService<TicketTypeResponse, TicketTypeSearch, TicketTypeInsertRequest, TicketTypeUpdateRequest>
    {
    }
}
