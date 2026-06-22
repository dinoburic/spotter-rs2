namespace Spotter.Model.Responses
{
    public class OrganizerDashboardResponse
    {
        public decimal TotalRevenue { get; set; }
        public int TotalTicketsSold { get; set; }
        public int ActiveEventsCount { get; set; }
        public int TotalEventsCount { get; set; }
        public List<MonthlyRevenueItem> MonthlyRevenue { get; set; } = new();
        public List<TopEventItem> TopEvents { get; set; } = new();
    }

    public class MonthlyRevenueItem
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public string MonthName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int TicketsSold { get; set; }
    }

    public class TopEventItem
    {
        public int EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public int TicketsSold { get; set; }
        public decimal Revenue { get; set; }
    }
}
