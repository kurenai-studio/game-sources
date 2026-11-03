using System;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    /// <summary>Helpers that drive the rules frame by frame, as the game does at 60 Hz.</summary>
    static class Sim
    {
        public const float Dt = Tuning.Step;

        public static LevelMap Map(params string[] rows) => new LevelMap(rows);

        public static InputFrame Hold(float x = 0f, float y = 0f, bool jump = false, bool fire = false) =>
            new InputFrame(x, y, false, jump, fire);

        public static InputFrame Press(float x = 0f, float y = 0f, bool fire = false) =>
            new InputFrame(x, y, true, true, fire);

        public static MoveEvents Frames(PlayerMotor motor, LevelMap map, InputFrame input, int frames)
        {
            MoveEvents all = MoveEvents.None;
            for (int i = 0; i < frames; i++)
            {
                all |= motor.Step(map, input, Dt);
            }
            return all;
        }

        public static void Frames(Stage stage, InputFrame input, int frames)
        {
            for (int i = 0; i < frames; i++)
            {
                stage.Step(input, Dt);
            }
        }

        /// <summary>Steps until the condition holds; fails the test after <paramref name="maxFrames"/>.</summary>
        public static int Until(Stage stage, InputFrame input, Func<bool> done, int maxFrames = 600)
        {
            for (int i = 0; i < maxFrames; i++)
            {
                if (done()) return i;
                stage.Step(input, Dt);
            }
            throw new InvalidOperationException($"Condition not met within {maxFrames} frames.");
        }

        public static int Seconds(float seconds) => (int)Math.Round(seconds / Dt);

        /// <summary>A flat floor (row y = 0) with the player at x = 1 and the gate far right.</summary>
        public static string[] Flat(int width = 40, string actors = "")
        {
            string floor = new string('#', width);
            string air = new string(' ', width);
            char[] line = air.ToCharArray();
            line[1] = 'P';
            line[width - 3] = 'E';
            for (int i = 0; i < actors.Length && i + 2 < width - 3; i++)
            {
                if (actors[i] != ' ') line[i + 2] = actors[i];
            }
            return new[] { air, air, air, air, air, new string(line), floor };
        }
    }
}
