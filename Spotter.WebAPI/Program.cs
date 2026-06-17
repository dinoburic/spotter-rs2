using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Scalar.AspNetCore;
using Spotter.Common.Services.CryptoService;
using Spotter.Model.Access;
using Spotter.Model.Requests;
using Spotter.Model.Responses;
using Spotter.Services;
using Spotter.Services.Database;
using Spotter.Services.QueryOptimization;
using Spotter.Services.StateMachines;
using Spotter.Services.Validators;
using Spotter.WebAPI.Filters;
using System.Text;

if (!string.Equals(Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER"), "true", StringComparison.OrdinalIgnoreCase))
{
    DotNetEnv.Env.TraversePath().Load();
}

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(
   options => options.Filters.Add<ExceptionFilter>()
);

var configuredConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var connectionString = !string.IsNullOrWhiteSpace(configuredConnectionString)
    ? configuredConnectionString
    : Environment.GetEnvironmentVariable("SPOTTER_CONNECTION_STRING");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("Connection string not configured.");
}

builder.Services.AddDbContext<SpotterDbContext>(options =>
    options.UseSqlServer(connectionString)
);

builder.Services.AddMapster();

TypeAdapterConfig<Category, CategoryResponse>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<User, UserResponse>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<UserUpdateRequest, User>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<Venue, VenueResponse>.NewConfig()
    .Map(dest => dest.CityName, src => src.City != null ? src.City.Name : string.Empty);

TypeAdapterConfig<Event, EventResponse>.NewConfig()
    .Map(dest => dest.CategoryName, src => src.Category != null ? src.Category.Name : string.Empty)
    .Map(dest => dest.CategoryColorHex, src => src.Category != null ? src.Category.ColorHex : string.Empty)
    .Map(dest => dest.VenueName, src => src.Venue != null ? src.Venue.Name : string.Empty)
    .Map(dest => dest.VenueAddress, src => src.Venue != null ? src.Venue.Address : null)
    .Map(dest => dest.VenueLatitude, src => src.Venue != null ? src.Venue.Latitude : null)
    .Map(dest => dest.VenueLongitude, src => src.Venue != null ? src.Venue.Longitude : null)
    .Map(dest => dest.VenueGeocodingPending, src => src.Venue != null && src.Venue.GeocodingPending)
    .Map(dest => dest.CityId, src => src.Venue != null && src.Venue.City != null ? src.Venue.City.Id : 0)
    .Map(dest => dest.CityName, src => src.Venue != null && src.Venue.City != null ? src.Venue.City.Name : string.Empty)
    .Map(dest => dest.OrganizerName, src => src.Organizer != null ? src.Organizer.FirstName + " " + src.Organizer.LastName : string.Empty)
    .Map(dest => dest.StatusName, src => src.Status.ToString())
    .Map(dest => dest.AvailableCapacity, src => src.TotalCapacity - (src.TicketTypes != null ? src.TicketTypes.Sum(tt => tt.SoldQuantity) : 0));

TypeAdapterConfig<TicketType, TicketTypeResponse>.NewConfig()
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.TypeName, src => src.TypeEnum.ToString())
    .Map(dest => dest.AvailableQuantity, src => src.TotalQuantity - src.SoldQuantity);

TypeAdapterConfig<Order, OrderResponse>.NewConfig()
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.UserFullName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty)
    .Map(dest => dest.StatusName, src => src.Status.ToString())
    .Map(dest => dest.Items, src => src.OrderItems);

TypeAdapterConfig<OrderItem, OrderItemResponse>.NewConfig()
    .Map(dest => dest.TicketTypeName, src => src.TicketType != null ? src.TicketType.Name : string.Empty)
    .Map(dest => dest.TypeName, src => src.TicketType != null ? src.TicketType.TypeEnum.ToString() : string.Empty)
    .Map(dest => dest.Subtotal, src => src.Quantity * src.UnitPrice);

TypeAdapterConfig<Ticket, TicketResponse>.NewConfig()
    .Map(dest => dest.UserFullName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty)
    .Map(dest => dest.EventId, src => src.OrderItem != null && src.OrderItem.Order != null ? src.OrderItem.Order.EventId : 0)
    .Map(dest => dest.EventTitle, src => src.OrderItem != null && src.OrderItem.Order != null && src.OrderItem.Order.Event != null ? src.OrderItem.Order.Event.Title : string.Empty)
    .Map(dest => dest.TicketTypeName, src => src.OrderItem != null && src.OrderItem.TicketType != null ? src.OrderItem.TicketType.Name : string.Empty)
    .Map(dest => dest.TypeName, src => src.OrderItem != null && src.OrderItem.TicketType != null ? src.OrderItem.TicketType.TypeEnum.ToString() : string.Empty)
    .Map(dest => dest.StatusName, src => src.Status.ToString());

TypeAdapterConfig<Review, ReviewResponse>.NewConfig()
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.UserFullName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty);

TypeAdapterConfig<Favorite, FavoriteResponse>.NewConfig()
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.EventCoverImageUrl, src => src.Event != null ? src.Event.CoverImageUrl : null)
    .Map(dest => dest.CategoryName, src => src.Event != null && src.Event.Category != null ? src.Event.Category.Name : string.Empty)
    .Map(dest => dest.CategoryColorHex, src => src.Event != null && src.Event.Category != null ? src.Event.Category.ColorHex : "#7C3AED")
    .Map(dest => dest.VenueName, src => src.Event != null && src.Event.Venue != null ? src.Event.Venue.Name : string.Empty)
    .Map(dest => dest.CityName, src => src.Event != null && src.Event.Venue != null && src.Event.Venue.City != null ? src.Event.Venue.City.Name : null)
    .Map(dest => dest.EventStartsAt, src => src.Event != null ? src.Event.StartsAt : default);

TypeAdapterConfig<Friendship, FriendshipResponse>.NewConfig()
    .Map(dest => dest.RequesterName, src => src.Requester != null ? src.Requester.FirstName + " " + src.Requester.LastName : string.Empty)
    .Map(dest => dest.AddresseeName, src => src.Addressee != null ? src.Addressee.FirstName + " " + src.Addressee.LastName : string.Empty)
    .Map(dest => dest.StatusName, src => src.Status.ToString());

TypeAdapterConfig<Notification, NotificationResponse>.NewConfig()
    .Map(dest => dest.TypeName, src => src.Type.ToString())
    .Map(dest => dest.ReferenceId, src => src.ReferenceId.HasValue ? src.ReferenceId.Value.ToString() : null);

TypeAdapterConfig<Reservation, ReservationResponse>.NewConfig()
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.UserFullName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty)
    .Map(dest => dest.StatusName, src => src.Status.ToString())
    .Map(dest => dest.ApprovedByName, src => src.ApprovedBy != null ? src.ApprovedBy.FirstName + " " + src.ApprovedBy.LastName : null);

TypeAdapterConfig<SpotterPoints, SpotterPointsResponse>.NewConfig()
    .Map(dest => dest.SourceName, src => src.Source.ToString())
    .Map(dest => dest.ReferenceId, src => src.ReferenceId.HasValue ? src.ReferenceId.Value.ToString() : null);

TypeAdapterConfig<Badge, BadgeResponse>.NewConfig();

TypeAdapterConfig<UserBadge, UserBadgeResponse>.NewConfig()
    .Map(dest => dest.BadgeName, src => src.Badge != null ? src.Badge.Name : string.Empty)
    .Map(dest => dest.BadgeDescription, src => src.Badge != null ? src.Badge.Description : string.Empty)
    .Map(dest => dest.BadgeIconUrl, src => src.Badge != null ? src.Badge.IconUrl : null);

TypeAdapterConfig<WaitlistEntry, WaitlistEntryResponse>.NewConfig()
    .Map(dest => dest.UserFullName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : string.Empty)
    .Map(dest => dest.EventTitle, src => src.Event != null ? src.Event.Title : string.Empty)
    .Map(dest => dest.TicketTypeName, src => src.TicketType != null ? src.TicketType.Name : string.Empty);

builder.Services.AddSignalR();

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<IAccessService, AccessService>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IQueryOptimizationService, QueryOptimizationService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IVenueService, VenueService>();
builder.Services.AddScoped<IEventService, EventService>();
builder.Services.AddScoped<ITicketTypeService, TicketTypeService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ITicketService, TicketService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();
builder.Services.AddScoped<IFriendshipService, FriendshipService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<ISpotterPointsService, SpotterPointsService>();
builder.Services.AddScoped<IBadgeService, BadgeService>();
builder.Services.AddScoped<IWaitlistService, WaitlistService>();
builder.Services.AddScoped<IStripeService, StripeService>();
builder.Services.AddSingleton<IRabbitMqPublisher, RabbitMqPublisher>();
builder.Services.AddScoped<IRecommendationService, RecommendationService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddHostedService<RecommendationTrainingService>();
builder.Services.AddHostedService<PendingOrderExpirationService>();

builder.Services.AddScoped<EventStateMachine>();
builder.Services.AddScoped<OrderStateMachine>();
builder.Services.AddScoped<TicketStateMachine>();
builder.Services.AddScoped<ReservationStateMachine>();

builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<UserLoginRequest>, LoginRequestValidator>();
builder.Services.AddScoped<IValidator<RegisterRequest>, RegisterRequestValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertRequestValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<CategoryInsertRequest>, CategoryInsertRequestValidator>();
builder.Services.AddScoped<IValidator<CategoryUpdateRequest>, CategoryUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<VenueInsertRequest>, VenueInsertRequestValidator>();
builder.Services.AddScoped<IValidator<VenueUpdateRequest>, VenueUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<EventInsertRequest>, EventInsertRequestValidator>();
builder.Services.AddScoped<IValidator<EventUpdateRequest>, EventUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<TicketTypeInsertRequest>, TicketTypeInsertRequestValidator>();
builder.Services.AddScoped<IValidator<TicketTypeUpdateRequest>, TicketTypeUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<OrderInsertRequest>, OrderInsertRequestValidator>();
builder.Services.AddScoped<IValidator<ReviewInsertRequest>, ReviewInsertRequestValidator>();
builder.Services.AddScoped<IValidator<ReviewUpdateRequest>, ReviewUpdateRequestValidator>();
builder.Services.AddScoped<IValidator<ReservationInsertRequest>, ReservationInsertRequestValidator>();
builder.Services.AddScoped<IValidator<WaitlistJoinRequest>, WaitlistJoinRequestValidator>();
builder.Services.AddScoped<IValidator<ChangePasswordRequest>, ChangePasswordValidator>();

builder.Services.AddOpenApi();

var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? builder.Configuration["JWT_SECRET"]
    ?? throw new InvalidOperationException("JWT Secret not configured.");

var jwtIssuer = builder.Configuration["Jwt:Issuer"]
    ?? builder.Configuration["JWT_ISSUER"]
    ?? throw new InvalidOperationException("JWT Issuer not configured.");

var jwtAudience = builder.Configuration["Jwt:Audience"]
    ?? builder.Configuration["JWT_AUDIENCE"]
    ?? throw new InvalidOperationException("JWT Audience not configured.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
    o.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        },
        OnTokenValidated = async context =>
        {
            var jti = context.Principal?.FindFirst("jti")?.Value;
            if (!string.IsNullOrEmpty(jti))
            {
                var dbContext = context.HttpContext.RequestServices.GetRequiredService<SpotterDbContext>();
                var isInvalidated = await dbContext.InvalidatedTokens.AnyAsync(t => t.TokenJti == jti);
                if (isInvalidated)
                {
                    context.Fail("Token has been invalidated.");
                }
            }
        }
    };
});
builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("SpotterPolicy", policy =>
    {
        policy.WithOrigins("http://localhost:5126", "http://10.0.2.2:5126", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(
    options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Version = "v1",
            Title = "Spotter API",
            Description = "API for managing the Spotter application"
        });

        var jwtSecurityScheme = new OpenApiSecurityScheme
        {
            BearerFormat = "JWT",
            Name = "JWT Authentication",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = JwtBearerDefaults.AuthenticationScheme,
            Reference = new OpenApiReference
            {
                Id = JwtBearerDefaults.AuthenticationScheme,
                Type = ReferenceType.SecurityScheme
            }
        };

        options.AddSecurityDefinition(jwtSecurityScheme.Reference.Id, jwtSecurityScheme);
        options.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
            { jwtSecurityScheme, Array.Empty<string>() }
        });
    });

TypeAdapterConfig<User, UserResponse>.NewConfig()
    .Map(dest => dest.Role, src => src.UserRoles != null && src.UserRoles.Any()
        ? src.UserRoles.First().Role.Name
        : string.Empty)
    .Map(dest => dest.CityName, src => src.City != null ? src.City.Name : string.Empty);

var app = builder.Build();

await InitializeDatabaseAsync(app, connectionString);

app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api/payments/webhook"))
    {
        context.Request.EnableBuffering();
    }
    await next();
});

app.MapOpenApi();
app.MapScalarApiReference();
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("SpotterPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<Spotter.Services.Hubs.NotificationHub>("/hubs/notifications");

app.Run();

static async Task InitializeDatabaseAsync(WebApplication app, string connectionString)
{
    await using var scope = app.Services.CreateAsyncScope();
    var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("DatabaseStartup");
    var dbContext = scope.ServiceProvider.GetRequiredService<SpotterDbContext>();
    var target = GetDatabaseTarget(connectionString);

    logger.LogInformation("Using SQL Server database target {Server}/{Database}", target.Server, target.Database);

    try
    {
        await EnsureDatabaseExistsAsync(connectionString);
        await dbContext.Database.MigrateAsync();

        var seededUsers = await dbContext.Users
            .Where(user => user.Username == "desktop" || user.Username == "mobile")
            .Select(user => user.Username)
            .ToListAsync();

        logger.LogInformation(
            "Database migrations applied. Seeded seminar users present: {Users}",
            seededUsers.Count > 0 ? string.Join(", ", seededUsers) : "none");
    }
    catch (SqlException ex) when (ex.Number == 4060)
    {
        logger.LogCritical(ex, "SQL Server is reachable at {Server}, but database {Database} could not be opened. Check that migrations can create it and that the login has access.", target.Server, target.Database);
        throw;
    }
    catch (SqlException ex) when (ex.Number == 18456)
    {
        logger.LogCritical(ex, "SQL Server login failed for database target {Server}/{Database}. Check the configured username and password.", target.Server, target.Database);
        throw;
    }
    catch (SqlException ex) when (ex.Number is -1 or 53)
    {
        logger.LogCritical(ex, "SQL Server is unreachable at {Server}. In Docker use 'sqlserver,1433'; from Windows use 'localhost,1435'.", target.Server);
        throw;
    }
    catch (SqlException ex)
    {
        logger.LogCritical(ex, "Failed to initialize SQL Server database target {Server}/{Database}. SQL error number: {Number}", target.Server, target.Database, ex.Number);
        throw;
    }
}

static (string Server, string Database) GetDatabaseTarget(string connectionString)
{
    var builder = new SqlConnectionStringBuilder(connectionString);
    return (builder.DataSource, builder.InitialCatalog);
}

static async Task EnsureDatabaseExistsAsync(string connectionString)
{
    var builder = new SqlConnectionStringBuilder(connectionString);
    var databaseName = builder.InitialCatalog;

    if (string.IsNullOrWhiteSpace(databaseName))
    {
        throw new InvalidOperationException("Connection string must include a database name.");
    }

    builder.InitialCatalog = "master";

    await using var connection = new SqlConnection(builder.ConnectionString);
    await connection.OpenAsync();

    await using var command = connection.CreateCommand();
    command.CommandText = $"IF DB_ID(@databaseName) IS NULL CREATE DATABASE {QuoteSqlIdentifier(databaseName)};";
    command.Parameters.AddWithValue("@databaseName", databaseName);
    await command.ExecuteNonQueryAsync();
}

static string QuoteSqlIdentifier(string value)
{
    return $"[{value.Replace("]", "]]")}]";
}
