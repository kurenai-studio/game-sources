using System.Numerics;
using Clong.Core.Domain.Const;
using Clong.Core.Domain.Dto;
using Clong.Core.Domain.Enum;
using Clong.Core.Ports.Driven;

namespace Clong.Core.Domain.Entity;

public class StarField
{
    private const int StarFieldSize = 25;
    private const TextureId Texture = TextureId.Star;

    private readonly Random _random = new();
    private readonly Vector2[] _starPositions = new Vector2[StarFieldSize];

    public StarField()
    {
        for (var i = 0; i < StarFieldSize; i++) {
            _starPositions[i] = new Vector2(_random.Next(0, Resolution.DesignWidth), _random.Next(0, Resolution.DesignHeight));
        }
    }

    public void Update(GameTime gameTime)
    {
        for (var i = 0; i < StarFieldSize; i++) {
            var starSpeed = 50 + i * (200 / StarFieldSize);

            _starPositions[i] = _starPositions[i] with { X = _starPositions[i].X - starSpeed * gameTime.DeltaSeconds };
            if (_starPositions[i].X < 0) {
                _starPositions[i] = _starPositions[i] with { X = Resolution.DesignWidth };
            }
        }
    }

    public void Draw(IForRendering renderer)
    {
        foreach (var starPosition in _starPositions) {
            renderer.DrawTexture(Texture, starPosition);
        }
    }
}