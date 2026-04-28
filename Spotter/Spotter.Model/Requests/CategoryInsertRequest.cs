namespace Spotter.Model.Requests
{
    public class CategoryInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string ColorHex { get; set; } = string.Empty;
        public string IconSlug { get; set; } = string.Empty;
    }
}
