using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Spotter.Model.Exceptions;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class CategoryService : BaseCRUDService<Category, CategoryResponse, CategorySearch, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
    {
        public CategoryService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<CategoryInsertRequest> insertValidator,
            IValidator<CategoryUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
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
            var hasEvents = await _dbContext.Events.AnyAsync(e => e.CategoryId == id);
            var hasUserInterests = await _dbContext.UserInterests.AnyAsync(ui => ui.CategoryId == id);

            if (hasEvents || hasUserInterests)
                throw new ClientException("Category cannot be deleted because it is in use.");

            await base.DeleteAsync(id);
        }
    }
}
