using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IFriendshipService
    {
        Task<PageResult<FriendshipResponse>> GetMyFriendshipsAsync(FriendshipSearch? search = null);
        Task<PageResult<UserSuggestionResponse>> GetFriendsAsync(int page = 1, int pageSize = 20);
        Task<PageResult<FriendshipResponse>> GetPendingRequestsAsync(int page = 1, int pageSize = 20);
        Task<PageResult<UserSuggestionResponse>> GetSuggestionsAsync(int page = 1, int pageSize = 10);
        Task<PageResult<UserSuggestionResponse>> SearchUsersAsync(string query, int page = 1, int pageSize = 20);
        Task<FriendshipResponse> SendRequestAsync(int addresseeId);
        Task<FriendshipResponse> AcceptAsync(int friendshipId);
        Task<FriendshipResponse> RejectAsync(int friendshipId);
        Task<FriendshipResponse> BlockAsync(int friendshipId);
        Task DeleteAsync(int friendshipId);
    }
}
