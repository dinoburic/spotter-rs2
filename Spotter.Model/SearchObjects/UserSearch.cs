namespace Spotter.Model.SearchObjects
{
    public class UserSearch : BaseSearchObject
    {
        public string? Email { get; set; }

        public string? Username { get; set; }

        public string? Name { get; set; }

        public bool? IsActive { get; set; }
    }
}
