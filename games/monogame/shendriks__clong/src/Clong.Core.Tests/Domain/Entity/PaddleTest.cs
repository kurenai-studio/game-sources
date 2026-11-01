using System.Numerics;
using Clong.Core.Domain.Const;
using Clong.Core.Domain.Entity;
using Clong.Core.Domain.Enum;
using Clong.Core.Domain.Input;
using Clong.Core.Tests.Util;
using NUnit.Framework;

namespace Clong.Core.Tests.Domain.Entity;

[TestFixture]
[TestOf(typeof(Paddle))]
public class PaddleTest
{
    [Test]
    public void TestUpdateMovesPaddle()
    {
        var paddle = new Paddle {
            Texture = TextureId.PaddleL,
            Position = new Vector2(0, 100)
        };

        const float epsilon = 0.001f;
        var gameTimeBuilder = new GameTimeBuilder();

        var gameTime = gameTimeBuilder.Build();
        var controlInput = new InGameControlInput { Y = 1 };
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(108.333f).Within(epsilon));

        gameTime = gameTimeBuilder.AdvanceFrame().Build();
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(116.666f).Within(epsilon));

        gameTime = gameTimeBuilder.AdvanceFrame().Build();
        controlInput = new InGameControlInput { Y = -1 };
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(108.333f).Within(epsilon));

        gameTime = gameTimeBuilder.AdvanceFrame().Build();
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(100f).Within(epsilon));

        gameTime = gameTimeBuilder.AdvanceFrame().Build();
        controlInput = new InGameControlInput { Y = 0 };
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(100f).Within(epsilon));
    }

    [Test]
    [TestCase(0f, 32f)]
    [TestCase(Resolution.DesignHeight, Resolution.DesignHeight - 32f)]
    public void TestUpdateRestrictsMovement(float paddlePositionY, float expectedCorrectedPositionY)
    {
        var paddle = new Paddle {
            Texture = TextureId.PaddleL,
            Position = new Vector2(0, paddlePositionY)
        };

        var gameTimeBuilder = new GameTimeBuilder();

        var gameTime = gameTimeBuilder.Build();
        var controlInput = new InGameControlInput { Y = 0 };
        paddle.Update(gameTime, controlInput);
        Assert.That(paddle.Position.X, Is.EqualTo(0));
        Assert.That(paddle.Position.Y, Is.EqualTo(expectedCorrectedPositionY));
    }
}