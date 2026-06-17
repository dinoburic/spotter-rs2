using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public class Friendship
    {
        public int Id { get; set; }
        public int RequesterId { get; set; }
        public User Requester { get; set; } = null!;
        public int AddresseeId { get; set; }
        public User Addressee { get; set; } = null!;
        public FriendshipStatus Status { get; set; }
        public DateTime RequestedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
    }
}
