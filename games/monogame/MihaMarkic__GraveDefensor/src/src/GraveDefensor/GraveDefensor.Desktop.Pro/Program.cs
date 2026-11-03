using GraveDefensor.Engine.Core;
using GraveDefensor.Shared;
using System;

namespace GraveDefensor.Desktop.Pro
{
    public static class Program
    {
        [STAThread]
        static void Main()
        {
            ScreenInfo.Default = ScreenInfo.Window(768, 1280, hasMouse: true);
            using (var game = new GraveDefensorGame())
                game.Run();
        }
    }
}
