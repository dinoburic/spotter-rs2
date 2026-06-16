namespace Spotter.Services
{
    public interface ICurrentUserService
    {
        int GetUserId();
        string GetUsername();
        string GetRole();
        bool IsAdmin();
        bool IsInRole(string role);
    }
}
