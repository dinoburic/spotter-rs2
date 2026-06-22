using Spotter.Model.Requests;
using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface ISystemSettingService
    {
        Task<List<SystemSettingResponse>> GetAllAsync();
        Task<SystemSettingResponse> UpdateAsync(string key, SystemSettingUpdateRequest request);
    }
}
