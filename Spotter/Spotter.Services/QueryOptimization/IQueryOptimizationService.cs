using Spotter.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Spotter.Services.QueryOptimization
{
    public interface IQueryOptimizationService
    {
        Task<ProductResponse> AsNoTrackingBadQuerry();
        Task<ProductResponse> AsNoTrackingGoodQuerry();
        Task<List<ProductResponse>> GetFilteredProductsBadQuerry();
        Task<List<ProductResponse>> GetFilteredProductsGoodQuerry();
        Task<List<string>> GetFullNamesBadQuerry();
        Task<List<string>> GetFullNamesGoodQuerry();
        Task<List<UserResponse>> SplittingQueries();
        Task<List<ProductResponse>> UsingSqlQueries();
        
        
    }
}
