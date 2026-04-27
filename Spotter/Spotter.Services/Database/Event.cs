using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Event
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public Category Category { get; set; } = null!;
        public int OrganizerId { get; set; }
        public User Organizer { get; set; } = null!;
        public int VenueId { get; set; }
        public Venue Venue { get; set; } = null!;
        public DateTime StartsAt { get; set; }
        public DateTime EndsAt { get; set; }
        public EventStatus Status { get; set; }
        public string? CoverImageUrl { get; set; }
        public int TotalCapacity { get; set; }
        public bool GeocodingPending { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public ICollection<EventTag> Tags { get; set; } = new List<EventTag>();
        public ICollection<TicketType> TicketTypes { get; set; } = new List<TicketType>();
    }
}
