namespace Spotter.Model.Responses
{
    public class PointsBalanceResponse
    {
        public int UserId { get; set; }
        public int Balance { get; set; }
        public int TotalEarned { get; set; }
        public int TotalRedeemed { get; set; }
    }
}
