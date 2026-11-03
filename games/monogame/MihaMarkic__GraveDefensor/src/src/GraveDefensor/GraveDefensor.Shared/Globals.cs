using GraveDefensor.Engine.Services.Abstract;
using GraveDefensor.Engine.Services.Implementation;
using Righthand.MessageBus;

namespace GraveDefensor.Shared
{
    public static class Globals
    {
        public static IObjectPool ObjectPool { get; } = new ObjectPool();
        public static IDispatcher Dispatcher { get; } = new Dispatcher();
        public static bool ShowPaths { get; set; } = true;
        public static bool ShowMouseCoordinates { get; set; } = true;
        public static bool ShowButtonsInfo { get; set; } = true;
    }
}
