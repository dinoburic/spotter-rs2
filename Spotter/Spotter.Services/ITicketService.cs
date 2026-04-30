using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface ITicketService
    {
        Task<PageResult<TicketResponse>> GetAllAsync(TicketSearch? search = null);
        Task<TicketResponse> GetByIdAsync(int id);
        Task<TicketResponse> UseTicketAsync(string qrCodePayload);
    }
}
