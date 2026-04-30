using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IFriendshipService
    {
        Task<PageResult<FriendshipResponse>> GetMyFriendshipsAsync(FriendshipSearch? search = null);
        Task<FriendshipResponse> SendRequestAsync(int addresseeId);
        Task<FriendshipResponse> AcceptAsync(int friendshipId);
        Task<FriendshipResponse> RejectAsync(int friendshipId);
        Task<FriendshipResponse> BlockAsync(int friendshipId);
        Task DeleteAsync(int friendshipId);
    }
}
