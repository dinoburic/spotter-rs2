using Spotter.Model.Exceptions;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace Spotter.WebAPI.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;

        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            int statusCode;
            string message;

            switch (context.Exception)
            {
                case FluentValidation.ValidationException fvEx:
                    foreach (var error in fvEx.Errors)
                    {
                        context.ModelState.AddModelError(error.PropertyName ?? string.Empty, error.ErrorMessage);
                    }
                    var validationErrors = context.ModelState
                        .Where(c => c.Value?.Errors.Count > 0)
                        .ToDictionary(c => c.Key, c => c.Value!.Errors.Select(z => z.ErrorMessage));
                    context.Result = new JsonResult(new { errors = validationErrors });
                    context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                    context.ExceptionHandled = true;
                    return;

                case NotFoundException ex:
                    statusCode = 404;
                    message = ex.Message;
                    break;

                case UnauthorizedException ex:
                    statusCode = 401;
                    message = ex.Message;
                    break;

                case ForbiddenException ex:
                    statusCode = 403;
                    message = ex.Message;
                    break;

                case ClientException ex:
                    statusCode = 400;
                    message = ex.Message;
                    break;

                default:
                    statusCode = 500;
                    message = "An unexpected error occurred.";
                    _logger.LogError(context.Exception, "Unhandled exception");
                    break;
            }

            context.Result = new ObjectResult(new { error = message })
            {
                StatusCode = statusCode
            };
            context.ExceptionHandled = true;
        }
    }
}
