using Spotter.Model.Access;

namespace Spotter.WebAPI.Services.AccessService
{
    public interface IAccessService
    {
        Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
    }
}
