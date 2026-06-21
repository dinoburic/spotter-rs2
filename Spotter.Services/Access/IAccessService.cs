using Spotter.Model.Access;
using Spotter.Model.Requests;

namespace Spotter.Services
{
    public interface IAccessService
    {
        Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> LoginWithRefreshTokenAsync(string refreshToken);
        Task LogoutAsync(int userId, string refreshToken);
        Task<UserLoginResponse> RegisterAsync(RegisterRequest request);
    }
}
