using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IWaitlistService
    {
        Task<PageResult<WaitlistEntryResponse>> GetAllAsync(WaitlistSearch? search = null);
        Task<WaitlistEntryResponse> JoinAsync(WaitlistJoinRequest request);
        Task LeaveAsync(int entryId);
        Task NotifyNextInLineAsync(int ticketTypeId);
    }
}
