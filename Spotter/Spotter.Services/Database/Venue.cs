namespace Spotter.Services.Database
{
    public class Venue
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public City City { get; set; } = null!;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
    }
}
