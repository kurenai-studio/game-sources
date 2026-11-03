using Microsoft.Extensions.DependencyInjection;

namespace TowerProtect.Registry;

internal static class RegistryExtensions
{
    public static void ReassignSingleton<ITarget, ISource>(this IServiceCollection srv)
        where ITarget : class
        where ISource : class, ITarget
    {
        srv.AddSingleton<ITarget>(sp => sp.GetRequiredService<ISource>());
    }

    public static void ReassignScoped<ITarget, ISource>(this IServiceCollection srv)
        where ITarget : class
        where ISource : class, ITarget
    {
        srv.AddScoped<ITarget>(sp => sp.GetRequiredService<ISource>());
    }

    public static void ReassignTransient<ITarget, ISource>(this IServiceCollection srv)
        where ITarget : class
        where ISource : class, ITarget
    {
        srv.AddTransient<ITarget>(sp => sp.GetRequiredService<ISource>());
    }
}