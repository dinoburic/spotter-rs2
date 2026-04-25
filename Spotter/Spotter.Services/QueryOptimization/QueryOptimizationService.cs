using Spotter.Model.Responses;
using Spotter.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Spotter.Services.QueryOptimization
{
    public class QueryOptimizationService : IQueryOptimizationService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper mapper;

        public QueryOptimizationService(SpotterDbContext dbContext, IMapper mapper)
        {
            _dbContext = dbContext;
            this.mapper = mapper;
        }


        public async Task<ProductResponse> AsNoTrackingBadQuerry()
        {
           var product = await _dbContext.Products.FirstAsync();

            product.Name = "Updated Name";

            foreach (var entries in _dbContext.ChangeTracker.Entries())
            {
                var entity = entries.Entity;
                var state = entries.State;
            }

            return mapper.Map<ProductResponse>(product);

        }

        public async Task<ProductResponse> AsNoTrackingGoodQuerry()
        {
            var product = await _dbContext.Products.AsNoTracking().FirstAsync();

            product.Name = "Updated Name";

            foreach (var entries in _dbContext.ChangeTracker.Entries())
            {
                var entity = entries.Entity;
                var state = entries.State;
            }

            return mapper.Map<ProductResponse>(product);
        }

        public async Task<List<ProductResponse>> GetFilteredProductsBadQuerry()
        {
            var products = await _dbContext.Products.ToListAsync();

            var expensiveProducts = products.Where(p => p.Price > 400).ToList();

            return expensiveProducts.Select(p => mapper.Map<ProductResponse>(p)).ToList();
        }

        public async Task<List<ProductResponse>> GetFilteredProductsGoodQuerry()
        {
            var products = _dbContext.Products;

            var expensiveProducts = await products.Where(p => p.Price > 400).ToListAsync();

            return expensiveProducts.Select(p => mapper.Map<ProductResponse>(p)).ToList();
        }

        public async Task<List<string>> GetFullNamesBadQuerry()
        {
            var fullNames = new List<string>();

            await foreach(var user in _dbContext.Users.AsAsyncEnumerable())
            {
                fullNames.Add($"{user.FirstName} {user.LastName}");
            }

            return fullNames;
        }

        public async Task<List<string>> GetFullNamesGoodQuerry()
        {
            var fullNames = new List<string>();

            await foreach (var userName in _dbContext.Users.Select(u => u.FirstName + " " + u.LastName).AsAsyncEnumerable())
            {
                fullNames.Add(userName);
            }

            return fullNames;
        }

        public async Task<List<UserResponse>> SplittingQueries()
        {
            var users = await _dbContext.Users
                .Include(u => u.UserRoles)
                .Include(u => u.RefreshTokens)
                .AsSplitQuery()
                .ToListAsync();

            var userResponses = users.Select(u => mapper.Map<UserResponse>(u)).ToList();

            return userResponses;
        }

        public async Task<List<ProductResponse>> UsingSqlQueries()
        {
            var products = await _dbContext.Products
                .FromSqlRaw("SELECT * FROM Products as P WHERE P.Price > 300")
                .ToListAsync();

            var productResponses = products.Select(u => mapper.Map<ProductResponse>(u)).ToList();

            return productResponses;
        }
    }
}
