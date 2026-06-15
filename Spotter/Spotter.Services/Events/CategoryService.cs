using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class CategoryService : BaseCRUDService<Category, CategoryResponse, CategorySearch, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
    {
        private readonly ILogger<CategoryService> _logger;

        public CategoryService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<CategoryInsertRequest> insertValidator,
            IValidator<CategoryUpdateRequest> updateValidator,
            ILogger<CategoryService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        protected override IQueryable<Category> ApplyFilters(IQueryable<Category> query, CategorySearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            return query;
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting category {CategoryId}", id);
            var hasEvents = await _dbContext.Events.AnyAsync(e => e.CategoryId == id);
            var hasUserInterests = await _dbContext.UserInterests.AnyAsync(ui => ui.CategoryId == id);

            if (hasEvents || hasUserInterests)
            {
                _logger.LogWarning("Category {CategoryId} cannot be deleted - in use", id);
                throw new ClientException("Category cannot be deleted because it is in use.");
            }

            await base.DeleteAsync(id);
            _logger.LogInformation("Category {CategoryId} deleted successfully", id);
        }
    }
}
