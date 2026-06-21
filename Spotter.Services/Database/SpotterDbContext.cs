using Microsoft.EntityFrameworkCore;

namespace Spotter.Services.Database
{
    public partial class SpotterDbContext : DbContext
    {
        public SpotterDbContext(DbContextOptions<SpotterDbContext> options) : base(options)
        {
        }

        public DbSet<City> Cities { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Badge> Badges { get; set; }
        public DbSet<SystemSetting> SystemSettings { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<InvalidatedToken> InvalidatedTokens { get; set; }
        public DbSet<Venue> Venues { get; set; }
        public DbSet<Event> Events { get; set; }
        public DbSet<EventTag> EventTags { get; set; }
        public DbSet<TicketType> TicketTypes { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Ticket> Tickets { get; set; }
        public DbSet<WaitlistEntry> WaitlistEntries { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<Friendship> Friendships { get; set; }
        public DbSet<SpotterPoints> SpotterPoints { get; set; }
        public DbSet<UserBadge> UserBadges { get; set; }
        public DbSet<UserInterest> UserInterests { get; set; }
        public DbSet<Recommendation> Recommendations { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<ProcessedStripeEvent> ProcessedStripeEvents { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            CreateConfiguration(modelBuilder);
            CreateSeed(modelBuilder);
        }
    }
}
