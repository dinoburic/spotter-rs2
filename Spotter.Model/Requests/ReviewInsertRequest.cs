namespace Spotter.Model.Requests
{
    public class ReviewInsertRequest
    {
        public int EventId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
    }
}
