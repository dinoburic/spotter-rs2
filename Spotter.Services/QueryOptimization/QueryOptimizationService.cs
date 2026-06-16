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

    }
}
