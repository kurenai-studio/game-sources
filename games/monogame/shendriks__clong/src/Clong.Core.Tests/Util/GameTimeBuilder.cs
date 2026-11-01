using System;
using Clong.Core.Domain.Dto;

namespace Clong.Core.Tests.Util;

public class GameTimeBuilder
{
    private readonly TimeSpan _deltaTime = TimeSpan.FromTicks(TimeSpan.TicksPerSecond / 60);
    private int _numberOfFrames = 1;

    public GameTimeBuilder AdvanceFrame()
    {
        _numberOfFrames++;
        return this;
    }

    public GameTime Build()
    {
        return new GameTime {
            DeltaTime = _deltaTime,
            TotalTime = _deltaTime * _numberOfFrames
        };
    }
}