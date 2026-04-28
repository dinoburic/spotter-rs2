namespace Spotter.Model.Requests
{
    public class VenueInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
    }
}
