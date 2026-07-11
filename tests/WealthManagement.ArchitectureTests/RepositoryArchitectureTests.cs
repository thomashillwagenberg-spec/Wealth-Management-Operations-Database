namespace WealthManagement.ArchitectureTests;

public sealed class RepositoryArchitectureTests
{
    private static readonly string Root = FindRoot();

    [Fact]
    public void Application_layer_does_not_reference_infrastructure()
    {
        var project = File.ReadAllText(Path.Combine(Root,"src","WealthManagement.Application","WealthManagement.Application.csproj"));
        Assert.False(project.Contains("WealthManagement.Infrastructure", StringComparison.Ordinal));
    }

    [Fact]
    public void Endpoint_files_do_not_execute_sql_or_reference_dapper()
    {
        var files = Directory.GetFiles(Path.Combine(Root,"src","WealthManagement.Api","Endpoints"),"*.cs");
        foreach (var file in files)
        {
            var text = File.ReadAllText(file);
            Assert.False(text.Contains("Dapper", StringComparison.Ordinal));
            Assert.False(text.Contains("SqlConnection", StringComparison.Ordinal));
            Assert.False(text.Contains("SELECT ", StringComparison.OrdinalIgnoreCase));
        }
    }

    [Fact]
    public void Entity_framework_is_not_used_for_the_wealth_database()
    {
        var projectFiles = Directory.GetFiles(Path.Combine(Root,"src"),"*.csproj",SearchOption.AllDirectories);
        Assert.All(projectFiles, path => Assert.False(File.ReadAllText(path).Contains("EntityFrameworkCore", StringComparison.OrdinalIgnoreCase)));
    }

    [Fact]
    public void Development_authentication_resolves_roles_server_side()
    {
        var handler = File.ReadAllText(Path.Combine(Root,"src","WealthManagement.Api","Authentication","DevelopmentHeaderAuthenticationHandler.cs"));
        Assert.Contains("DevelopmentIdentities.TryGet", handler, StringComparison.Ordinal);
        Assert.DoesNotContain("X-Dev-Roles", handler, StringComparison.Ordinal);
        Assert.DoesNotContain("X-Dev-Advisor-Id", handler, StringComparison.Ordinal);
    }

    [Fact]
    public void Development_authentication_has_a_production_environment_guard()
    {
        var text = File.ReadAllText(Path.Combine(Root,"src","WealthManagement.Api","Authentication","AuthenticationExtensions.cs"));
        Assert.Contains("!environment.IsDevelopment()", text, StringComparison.Ordinal);
        Assert.Contains("throw new InvalidOperationException", text, StringComparison.Ordinal);
    }

    private static string FindRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName,"project-manifest.json"))) return directory.FullName;
            directory=directory.Parent;
        }
        throw new DirectoryNotFoundException("Repository root was not found.");
    }
}
