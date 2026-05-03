namespace Spotter.Worker.Services
{
    public interface IGeocodingService
    {
        Task<(decimal Latitude, decimal Longitude)?> GeocodeAsync(string name,string address, string city, string country);
    }
}
