namespace Spotter.Model.SearchObjects
{
    public class ReviewSearch : BaseSearchObject
    {
        public int? EventId { get; set; }
        public int? UserId { get; set; }
        public int? MinRating { get; set; }
    }
}
