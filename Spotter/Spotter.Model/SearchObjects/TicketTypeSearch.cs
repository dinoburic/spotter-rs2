using Spotter.Model.Enums;

namespace Spotter.Model.SearchObjects
{
    public class TicketTypeSearch : BaseSearchObject
    {
        public int? EventId { get; set; }
        public TicketTypeEnum? TypeEnum { get; set; }
    }
}
