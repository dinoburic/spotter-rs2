namespace Spotter.Model.Responses
{
    public class CategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ColorHex { get; set; } = string.Empty;
        public string IconSlug { get; set; } = string.Empty;
    }
}
