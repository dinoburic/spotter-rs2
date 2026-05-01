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
    public class VenueService : BaseCRUDService<Venue, VenueResponse, VenueSearch, VenueInsertRequest, VenueUpdateRequest>, IVenueService
    {
        private readonly ILogger<VenueService> _logger;

        public VenueService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<VenueInsertRequest> insertValidator,
            IValidator<VenueUpdateRequest> updateValidator,
            ILogger<VenueService> logger)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        protected override IQueryable<Venue> ApplyFilters(IQueryable<Venue> query, VenueSearch? search)
        {
            if (search == null)
                return query;

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(v => v.Name.Contains(search.Name));

            if (search.CityId.HasValue)
                query = query.Where(v => v.CityId == search.CityId.Value);

            return query;
        }

        protected override Task<IQueryable<Venue>> IncludeRelatedEntitiesAsync(VenueSearch? search, IQueryable<Venue> query)
        {
            return Task.FromResult<IQueryable<Venue>>(query.Include(v => v.City));
        }

        public override async Task<VenueResponse> InsertAsync(VenueInsertRequest request)
        {
            _logger.LogInformation("Creating venue {VenueName} in city {CityId}", request.Name, request.CityId);
            var cityExists = await _dbContext.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
            {
                _logger.LogWarning("City {CityId} not found", request.CityId);
                throw new NotFoundException("City not found.");
            }

            var result = await base.InsertAsync(request);
            _logger.LogInformation("Venue {VenueId} created successfully", result.Id);
            return result;
        }

        public override async Task<VenueResponse> UpdateAsync(int id, VenueUpdateRequest request)
        {
            _logger.LogInformation("Updating venue {VenueId}", id);
            var cityExists = await _dbContext.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
            {
                _logger.LogWarning("City {CityId} not found", request.CityId);
                throw new NotFoundException("City not found.");
            }

            var result = await base.UpdateAsync(id, request);
            _logger.LogInformation("Venue {VenueId} updated successfully", id);
            return result;
        }

        public override async Task DeleteAsync(int id)
        {
            _logger.LogInformation("Deleting venue {VenueId}", id);
            var hasEvents = await _dbContext.Events.AnyAsync(e => e.VenueId == id);

            if (hasEvents)
            {
                _logger.LogWarning("Venue {VenueId} cannot be deleted - has events", id);
                throw new ClientException("Venue cannot be deleted because it has existing events.");
            }

            await base.DeleteAsync(id);
            _logger.LogInformation("Venue {VenueId} deleted successfully", id);
        }
    }
}
