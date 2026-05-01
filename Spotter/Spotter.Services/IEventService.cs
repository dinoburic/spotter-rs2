using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IEventService
    {
        Task<PageResult<EventResponse>> GetAllAsync(EventSearch? search = null);
        Task<EventResponse> GetByIdAsync(int id);
        Task<EventResponse> InsertAsync(EventInsertRequest request);
        Task<EventResponse> UpdateAsync(int id, EventUpdateRequest request);
        Task DeleteAsync(int id);
        Task<EventResponse> ActivateAsync(int id);
        Task<EventResponse> CancelAsync(int id);
        Task<EventResponse> CompleteAsync(int id);
    }
}
