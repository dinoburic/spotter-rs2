using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class EventResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? CoverImageUrl { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryColorHex { get; set; } = string.Empty;
        public int VenueId { get; set; }
        public string VenueName { get; set; } = string.Empty;
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        public int OrganizerId { get; set; }
        public string OrganizerName { get; set; } = string.Empty;
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
        public EventStatus Status { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public int TotalCapacity { get; set; }
        public int AvailableCapacity { get; set; }
        public bool GeocodingPending { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
