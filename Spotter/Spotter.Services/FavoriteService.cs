using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class FavoriteService : IFavoriteService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;

        public FavoriteService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
        }

        public async Task<PageResult<FavoriteResponse>> GetMyFavoritesAsync(FavoriteSearch? search = null)
        {
            var userId = _currentUserService.GetUserId();

            var query = _dbContext.Favorites
                .Include(f => f.Event)
                .Where(f => f.UserId == userId)
                .AsQueryable();

            if (search != null)
            {
                if (search.EventId.HasValue)
                    query = query.Where(f => f.EventId == search.EventId.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var favorites = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<FavoriteResponse>
            {
                Items = favorites.Select(f => _mapper.Map<FavoriteResponse>(f)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<FavoriteResponse> AddFavoriteAsync(int eventId)
        {
            var eventEntity = await _dbContext.Events.FirstOrDefaultAsync(e => e.Id == eventId && !e.IsDeleted);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            var userId = _currentUserService.GetUserId();

            var exists = await _dbContext.Favorites.AnyAsync(f => f.UserId == userId && f.EventId == eventId);
            if (exists)
                throw new ClientException("Event is already in your favorites.");

            var favorite = new Favorite
            {
                UserId = userId,
                EventId = eventId,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Favorites.Add(favorite);
            await _dbContext.SaveChangesAsync();

            var createdFavorite = await _dbContext.Favorites
                .Include(f => f.Event)
                .FirstAsync(f => f.Id == favorite.Id);

            return _mapper.Map<FavoriteResponse>(createdFavorite);
        }

        public async Task RemoveFavoriteAsync(int eventId)
        {
            var userId = _currentUserService.GetUserId();

            var favorite = await _dbContext.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.EventId == eventId);

            if (favorite == null)
                throw new NotFoundException("Favorite not found.");

            _dbContext.Favorites.Remove(favorite);
            await _dbContext.SaveChangesAsync();
        }
    }
}
