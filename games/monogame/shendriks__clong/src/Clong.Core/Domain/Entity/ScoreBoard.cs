using System.Numerics;
using Clong.Core.Domain.Const;
using Clong.Core.Ports.Driven;

namespace Clong.Core.Domain.Entity;

public class ScoreBoard
{
    public int ScorePlayerL { get; internal set; }
    public int ScorePlayerR { get; internal set; }

    internal void Draw(IForRendering renderer)
    {
        var scorePlayerL = $"{ScorePlayerL}";
        var scorePlayerR = $"{ScorePlayerR}";

        renderer.DrawString(scorePlayerL, new Vector2(Resolution.DesignWidth / 2f - 16 * scorePlayerL.Length - 8, 20), scale: 2f, false);
        renderer.DrawString(":", new Vector2(Resolution.DesignWidth / 2f, 20), scale: 2f, false);
        renderer.DrawString(scorePlayerR, new Vector2(Resolution.DesignWidth / 2f + 12, 20), scale: 2f, false);
    }
}