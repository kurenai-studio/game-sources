using Microsoft.Extensions.DependencyInjection;
using Microsoft.Xna.Framework;
using System;
using TowerProtect.Framework;

namespace TowerProtect.Registry;

internal static class MonoGameRegistryExtensions
{
    public static void InitializeMonoGame(this IServiceCollection srv)
    {
        srv.AddSingleton<MainGame>();
        srv.ReassignSingleton<Game, MainGame>();
    }

    public static void AddMonoGameSingleton<T>(this IServiceCollection srv)
        where T : class, IGameComponent
    {
        srv.AddSingleton<T>();
        srv.ReassignSingleton<IGameComponent, T>();
    }

    public static void AddMonoGameSingleton<I, T>(this IServiceCollection srv)
        where I : class
        where T : class, I, IGameComponent
    {
        srv.AddMonoGameSingleton<T>();
        srv.ReassignSingleton<I, T>();
    }

    public static void AttachComponents(this Game game, IServiceProvider provider)
    {
        var components = provider.GetServices<IGameComponent>();
        foreach (var component in components)
        {
            game.Components.Add(component);
        }
    }
}
