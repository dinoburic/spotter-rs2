using Spotter.Model.Enums;

namespace Spotter.Model.Responses
{
    public class FriendshipResponse
    {
        public int Id { get; set; }
        public int RequesterId { get; set; }
        public string RequesterName { get; set; } = string.Empty;
        public int AddresseeId { get; set; }
        public string AddresseeName { get; set; } = string.Empty;
        public FriendshipStatus Status { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public DateTime RequestedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
    }
}
