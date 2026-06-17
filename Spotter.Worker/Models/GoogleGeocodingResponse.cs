using Newtonsoft.Json;

namespace Spotter.Worker.Models
{
    public class GoogleGeocodingResponse
    {
        [JsonProperty("status")]
    public string Status { get; set; } = string.Empty;

    [JsonProperty("candidates")]
    public PlaceCandidate[] Candidates { get; set; } = [];
}

public class PlaceCandidate
{
    [JsonProperty("geometry")]
    public GeocodingGeometry Geometry { get; set; } = new();
}
    public class GeocodingResult
    {
        [JsonProperty("geometry")]
        public GeocodingGeometry Geometry { get; set; } = new();
    }

    public class GeocodingGeometry
    {
        [JsonProperty("location")]
        public GeocodingLocation Location { get; set; } = new();
    }

    public class GeocodingLocation
    {
        [JsonProperty("lat")]
        public double Lat { get; set; }

        [JsonProperty("lng")]
        public double Lng { get; set; }
    }
}
