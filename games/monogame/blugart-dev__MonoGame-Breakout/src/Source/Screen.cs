namespace Breakout;

/// <summary>
/// The virtual resolution as plain constants. These used to live on the Game
/// class, but gameplay code referencing the application shell just to read
/// the screen size is a dependency smell — a Brick has no business knowing
/// the Game type exists. Constants in their own small type keep the dependency
/// arrows pointing one way: everything may read Screen, nothing reads the shell.
/// </summary>
public static class Screen
{
    public const int Width = 800;
    public const int Height = 480;
}
