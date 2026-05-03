using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Exceptions;
using Spotter.Model.Messages;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class VenueService : BaseCRUDService<Venue, VenueResponse, VenueSearch, VenueInsertRequest, VenueUpdateRequest>, IVenueService
    {
        private readonly ILogger<VenueService> _logger;
        private readonly IRabbitMqPublisher _rabbitMqPublisher;

        public VenueService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<VenueInsertRequest> insertValidator,
            IValidator<VenueUpdateRequest> updateValidator,
            ILogger<VenueService> logger,
            IRabbitMqPublisher rabbitMqPublisher)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _rabbitMqPublisher = rabbitMqPublisher;
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

            var city = await _dbContext.Cities.FirstOrDefaultAsync(c => c.Id == request.CityId);
            if (city == null)
            {
                _logger.LogWarning("City {CityId} not found", request.CityId);
                throw new NotFoundException("City not found.");
            }

            var entity = _mapper.Map<Venue>(request);
            entity.GeocodingPending = false;
            _dbContext.Venues.Add(entity);
            await _dbContext.SaveChangesAsync();

            if (request.Latitude.HasValue && request.Longitude.HasValue)
            {
                entity.Latitude = request.Latitude.Value;
                entity.Longitude = request.Longitude.Value;
                entity.GeocodingPending = false;
                await _dbContext.SaveChangesAsync();
                _logger.LogInformation("Coordinates set manually for venue {VenueId}", entity.Id);
            }
            else
            {
                try
                {
                    await _rabbitMqPublisher.PublishAsync(QueueNames.Geocoding, new GeocodingRequestMessage
                    {
                        VenueId = entity.Id,
                        Name = entity.Name,
                        Address = entity.Address,
                        City = city.Name,
                        Country = city.Country
                    });
                    entity.GeocodingPending = true;
                    await _dbContext.SaveChangesAsync();
                    _logger.LogInformation("Geocoding request published for venue {VenueId}", entity.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to publish geocoding request for venue {VenueId}", entity.Id);
                }
            }

            var createdVenue = await _dbContext.Venues
                .Include(v => v.City)
                .FirstAsync(v => v.Id == entity.Id);

            _logger.LogInformation("Venue {VenueId} created successfully", entity.Id);
            return _mapper.Map<VenueResponse>(createdVenue);
        }

        public override async Task<VenueResponse> UpdateAsync(int id, VenueUpdateRequest request)
        {
            _logger.LogInformation("Updating venue {VenueId}", id);
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _dbContext.Venues
                .Include(v => v.City)
                .FirstOrDefaultAsync(v => v.Id == id);

            if (entity == null)
            {
                _logger.LogWarning("Venue {VenueId} not found", id);
                throw new NotFoundException("Venue not found.");
            }

            var city = await _dbContext.Cities.FirstOrDefaultAsync(c => c.Id == request.CityId);
            if (city == null)
            {
                _logger.LogWarning("City {CityId} not found", request.CityId);
                throw new NotFoundException("City not found.");
            }

            var addressChanged = entity.Address != request.Address || entity.CityId != request.CityId;
            _mapper.Map(request, entity);

            if (request.Latitude.HasValue && request.Longitude.HasValue)
            {
                entity.Latitude = request.Latitude.Value;
                entity.Longitude = request.Longitude.Value;
                entity.GeocodingPending = false;
            }
            else if (addressChanged)
            {
                try
                {
                    await _rabbitMqPublisher.PublishAsync(QueueNames.Geocoding, new GeocodingRequestMessage
                    {
                        VenueId = entity.Id,
                        Name = entity.Name,
                        Address = entity.Address,
                        City = city.Name,
                        Country = city.Country
                    });
                    entity.GeocodingPending = true;
                    _logger.LogInformation("Geocoding request published for venue {VenueId}", entity.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to publish geocoding request for venue {VenueId}", entity.Id);
                }
            }

            await _dbContext.SaveChangesAsync();

            var updatedVenue = await _dbContext.Venues
                .Include(v => v.City)
                .FirstAsync(v => v.Id == entity.Id);

            _logger.LogInformation("Venue {VenueId} updated successfully", id);
            return _mapper.Map<VenueResponse>(updatedVenue);
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