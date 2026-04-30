using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface IFavoriteService
    {
        Task<PageResult<FavoriteResponse>> GetMyFavoritesAsync(FavoriteSearch? search = null);
        Task<FavoriteResponse> AddFavoriteAsync(int eventId);
        Task RemoveFavoriteAsync(int eventId);
    }
}
