// `dotnet run` plays the game; `dotnet run -- --screenshot <mode> <out.png>`
// boots it, captures one settled frame and exits (see ScreenshotRig).
var rig = Breakout.Systems.ScreenshotRig.TryParse(args);
using var game = new Breakout.BreakoutGame(rig);
game.Run();
