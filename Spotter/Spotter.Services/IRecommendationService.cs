using Spotter.Model.Responses;

namespace Spotter.Services
{
    public interface IRecommendationService
    {
        Task<List<RecommendationResponse>> GetRecommendationsAsync(int userId);
        Task TrainModelAsync();
    }
}
