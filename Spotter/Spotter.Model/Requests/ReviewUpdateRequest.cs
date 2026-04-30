namespace Spotter.Model.Requests
{
    public class ReviewUpdateRequest
    {
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
