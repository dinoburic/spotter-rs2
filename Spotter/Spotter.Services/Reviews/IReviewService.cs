using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IReviewService
    {
        Task<PageResult<ReviewResponse>> GetAllAsync(ReviewSearch? search = null);
        Task<ReviewResponse> GetByIdAsync(int id);
        Task<ReviewResponse> InsertAsync(ReviewInsertRequest request);
        Task<ReviewResponse> UpdateAsync(int id, ReviewUpdateRequest request);
        Task DeleteAsync(int id);
    }
}
