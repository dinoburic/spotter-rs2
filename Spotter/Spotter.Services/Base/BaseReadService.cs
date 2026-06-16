using Microsoft.EntityFrameworkCore;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;
using System.Linq.Dynamic.Core;

namespace Spotter.Services
{
    public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        private static readonly HashSet<string> _allowedSortColumns = new(StringComparer.OrdinalIgnoreCase)
        {
            "Id", "CreatedAt", "UpdatedAt", "Name", "Title", "StartsAt", "Price", "Rating"
        };

        protected readonly MapsterMapper.IMapper _mapper;
        protected readonly SpotterDbContext _dbContext;

        protected BaseReadService(MapsterMapper.IMapper mapper, SpotterDbContext dbContext)
        {
            _mapper = mapper;
            _dbContext = dbContext;
        }

        protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch? search);

        public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
        {
            var page = Math.Max(1, search?.Page ?? 1);
            var pageSize = Math.Clamp(search?.PageSize ?? 10, 1, 100);

            IQueryable<TEntity> query = _dbContext.Set<TEntity>();

            query = await IncludeRelatedEntitiesAsync(search, query);
            query = ApplyFilters(query, search);

            int? totalCount = null;

            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            if (!string.IsNullOrWhiteSpace(search?.SortBy))
            {
                if (!_allowedSortColumns.Contains(search.SortBy))
                    throw new ClientException($"Invalid sort column: {search.SortBy}");
                query = query.OrderBy(search.SortBy);
            }

            query = query.Skip((page - 1) * pageSize);
            query = query.Take(pageSize);

            var entities = await query.ToListAsync();
            var list = entities.Select(item => _mapper.Map<TResponse>(item)).ToList();

            return new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount
            };
        }

        protected virtual Task<IQueryable<TEntity>> IncludeRelatedEntitiesAsync(TSearch? search, IQueryable<TEntity> query)
        {
            return Task.FromResult(query);
        }

        public virtual async Task<TResponse> GetByIdAsync(int id)
        {
            var query = _dbContext.Set<TEntity>().AsQueryable();
            query = await IncludeRelatedEntitiesAsync(null, query);
            
            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);
            
            if (entity == null)
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

            return _mapper.Map<TResponse>(entity);
        }
    }
}
