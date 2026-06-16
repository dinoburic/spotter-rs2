namespace Spotter.Model.Responses
{
    public class UserSuggestionResponse
    {
        public int UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string? CityName { get; set; }
        public int MutualFriendsCount { get; set; }
    }
}
