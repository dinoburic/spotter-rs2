using Newtonsoft.Json;
using Spotter.Worker.Models;

namespace Spotter.Worker.Services
{
    public class GeocodingService : IGeocodingService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<GeocodingService> _logger;
        private readonly string? _apiKey;

        public GeocodingService(IHttpClientFactory httpClientFactory, ILogger<GeocodingService> logger)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
            _apiKey = Environment.GetEnvironmentVariable("GOOGLE_MAPS_API_KEY");
        }

        public async Task<(decimal Latitude, decimal Longitude)?> GeocodeAsync(string name,string address, string city, string country)
        {
            if (string.IsNullOrEmpty(_apiKey))
            {
                _logger.LogWarning("GOOGLE_MAPS_API_KEY not set, skipping geocoding");
                return null;
            }

            
            var query = Uri.EscapeDataString($"{address}, {city}");
    var url = $"https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input={query}&inputtype=textquery&fields=geometry&key={_apiKey}";

    var client = _httpClientFactory.CreateClient();
    var response = await client.GetAsync(url);
    response.EnsureSuccessStatusCode();

    var json = await response.Content.ReadAsStringAsync();
    var result = JsonConvert.DeserializeObject<GoogleGeocodingResponse>(json);

    if (result?.Status != "OK" || result.Candidates.Length == 0)
    {
        _logger.LogWarning("Places API returned no results for: {Address}, {City}", address, city);
        return null;
    }

    var location = result.Candidates[0].Geometry.Location;
    return ((decimal)location.Lat, (decimal)location.Lng);
        }
    }
}
