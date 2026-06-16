using Spotter.Model.Access;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IUserService : IBaseCRUDService<UserResponse, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserSensitveResponse?> GetByUsernameAsync(string username);
        Task<UserResponse?> GetWithRoleByIdAsync(int id);
        Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task<List<UserInterestResponse>> GetInterestsAsync(int userId);
        Task UpdateInterestsAsync(int userId, UpdateInterestsRequest request);
    }
}
