using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
    {
        public RegisterRequestValidator()
        {
            RuleFor(x => x.FirstName).NotEmpty().MaximumLength(50);
            RuleFor(x => x.LastName).NotEmpty().MaximumLength(50);
            RuleFor(x => x.Username).NotEmpty().MaximumLength(100);
            RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(100);
            RuleFor(x => x.Password).NotEmpty().MinimumLength(6).MaximumLength(100);
            RuleFor(x => x.ConfirmPassword).NotEmpty().Equal(x => x.Password);
            RuleFor(x => x.CityId).GreaterThan(0);
        }
    }
}
