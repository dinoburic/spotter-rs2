using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Spotter.Model.Enums;
using Spotter.Model.Exceptions;
using Spotter.Model.Responses;
using Spotter.Model.SearchObjects;
using Spotter.Services.Database;

namespace Spotter.Services
{
    public class FriendshipService : IFriendshipService
    {
        private readonly SpotterDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationService _notificationService;
        private readonly ILogger<FriendshipService> _logger;

        public FriendshipService(
            SpotterDbContext dbContext,
            IMapper mapper,
            ICurrentUserService currentUserService,
            INotificationService notificationService,
            ILogger<FriendshipService> logger)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _currentUserService = currentUserService;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<PageResult<FriendshipResponse>> GetMyFriendshipsAsync(FriendshipSearch? search = null)
        {
            var userId = _currentUserService.GetUserId();

            var query = _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .Where(f => f.RequesterId == userId || f.AddresseeId == userId)
                .AsQueryable();

            if (search != null)
            {
                if (search.Status.HasValue)
                    query = query.Where(f => f.Status == search.Status.Value);
            }

            var page = search?.Page ?? 1;
            var pageSize = Math.Min(search?.PageSize ?? 20, 100);

            int? totalCount = null;
            if (search?.IncludeTotalCount ?? false)
            {
                totalCount = await query.CountAsync();
            }

            var friendships = await query
                .OrderByDescending(f => f.RequestedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<FriendshipResponse>
            {
                Items = friendships.Select(f => _mapper.Map<FriendshipResponse>(f)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<FriendshipResponse> SendRequestAsync(int addresseeId)
        {
            var userId = _currentUserService.GetUserId();
            _logger.LogInformation("User {UserId} sending friend request to {AddresseeId}", userId, addresseeId);

            if (addresseeId == userId)
                throw new ClientException("You cannot send a friend request to yourself.");

            var addresseeExists = await _dbContext.Users.AnyAsync(u => u.Id == addresseeId && !u.IsDeleted);
            if (!addresseeExists)
                throw new NotFoundException("User not found.");

            var exists = await _dbContext.Friendships.AnyAsync(f =>
                (f.RequesterId == userId && f.AddresseeId == addresseeId) ||
                (f.RequesterId == addresseeId && f.AddresseeId == userId));

            if (exists)
                throw new ClientException("A friendship request already exists between these users.");

            var friendship = new Friendship
            {
                RequesterId = userId,
                AddresseeId = addresseeId,
                Status = FriendshipStatus.Pending,
                RequestedAt = DateTime.UtcNow
            };

            _dbContext.Friendships.Add(friendship);
            await _dbContext.SaveChangesAsync();

            var createdFriendship = await _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .FirstAsync(f => f.Id == friendship.Id);

            var requesterFullName = createdFriendship.Requester.FirstName + " " + createdFriendship.Requester.LastName;
            await _notificationService.CreateAsync(
                userId: addresseeId,
                title: "New Friend Request",
                body: $"{requesterFullName} sent you a friend request.",
                type: NotificationType.General,
                referenceId: friendship.Id.ToString()
            );

            _logger.LogInformation("Friend request {FriendshipId} sent successfully", friendship.Id);
            return _mapper.Map<FriendshipResponse>(createdFriendship);
        }

        public async Task<FriendshipResponse> AcceptAsync(int friendshipId)
        {
            _logger.LogInformation("Accepting friendship {FriendshipId}", friendshipId);
            var friendship = await _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .FirstOrDefaultAsync(f => f.Id == friendshipId);

            if (friendship == null)
            {
                _logger.LogWarning("Friendship {FriendshipId} not found", friendshipId);
                throw new NotFoundException("Friendship not found.");
            }

            if (friendship.AddresseeId != _currentUserService.GetUserId())
                throw new ClientException("Only the recipient can accept a friend request.");

            if (friendship.Status != FriendshipStatus.Pending)
                throw new ClientException("Only pending requests can be accepted.");

            friendship.Status = FriendshipStatus.Accepted;
            friendship.RespondedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            var addresseeFullName = friendship.Addressee.FirstName + " " + friendship.Addressee.LastName;
            await _notificationService.CreateAsync(
                userId: friendship.RequesterId,
                title: "Friend Request Accepted",
                body: $"{addresseeFullName} accepted your friend request.",
                type: NotificationType.General,
                referenceId: friendship.Id.ToString()
            );

            _logger.LogInformation("Friendship {FriendshipId} accepted successfully", friendshipId);
            return _mapper.Map<FriendshipResponse>(friendship);
        }

        public async Task<FriendshipResponse> RejectAsync(int friendshipId)
        {
            _logger.LogInformation("Rejecting friendship {FriendshipId}", friendshipId);
            var friendship = await _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .FirstOrDefaultAsync(f => f.Id == friendshipId);

            if (friendship == null)
            {
                _logger.LogWarning("Friendship {FriendshipId} not found", friendshipId);
                throw new NotFoundException("Friendship not found.");
            }

            if (friendship.AddresseeId != _currentUserService.GetUserId())
                throw new ClientException("Only the recipient can reject a friend request.");

            if (friendship.Status != FriendshipStatus.Pending)
                throw new ClientException("Only pending requests can be rejected.");

            friendship.Status = FriendshipStatus.Rejected;
            friendship.RespondedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Friendship {FriendshipId} rejected", friendshipId);

            return _mapper.Map<FriendshipResponse>(friendship);
        }

        public async Task<FriendshipResponse> BlockAsync(int friendshipId)
        {
            _logger.LogInformation("Blocking friendship {FriendshipId}", friendshipId);
            var friendship = await _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .FirstOrDefaultAsync(f => f.Id == friendshipId);

            if (friendship == null)
            {
                _logger.LogWarning("Friendship {FriendshipId} not found", friendshipId);
                throw new NotFoundException("Friendship not found.");
            }

            var userId = _currentUserService.GetUserId();
            if (friendship.RequesterId != userId && friendship.AddresseeId != userId)
                throw new ForbiddenException("Access denied.");

            friendship.Status = FriendshipStatus.Blocked;
            friendship.RespondedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<FriendshipResponse>(friendship);
        }

        public async Task DeleteAsync(int friendshipId)
        {
            _logger.LogInformation("Deleting friendship {FriendshipId}", friendshipId);
            var friendship = await _dbContext.Friendships.FirstOrDefaultAsync(f => f.Id == friendshipId);

            if (friendship == null)
            {
                _logger.LogWarning("Friendship {FriendshipId} not found", friendshipId);
                throw new NotFoundException("Friendship not found.");
            }

            var userId = _currentUserService.GetUserId();
            if (friendship.RequesterId != userId && friendship.AddresseeId != userId)
                throw new ForbiddenException("Access denied.");

            _dbContext.Friendships.Remove(friendship);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<PageResult<UserSuggestionResponse>> GetFriendsAsync(int page = 1, int pageSize = 20)
        {
            var userId = _currentUserService.GetUserId();
            pageSize = Math.Min(pageSize, 100);

            var query = _dbContext.Friendships
                .Include(f => f.Requester).ThenInclude(u => u.City)
                .Include(f => f.Addressee).ThenInclude(u => u.City)
                .Where(f => f.Status == FriendshipStatus.Accepted &&
                           (f.RequesterId == userId || f.AddresseeId == userId));

            var totalCount = await query.CountAsync();

            var friendships = await query
                .OrderByDescending(f => f.RespondedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = friendships.Select(f =>
            {
                var friend = f.RequesterId == userId ? f.Addressee : f.Requester;
                return new UserSuggestionResponse
                {
                    UserId = friend.Id,
                    FullName = $"{friend.FirstName} {friend.LastName}",
                    Username = friend.Username,
                    CityName = friend.City?.Name,
                    MutualFriendsCount = 0
                };
            }).ToList();

            return new PageResult<UserSuggestionResponse>
            {
                Items = items,
                TotalCount = totalCount
            };
        }

        public async Task<PageResult<FriendshipResponse>> GetPendingRequestsAsync(int page = 1, int pageSize = 20)
        {
            var userId = _currentUserService.GetUserId();
            pageSize = Math.Min(pageSize, 100);

            var query = _dbContext.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .Where(f => f.Status == FriendshipStatus.Pending && f.AddresseeId == userId);

            var totalCount = await query.CountAsync();

            var friendships = await query
                .OrderByDescending(f => f.RequestedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PageResult<FriendshipResponse>
            {
                Items = friendships.Select(f => _mapper.Map<FriendshipResponse>(f)).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<PageResult<UserSuggestionResponse>> GetSuggestionsAsync(int page = 1, int pageSize = 10)
        {
            var userId = _currentUserService.GetUserId();
            pageSize = Math.Min(pageSize, 100);

            var currentUser = await _dbContext.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == userId);

            var existingFriendshipUserIds = await _dbContext.Friendships
                .Where(f => f.RequesterId == userId || f.AddresseeId == userId)
                .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
                .ToListAsync();

            existingFriendshipUserIds.Add(userId);

            var myFriendIds = await _dbContext.Friendships
                .Where(f => f.Status == FriendshipStatus.Accepted &&
                           (f.RequesterId == userId || f.AddresseeId == userId))
                .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
                .ToListAsync();

            var query = _dbContext.Users
                .Include(u => u.City)
                .Where(u => !u.IsDeleted && !existingFriendshipUserIds.Contains(u.Id));

            if (currentUser?.CityId != null)
            {
                query = query.OrderByDescending(u => u.CityId == currentUser.CityId);
            }

            var totalCount = await query.CountAsync();

            var users = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userIds = users.Select(u => u.Id).ToList();

            var mutualCounts = await _dbContext.Friendships
                .Where(f => f.Status == FriendshipStatus.Accepted &&
                           (userIds.Contains(f.RequesterId) || userIds.Contains(f.AddresseeId)))
                .SelectMany(f => new[]
                {
                    new { UserId = f.RequesterId, FriendId = f.AddresseeId },
                    new { UserId = f.AddresseeId, FriendId = f.RequesterId }
                })
                .Where(x => userIds.Contains(x.UserId) && myFriendIds.Contains(x.FriendId))
                .GroupBy(x => x.UserId)
                .Select(g => new { UserId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.UserId, x => x.Count);

            var suggestions = users.Select(user => new UserSuggestionResponse
            {
                UserId = user.Id,
                FullName = $"{user.FirstName} {user.LastName}",
                Username = user.Username,
                CityName = user.City?.Name,
                MutualFriendsCount = mutualCounts.GetValueOrDefault(user.Id, 0)
            }).ToList();

            return new PageResult<UserSuggestionResponse>
            {
                Items = suggestions.OrderByDescending(s => s.MutualFriendsCount).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<PageResult<UserSuggestionResponse>> SearchUsersAsync(string query, int page = 1, int pageSize = 20)
        {
            var userId = _currentUserService.GetUserId();
            pageSize = Math.Min(pageSize, 100);

            var existingFriendshipUserIds = await _dbContext.Friendships
                .Where(f => f.RequesterId == userId || f.AddresseeId == userId)
                .Select(f => f.RequesterId == userId ? f.AddresseeId : f.RequesterId)
                .ToListAsync();

            existingFriendshipUserIds.Add(userId);

            var searchQuery = query.ToLower();
            var usersQuery = _dbContext.Users
                .Include(u => u.City)
                .Where(u => !u.IsDeleted && !existingFriendshipUserIds.Contains(u.Id) &&
                           (u.FirstName.ToLower().Contains(searchQuery) ||
                            u.LastName.ToLower().Contains(searchQuery) ||
                            u.Username.ToLower().Contains(searchQuery)));

            var totalCount = await usersQuery.CountAsync();

            var users = await usersQuery
                .OrderBy(u => u.Username)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = users.Select(u => new UserSuggestionResponse
            {
                UserId = u.Id,
                FullName = $"{u.FirstName} {u.LastName}",
                Username = u.Username,
                CityName = u.City?.Name,
                MutualFriendsCount = 0
            }).ToList();

            return new PageResult<UserSuggestionResponse>
            {
                Items = items,
                TotalCount = totalCount
            };
        }
    }
}
