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
    public class CityService : BaseCRUDService<City, CityResponse, CitySearch, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        private readonly ILogger<CityService> _logger;

        public CityService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<CityInsertRequest> insertValidator,
            IValidator<CityUpdateRequest> updateValidator,
            ILogger<CityService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        protected override IQueryable<City> ApplyFilters(IQueryable<City> query, CitySearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (!string.IsNullOrWhiteSpace(search.Country))
                query = query.Where(c => c.Country.Contains(search.Country));

            return query;
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting city {CityId}", id);
            var hasUsers = await _dbContext.Users.AnyAsync(u => u.CityId == id);
            var hasVenues = await _dbContext.Venues.AnyAsync(v => v.CityId == id);

            if (hasUsers || hasVenues)
            {
                _logger.LogWarning("City {CityId} cannot be deleted - has references", id);
                throw new ClientException("City cannot be deleted because it is referenced by existing users or venues.");
            }

            await base.DeleteAsync(id);
            _logger.LogInformation("City {CityId} deleted successfully", id);
        }
    }
}
