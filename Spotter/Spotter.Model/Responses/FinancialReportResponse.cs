namespace Spotter.Model.Responses
{
    public class FinancialReportResponse
    {
        public decimal TotalRevenue { get; set; }
        public int TotalOrders { get; set; }
        public int TotalTicketsSold { get; set; }
        public List<FinancialOrderItem> Orders { get; set; } = new();
    }

    public class FinancialOrderItem
    {
        public int OrderId { get; set; }
        public string EventTitle { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime CreatedAt { get; set; }
        public int TicketCount { get; set; }
    }
}
