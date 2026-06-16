using Microsoft.EntityFrameworkCore;
using Spotter.Model.Enums;

namespace Spotter.Services.Database
{
    public partial class SpotterDbContext : DbContext
    {
        private void CreateSeed(ModelBuilder modelBuilder)
        {
            SeedCities(modelBuilder);
            SeedCategories(modelBuilder);
            SeedRoles(modelBuilder);
            SeedUsers(modelBuilder);
            SeedUserRoles(modelBuilder);
            SeedBadges(modelBuilder);
            SeedVenues(modelBuilder);
            SeedEvents(modelBuilder);
            SeedTicketTypes(modelBuilder);
            SeedSystemSettings(modelBuilder);
        }

        private void SeedCities(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<City>().HasData(
                new { Id = 1, Name = "Sarajevo", Country = "Bosnia and Herzegovina" },
                new { Id = 2, Name = "Mostar", Country = "Bosnia and Herzegovina" },
                new { Id = 3, Name = "Banja Luka", Country = "Bosnia and Herzegovina" }
            );
        }

        private void SeedCategories(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Category>().HasData(
                new { Id = 1, Name = "Music", ColorHex = "#7C3AED", IconSlug = "music" },
                new { Id = 2, Name = "Sport", ColorHex = "#EA580C", IconSlug = "sport" },
                new { Id = 3, Name = "Theatre", ColorHex = "#0EA5E9", IconSlug = "theatre" },
                new { Id = 4, Name = "Education", ColorHex = "#16A34A", IconSlug = "education" },
                new { Id = 5, Name = "Food", ColorHex = "#CA8A04", IconSlug = "food" },
                new { Id = 6, Name = "Comedy", ColorHex = "#DB2777", IconSlug = "comedy" }
            );
        }

        private void SeedRoles(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Role>().HasData(
                new
                {
                    Id = 1,
                    Name = "Admin",
                    Description = "Administrator role with full permissions",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 2,
                    Name = "User",
                    Description = "Standard user role",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 3,
                    Name = "Organizer",
                    Description = "Event organizer",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                }
            );
        }

        private void SeedUsers(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasData(
                new
                {
                    Id = 1,
                    FirstName = "Desktop",
                    LastName = "Admin",
                    Email = "desktop@spotter.ba",
                    Username = "desktop",
                    PasswordHash = "bvcje+3zQBkTN8UWXobtDtIViAI=",
                    PasswordSalt = "SpotterSalt0001==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    CityId = 1,
                    AvatarUrl = (string?)null,
                    SpotterPointsBalance = 0,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null
                },
                new
                {
                    Id = 2,
                    FirstName = "Event",
                    LastName = "Organizer",
                    Email = "organizer@spotter.ba",
                    Username = "organizer",
                    PasswordHash = "wWNjgTXJRFfp0AmoARk5dlUVc5w=",
                    PasswordSalt = "SpotterSalt0002==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    CityId = 1,
                    AvatarUrl = (string?)null,
                    SpotterPointsBalance = 0,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null
                },
                new
                {
                    Id = 3,
                    FirstName = "Mobile",
                    LastName = "User",
                    Email = "mobile@spotter.ba",
                    Username = "mobile",
                    PasswordHash = "fFX7KGnDvwM570eOJrZCzJx6ohs=",
                    PasswordSalt = "SpotterSalt0003==",
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc),
                    LastLoginAt = (DateTime?)null,
                    PhoneNumber = (string?)null,
                    CityId = 2,
                    AvatarUrl = (string?)null,
                    SpotterPointsBalance = 0,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null
                }
            );
        }

        private void SeedUserRoles(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<UserRole>().HasData(
                new
                {
                    Id = 1,
                    UserId = 1,
                    RoleId = 1,
                    DateAssigned = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 2,
                    UserId = 2,
                    RoleId = 3,
                    DateAssigned = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 3,
                    UserId = 3,
                    RoleId = 2,
                    DateAssigned = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                }
            );
        }

        private void SeedBadges(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Badge>().HasData(
                new
                {
                    Id = 1,
                    Name = "Early Bird",
                    Description = "First to buy a ticket for an event",
                    IconUrl = (string?)null,
                    Criteria = 1
                },
                new
                {
                    Id = 2,
                    Name = "Music Lover",
                    Description = "Attended 5 or more music events",
                    IconUrl = (string?)null,
                    Criteria = 5
                },
                new
                {
                    Id = 3,
                    Name = "Night Owl",
                    Description = "Attended events that start after 22:00",
                    IconUrl = (string?)null,
                    Criteria = 3
                },
                new
                {
                    Id = 4,
                    Name = "Foodie",
                    Description = "Attended 3 or more food and drink events",
                    IconUrl = (string?)null,
                    Criteria = 3
                }
            );
        }

        private void SeedVenues(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Venue>().HasData(
                new
                {
                    Id = 1,
                    Name = "Arena Sarajevo",
                    Address = "Zmaja od Bosne bb, 71000 Sarajevo",
                    CityId = 1,
                    Latitude = (decimal?)43.8563m,
                    Longitude = (decimal?)18.4131m,
                    GeocodingPending = false
                },
                new
                {
                    Id = 2,
                    Name = "Mostar Sports Hall",
                    Address = "Bulevar 1 bb, 88000 Mostar",
                    CityId = 2,
                    Latitude = (decimal?)43.3438m,
                    Longitude = (decimal?)17.8078m,
                    GeocodingPending = false
                },
                new
                {
                    Id = 3,
                    Name = "Boska Banja Luka",
                    Address = "Kralja Petra I Karađorđevića 97, 78000 Banja Luka",
                    CityId = 3,
                    Latitude = (decimal?)44.7722m,
                    Longitude = (decimal?)17.1910m,
                    GeocodingPending = false
                }
            );
        }

        private void SeedEvents(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Event>().HasData(
                new
                {
                    Id = 1,
                    Title = "Rock the Night",
                    Description = "An electrifying rock concert featuring the best local and regional bands.",
                    CategoryId = 1,
                    OrganizerId = 2,
                    VenueId = 1,
                    StartsAt = new DateTime(2026, 7, 15, 20, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 7, 15, 23, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Active,
                    CoverImageUrl = "https://picsum.photos/seed/1/800/400",
                    TotalCapacity = 2000,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 2,
                    Title = "City Marathon",
                    Description = "Annual city marathon through the historic streets of Mostar.",
                    CategoryId = 2,
                    OrganizerId = 2,
                    VenueId = 2,
                    StartsAt = new DateTime(2026, 8, 20, 8, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 8, 20, 14, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Active,
                    CoverImageUrl = "https://picsum.photos/seed/2/800/400",
                    TotalCapacity = 500,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 3,
                    Title = "Hamlet",
                    Description = "Shakespeare's timeless tragedy performed by the National Theatre ensemble.",
                    CategoryId = 3,
                    OrganizerId = 2,
                    VenueId = 1,
                    StartsAt = new DateTime(2026, 9, 1, 19, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 9, 1, 22, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Draft,
                    CoverImageUrl = "https://picsum.photos/seed/3/800/400",
                    TotalCapacity = 400,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 4,
                    Title = "Tech Talk Banja Luka",
                    Description = "A full-day technology conference covering AI, cloud and modern software development.",
                    CategoryId = 4,
                    OrganizerId = 2,
                    VenueId = 3,
                    StartsAt = new DateTime(2026, 10, 25, 10, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 10, 25, 17, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Active,
                    CoverImageUrl = "https://picsum.photos/seed/4/800/400",
                    TotalCapacity = 300,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 5,
                    Title = "Street Food Festival",
                    Description = "Three days of local and international street food from over 40 vendors.",
                    CategoryId = 5,
                    OrganizerId = 2,
                    VenueId = 2,
                    StartsAt = new DateTime(2026, 11, 30, 12, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 11, 30, 20, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Active,
                    CoverImageUrl = "https://picsum.photos/seed/5/800/400",
                    TotalCapacity = 1500,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 6,
                    Title = "Stand-Up Night",
                    Description = "An evening of stand-up comedy with the funniest comedians from across the region.",
                    CategoryId = 6,
                    OrganizerId = 2,
                    VenueId = 1,
                    StartsAt = new DateTime(2026, 12, 22, 20, 0, 0, DateTimeKind.Utc),
                    EndsAt = new DateTime(2026, 12, 22, 23, 0, 0, DateTimeKind.Utc),
                    Status = EventStatus.Active,
                    CoverImageUrl = "https://picsum.photos/seed/6/800/400",
                    TotalCapacity = 600,
                    IsDeleted = false,
                    DeletedAt = (DateTime?)null,
                    CreatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                }
            );
        }

        private void SeedTicketTypes(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TicketType>().HasData(
                new { Id = 1,  EventId = 1, Name = "Regular", Price = 15.00m, TotalQuantity = 1500, SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 2,  EventId = 1, Name = "VIP",     Price = 35.00m, TotalQuantity = 500,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP },
                new { Id = 3,  EventId = 2, Name = "Regular", Price = 10.00m, TotalQuantity = 400,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 4,  EventId = 2, Name = "VIP",     Price = 25.00m, TotalQuantity = 100,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP },
                new { Id = 5,  EventId = 3, Name = "Regular", Price = 20.00m, TotalQuantity = 300,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 6,  EventId = 3, Name = "VIP",     Price = 50.00m, TotalQuantity = 100,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP },
                new { Id = 7,  EventId = 4, Name = "Regular", Price = 5.00m,  TotalQuantity = 250,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 8,  EventId = 4, Name = "VIP",     Price = 15.00m, TotalQuantity = 50,   SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP },
                new { Id = 9,  EventId = 5, Name = "Regular", Price = 8.00m,  TotalQuantity = 1200, SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 10, EventId = 5, Name = "VIP",     Price = 20.00m, TotalQuantity = 300,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP },
                new { Id = 11, EventId = 6, Name = "Regular", Price = 12.00m, TotalQuantity = 500,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.Regular },
                new { Id = 12, EventId = 6, Name = "VIP",     Price = 30.00m, TotalQuantity = 100,  SoldQuantity = 0, TypeEnum = TicketTypeEnum.VIP }
            );
        }

        private void SeedSystemSettings(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<SystemSetting>().HasData(
                new
                {
                    Id = 1,
                    Key = "AppName",
                    Value = "Spotter",
                    UpdatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                },
                new
                {
                    Id = 2,
                    Key = "DefaultCurrency",
                    Value = "BAM",
                    UpdatedAt = new DateTime(2026, 4, 26, 0, 0, 0, DateTimeKind.Utc)
                }
            );
        }
    }
}
