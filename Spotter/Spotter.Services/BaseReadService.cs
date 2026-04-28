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
                query = query.OrderBy(search.SortBy);
            }

            var pageSize = search?.PageSize.HasValue == true
                ? Math.Min(search.PageSize!.Value, 100)
                : 20;

            if (search?.Page.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * pageSize);
            }

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
            var entity = await _dbContext.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
            }

            return _mapper.Map<TResponse>(entity);
        }
    }
}
