namespace Spotter.Model.Responses
{
    public class UserInterestResponse
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string ColorHex { get; set; } = string.Empty;
    }
}
