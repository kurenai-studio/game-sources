using System.Diagnostics;

namespace Monogame.Enchanted.Debug;

public static class Log {
	[Conditional("DEBUG")]
	public static void Info(string message) => Print(message, ConsoleColor.Green, "INF");

	[Conditional("DEBUG")]
	public static void Warning(string message) => Print(message, ConsoleColor.DarkYellow, "WRN");

	[Conditional("DEBUG")]
	public static void Error(string message) => Print(message, ConsoleColor.DarkRed, "ERR");

	private static void Print(string message, ConsoleColor color, string type) 
	{
		Console.ForegroundColor = color;
		Console.Write($"[{type}] ");
		Console.ResetColor();
		Console.WriteLine(message);
	}
}