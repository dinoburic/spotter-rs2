using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public partial class SpotterDbContext : DbContext
    {
        private void CreateConfiguration(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<City>(entity =>
            {
                entity.Property(c => c.Name).IsRequired().HasMaxLength(100);
                entity.Property(c => c.Country).IsRequired().HasMaxLength(100);
            });

            modelBuilder.Entity<Category>(entity =>
            {
                entity.Property(c => c.Name).IsRequired().HasMaxLength(100);
                entity.Property(c => c.ColorHex).IsRequired().HasMaxLength(20);
                entity.Property(c => c.IconSlug).IsRequired().HasMaxLength(100);
            });

            modelBuilder.Entity<Badge>(entity =>
            {
                entity.Property(b => b.Name).IsRequired().HasMaxLength(100);
                entity.Property(b => b.Description).IsRequired().HasMaxLength(500);
                entity.Property(b => b.IconUrl).HasMaxLength(500);
            });

            modelBuilder.Entity<SystemSetting>(entity =>
            {
                entity.Property(ss => ss.Key).IsRequired().HasMaxLength(100);
                entity.Property(ss => ss.Value).IsRequired().HasMaxLength(2000);
                entity.HasIndex(ss => ss.Key).IsUnique();
            });

            modelBuilder.Entity<User>(entity =>
            {
                entity.Property(u => u.FirstName).IsRequired().HasMaxLength(50);
                entity.Property(u => u.LastName).IsRequired().HasMaxLength(50);
                entity.Property(u => u.Email).IsRequired().HasMaxLength(100);
                entity.Property(u => u.Username).IsRequired().HasMaxLength(100);
                entity.Property(u => u.PhoneNumber).HasMaxLength(20);
                entity.Property(u => u.AvatarUrl).HasMaxLength(500);
                entity.Property(u => u.SpotterPointsBalance).HasDefaultValue(0);
                entity.Property(u => u.IsDeleted).HasDefaultValue(false);
                entity.HasOne(u => u.City)
                    .WithMany()
                    .HasForeignKey(u => u.CityId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Role>(entity =>
            {
                entity.Property(r => r.Name).IsRequired().HasMaxLength(50);
                entity.Property(r => r.Description).HasMaxLength(200);
            });

            modelBuilder.Entity<UserRole>(entity =>
            {
                entity.HasOne(ur => ur.User)
                    .WithMany(u => u.UserRoles)
                    .HasForeignKey(ur => ur.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(ur => ur.Role)
                    .WithMany(r => r.UserRoles)
                    .HasForeignKey(ur => ur.RoleId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<RefreshToken>(entity =>
            {
                entity.Property(rt => rt.Token).IsRequired().HasMaxLength(500);
                entity.HasOne(rt => rt.User)
                    .WithMany(u => u.RefreshTokens)
                    .HasForeignKey(rt => rt.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Venue>(entity =>
            {
                entity.Property(v => v.Name).IsRequired().HasMaxLength(200);
                entity.Property(v => v.Address).IsRequired().HasMaxLength(500);
                entity.Property(v => v.Latitude).HasColumnType("decimal(10,7)");
                entity.Property(v => v.Longitude).HasColumnType("decimal(10,7)");
                entity.Property(v => v.GeocodingPending).HasDefaultValue(false);
                entity.HasOne(v => v.City)
                    .WithMany()
                    .HasForeignKey(v => v.CityId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Event>(entity =>
            {
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
                entity.Property(e => e.Description).IsRequired().HasMaxLength(2000);
                entity.Property(e => e.CoverImageUrl).HasMaxLength(500);
                entity.Property(e => e.Status).HasDefaultValue(EventStatus.Draft);
                entity.Property(e => e.IsDeleted).HasDefaultValue(false);
                entity.HasOne(e => e.Category)
                    .WithMany()
                    .HasForeignKey(e => e.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Organizer)
                    .WithMany()
                    .HasForeignKey(e => e.OrganizerId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Venue)
                    .WithMany()
                    .HasForeignKey(e => e.VenueId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<EventTag>(entity =>
            {
                entity.Property(et => et.Tag).IsRequired().HasMaxLength(50);
                entity.HasOne(et => et.Event)
                    .WithMany(e => e.Tags)
                    .HasForeignKey(et => et.EventId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<TicketType>(entity =>
            {
                entity.Property(tt => tt.Name).IsRequired().HasMaxLength(100);
                entity.Property(tt => tt.Price).HasColumnType("decimal(10,2)");
                entity.Property(tt => tt.SoldQuantity).HasDefaultValue(0);
                entity.HasOne(tt => tt.Event)
                    .WithMany(e => e.TicketTypes)
                    .HasForeignKey(tt => tt.EventId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Order>(entity =>
            {
                entity.Property(o => o.TotalAmount).HasColumnType("decimal(10,2)");
                entity.Property(o => o.DiscountApplied).HasColumnType("decimal(10,2)").HasDefaultValue(0m);
                entity.Property(o => o.SpotterPointsRedeemed).HasDefaultValue(0);
                entity.Property(o => o.StripePaymentIntentId).HasMaxLength(200);
                entity.Property(o => o.StripeCheckoutSessionId).HasMaxLength(200);
                entity.HasOne(o => o.User)
                    .WithMany()
                    .HasForeignKey(o => o.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(o => o.Event)
                    .WithMany()
                    .HasForeignKey(o => o.EventId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<OrderItem>(entity =>
            {
                entity.Property(oi => oi.UnitPrice).HasColumnType("decimal(10,2)");
                entity.HasOne(oi => oi.Order)
                    .WithMany(o => o.OrderItems)
                    .HasForeignKey(oi => oi.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(oi => oi.TicketType)
                    .WithMany()
                    .HasForeignKey(oi => oi.TicketTypeId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Ticket>(entity =>
            {
                entity.Property(t => t.QrCodePayload).IsRequired().HasMaxLength(500);
                entity.HasIndex(t => t.QrCodePayload).IsUnique();
                entity.HasOne(t => t.OrderItem)
                    .WithMany(oi => oi.Tickets)
                    .HasForeignKey(t => t.OrderItemId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(t => t.User)
                    .WithMany()
                    .HasForeignKey(t => t.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<WaitlistEntry>(entity =>
            {
                entity.Property(we => we.Notified).HasDefaultValue(false);
                entity.HasOne(we => we.User)
                    .WithMany()
                    .HasForeignKey(we => we.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(we => we.Event)
                    .WithMany()
                    .HasForeignKey(we => we.EventId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(we => we.TicketType)
                    .WithMany()
                    .HasForeignKey(we => we.TicketTypeId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Reservation>(entity =>
            {
                entity.Property(r => r.AuditNote).HasMaxLength(1000);
                entity.Property(r => r.IsDeleted).HasDefaultValue(false);
                entity.HasOne(r => r.User)
                    .WithMany()
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(r => r.Event)
                    .WithMany()
                    .HasForeignKey(r => r.EventId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(r => r.Order)
                    .WithMany()
                    .HasForeignKey(r => r.OrderId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(r => r.ApprovedBy)
                    .WithMany()
                    .HasForeignKey(r => r.ApprovedByUserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Review>(entity =>
            {
                entity.Property(r => r.Comment).HasMaxLength(1000);
                entity.Property(r => r.IsDeleted).HasDefaultValue(false);
                entity.HasOne(r => r.User)
                    .WithMany()
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(r => r.Event)
                    .WithMany()
                    .HasForeignKey(r => r.EventId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Notification>(entity =>
            {
                entity.Property(n => n.Title).IsRequired().HasMaxLength(200);
                entity.Property(n => n.Body).IsRequired().HasMaxLength(1000);
                entity.Property(n => n.IsRead).HasDefaultValue(false);
                entity.HasOne(n => n.User)
                    .WithMany()
                    .HasForeignKey(n => n.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Favorite>(entity =>
            {
                entity.HasIndex(f => new { f.UserId, f.EventId }).IsUnique();
                entity.HasOne(f => f.User)
                    .WithMany()
                    .HasForeignKey(f => f.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(f => f.Event)
                    .WithMany()
                    .HasForeignKey(f => f.EventId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Friendship>(entity =>
            {
                entity.HasIndex(f => new { f.RequesterId, f.AddresseeId }).IsUnique();
                entity.HasOne(f => f.Requester)
                    .WithMany()
                    .HasForeignKey(f => f.RequesterId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(f => f.Addressee)
                    .WithMany()
                    .HasForeignKey(f => f.AddresseeId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<SpotterPoints>(entity =>
            {
                entity.HasOne(sp => sp.User)
                    .WithMany()
                    .HasForeignKey(sp => sp.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<UserBadge>(entity =>
            {
                entity.HasOne(ub => ub.User)
                    .WithMany()
                    .HasForeignKey(ub => ub.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(ub => ub.Badge)
                    .WithMany()
                    .HasForeignKey(ub => ub.BadgeId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<UserInterest>(entity =>
            {
                entity.HasIndex(ui => new { ui.UserId, ui.CategoryId }).IsUnique();
                entity.HasOne(ui => ui.User)
                    .WithMany()
                    .HasForeignKey(ui => ui.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(ui => ui.Category)
                    .WithMany()
                    .HasForeignKey(ui => ui.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Recommendation>(entity =>
            {
                entity.Property(r => r.Reason).IsRequired().HasMaxLength(500);
                entity.HasOne(r => r.User)
                    .WithMany()
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(r => r.Event)
                    .WithMany()
                    .HasForeignKey(r => r.EventId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<InvalidatedToken>(entity =>
            {
                entity.Property(it => it.TokenJti).IsRequired().HasMaxLength(200);
                entity.HasIndex(it => it.TokenJti).IsUnique();
                entity.HasOne(it => it.User)
                    .WithMany()
                    .HasForeignKey(it => it.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Cart>(entity =>
            {
                entity.HasOne(c => c.User)
                    .WithMany()
                    .HasForeignKey(c => c.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<CartItem>(entity =>
            {
                entity.HasOne(ci => ci.Cart)
                    .WithMany(c => c.CartItems)
                    .HasForeignKey(ci => ci.CartId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Event>().HasIndex(e => e.CategoryId);
            modelBuilder.Entity<Event>().HasIndex(e => e.OrganizerId);
            modelBuilder.Entity<Event>().HasIndex(e => e.VenueId);
            modelBuilder.Entity<Event>().HasIndex(e => e.StartsAt);
            modelBuilder.Entity<Event>().HasIndex(e => e.Status);
            modelBuilder.Entity<Event>().HasIndex(e => e.IsDeleted);

            modelBuilder.Entity<Order>().HasIndex(o => o.UserId);
            modelBuilder.Entity<Order>().HasIndex(o => o.EventId);
            modelBuilder.Entity<Order>().HasIndex(o => o.Status);
            modelBuilder.Entity<Order>().HasIndex(o => o.StripePaymentIntentId);

            modelBuilder.Entity<Ticket>().HasIndex(t => t.UserId);
            modelBuilder.Entity<Ticket>().HasIndex(t => t.OrderItemId);
            modelBuilder.Entity<Ticket>().HasIndex(t => t.Status);

            modelBuilder.Entity<WaitlistEntry>().HasIndex(we => we.UserId);
            modelBuilder.Entity<WaitlistEntry>().HasIndex(we => new { we.EventId, we.TicketTypeId, we.Position });

            modelBuilder.Entity<Reservation>().HasIndex(r => r.UserId);
            modelBuilder.Entity<Reservation>().HasIndex(r => r.EventId);
            modelBuilder.Entity<Reservation>().HasIndex(r => r.Status);

            modelBuilder.Entity<Review>().HasIndex(r => r.UserId);
            modelBuilder.Entity<Review>().HasIndex(r => r.EventId);

            modelBuilder.Entity<Notification>().HasIndex(n => n.UserId);
            modelBuilder.Entity<Notification>().HasIndex(n => n.IsRead);

            modelBuilder.Entity<SpotterPoints>().HasIndex(sp => sp.UserId);
            modelBuilder.Entity<SpotterPoints>().HasIndex(sp => sp.CreatedAt);

            modelBuilder.Entity<Recommendation>().HasIndex(r => r.UserId);
            modelBuilder.Entity<Recommendation>().HasIndex(r => r.GeneratedAt);

            modelBuilder.Entity<RefreshToken>().HasIndex(rt => rt.UserId);
            modelBuilder.Entity<RefreshToken>().HasIndex(rt => rt.Token);

            modelBuilder.Entity<InvalidatedToken>().HasIndex(it => it.ExpiresAt);

            modelBuilder.Entity<EventTag>().HasIndex(et => et.EventId);
        }
    }
}
