using FluentValidation;
using Spotter.Model.Access;

namespace Spotter.Services.Validators
{
    public class LoginRequestValidator : AbstractValidator<UserLoginRequest>
    {
        public LoginRequestValidator()
        {
            RuleFor(x => x.Username).NotEmpty();
            RuleFor(x => x.Password).NotEmpty();
        }
    }
}
