using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace WealthManagement.Api.Authentication;

public static class AuthenticationExtensions
{
    public static IServiceCollection AddApplicationAuthentication(this IServiceCollection services, IConfiguration configuration, IWebHostEnvironment environment)
    {
        var enableDevelopmentAuth = configuration.GetValue<bool>("Authentication:EnableDevelopmentAuth");
        if (enableDevelopmentAuth && !environment.IsDevelopment()) throw new InvalidOperationException("Development authentication cannot be enabled outside the Development environment.");

        if (enableDevelopmentAuth)
        {
            services.AddAuthentication(DevelopmentHeaderAuthenticationHandler.Scheme)
                .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, DevelopmentHeaderAuthenticationHandler>(DevelopmentHeaderAuthenticationHandler.Scheme, _ => { });
            return services;
        }

        var authority = configuration["Authentication:Authority"];
        var audience = configuration["Authentication:Audience"];
        if (string.IsNullOrWhiteSpace(authority) || string.IsNullOrWhiteSpace(audience))
            throw new InvalidOperationException("Production authentication requires Authentication:Authority and Authentication:Audience.");

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.Authority = authority;
                options.Audience = audience;
                options.RequireHttpsMetadata = true;
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ClockSkew = TimeSpan.FromMinutes(2),
                    NameClaimType = "name",
                    RoleClaimType = "roles"
                };
            });
        return services;
    }
}
