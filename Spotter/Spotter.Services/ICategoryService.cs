using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;

namespace Spotter.Services
{
    public interface ICategoryService : IBaseCRUDService<CategoryResponse, CategorySearchObject, CategoriesInsertRequest, CategoriesUpdateRequest>
    {
        Task<CategoryResponse> ExceptionTestingInsertAsync(CategoriesInsertRequest request);

    }
}