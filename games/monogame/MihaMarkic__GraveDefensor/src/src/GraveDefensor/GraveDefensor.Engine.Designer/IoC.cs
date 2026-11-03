using Autofac;
using GraveDefensor.Engine.Designer.Services.Abstract;
using GraveDefensor.Engine.Designer.Services.Implementation;
using GraveDefensor.Engine.Designer.ViewModels;

namespace GraveDefensor.Engine.Designer
{
    public static class IoC
    {
        public static IContainer? Container { get; private set; }
        public static T Resolve<T>() => Container.Resolve<T>();
        public static ILifetimeScope BeginLifetimeScope() => Container!.BeginLifetimeScope();
        public static ContainerBuilder RegisterIoC()
        {
            var builder = new ContainerBuilder();
            // view models
            builder.RegisterType<MainViewModel>().SingleInstance();
            builder.RegisterType<SettingsViewModel>().SingleInstance();
            builder.RegisterType<HomeViewModel>();
            // services
            builder.RegisterType<FileService>().As<IFileService>().SingleInstance();
            return builder;
        }
        public static void Build(ContainerBuilder builder)
        {
            Container = builder.Build();
        }
        public static void Dispose() => Container?.Dispose();
    }
}
