using System;

namespace PortalMercenary.Utils;

public struct GameStats
{
    public float Time;

    public bool? IsWin;
    public int Kills;
    
    public string[] ToStringArray()
    {
        return
        [
            $"{(IsWin.HasValue ? (IsWin.Value ? "WIN!" : "DEFEAT!") : "N/A")}",
            $"time: {TimeSpan.FromSeconds((int)Time)}",
            $"kills: {Kills}"
        ];
    }
}