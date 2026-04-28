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
    public class VenueService : BaseCRUDService<Venue, VenueResponse, VenueSearch, VenueInsertRequest, VenueUpdateRequest>, IVenueService
    {
        public VenueService(
            SpotterDbContext dbContext,
            IMapper mapper,
            IValidator<VenueInsertRequest> insertValidator,
            IValidator<VenueUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
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
            var cityExists = await _dbContext.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
                throw new NotFoundException("City not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<VenueResponse> UpdateAsync(int id, VenueUpdateRequest request)
        {
            var cityExists = await _dbContext.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
                throw new NotFoundException("City not found.");

            return await base.UpdateAsync(id, request);
        }

        public override async Task DeleteAsync(int id)
        {
            var hasEvents = await _dbContext.Events.AnyAsync(e => e.VenueId == id);

            if (hasEvents)
                throw new ClientException("Venue cannot be deleted because it has existing events.");

            await base.DeleteAsync(id);
        }
    }
}
