using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class EventSearch : BaseSearchObject
    {
        public string? Title { get; set; }
        public int? CategoryId { get; set; }
        public int? CityId { get; set; }
        public int? VenueId { get; set; }
        public int? OrganizerId { get; set; }
        public EventStatus? Status { get; set; }
        public DateTime? StartsAfter { get; set; }
        public DateTime? StartsBefore { get; set; }
        public bool IncludeDeleted { get; set; } = false;
    }
}
