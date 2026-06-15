using Spotter.Model.Enums;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface ISpotterPointsService
    {
        Task<PageResult<SpotterPointsResponse>> GetLedgerAsync(SpotterPointsSearch? search = null);
        Task<PointsBalanceResponse> GetBalanceAsync(int? userId = null);
        Task<SpotterPointsResponse> EarnAsync(int userId, int delta, PointSource source, string? referenceId = null, string? description = null);
        Task RedeemAsync(int userId, int points, string? referenceId = null);
    }
}
