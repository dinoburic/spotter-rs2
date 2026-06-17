using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class SpotterPointsSearch : BaseSearchObject
    {
        public PointSource? Source { get; set; }
        public int? UserId { get; set; }
    }
}
