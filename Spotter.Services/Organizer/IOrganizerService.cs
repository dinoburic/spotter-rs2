using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface IOrganizerService
    {
        Task<OrganizerDashboardResponse> GetDashboardAsync();
    }
}
