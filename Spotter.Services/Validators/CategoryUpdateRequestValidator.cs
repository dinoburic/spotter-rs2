using FluentValidation;
using Spotter.Model.Requests;

namespace Spotter.Services.Validators
{
    public class CategoryUpdateRequestValidator : AbstractValidator<CategoryUpdateRequest>
    {
        public CategoryUpdateRequestValidator()
        {
            RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
            RuleFor(x => x.ColorHex).NotEmpty().MaximumLength(20).Matches(@"^#[0-9A-Fa-f]{6}$");
            RuleFor(x => x.IconSlug).NotEmpty().MaximumLength(100);
        }
    }
}
