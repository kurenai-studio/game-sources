using Autofac;
using Avalonia;
using Avalonia.Logging.Serilog;
using GraveDefensor.Engine.Designer;
using GraveDefensor.Engine.Designer.ViewModels;

namespace GraveDefensor.Designer
{
    class Program
    {
        // Initialization code. Don't use any Avalonia, third-party APIs or any
        // SynchronizationContext-reliant code before AppMain is called: things aren't initialized
        // yet and stuff might break.
        public static void Main(string[] args) 
        {
            RegisterIoC();
            BuildAvaloniaApp().Start(AppMain, args);
        }

        // Avalonia configuration, don't remove; also used by visual designer.
        public static AppBuilder BuildAvaloniaApp()
            => AppBuilder.Configure<App>()
                .UsePlatformDetect()
                .LogToDebug();

        // Your application's entry point. Here you can initialize your MVVM framework, DI
        // container, etc.
        static void AppMain(Application app, string[] args)
        {
            var mainViewModel = IoC.Resolve<MainViewModel>();
            var ignore = mainViewModel.InitAsync();
            var mainWindow = IoC.Resolve<MainWindow>();
            app.Run(mainWindow);

        }

        static void RegisterIoC()
        {
            var builder = IoC.RegisterIoC();
            builder.RegisterType<MainWindow>();
            IoC.Build(builder);
        }
    }
}
