using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface IBadgeService
    {
        Task<List<BadgeResponse>> GetAllBadgesAsync();
        Task<List<UserBadgeResponse>> GetUserBadgesAsync(int? userId = null);
        Task EvaluateAndAwardAsync(int userId);
    }
}
