using System.Drawing;
using System.Numerics;
using Clong.Core.Domain.Const;
using Clong.Core.Domain.Dto;
using Clong.Core.Domain.Entity;
using Clong.Core.Domain.Enum;
using Clong.Core.Domain.Input;
using Clong.Core.Ports.Driven;
using Clong.Core.Ports.Driving;

namespace Clong.Core.Domain;

public class Clong
(
    IForReadingInput inputReader,
    IForRendering renderer,
    IForPlayingSound soundPlayer
) : IForRunningTheGame
{
    private static readonly Random Random = new();
    private const float StartSpeed = 300f;
    private const float MaxSpeed = 600f;
    private bool _isPaused = true;

    // Input Mapping (logical to physical keys and buttons)
    private readonly InputConfiguration _inputConfigurationPlayerL = new() { KeyUp = Key.W, KeyDown = Key.S };
    private readonly InputConfiguration _inputConfigurationPlayerR = new();

    // Game Objects / Entities
    private readonly Ball _ball = new() {
        Position = GetBallStartingPosition(),
        Direction = GetInitialBallDirection(),
        Speed = StartSpeed
    };

    private readonly Paddle _paddleR = new() {
        Position = GetStartingPositionPaddleR(),
        Texture = TextureId.PaddleR
    };

    private readonly Paddle _paddleL = new() {
        Position = GetStartingPositionPaddleL(),
        Texture = TextureId.PaddleL
    };

    private readonly ScoreBoard _scoreBoard = new();
    private readonly StarField _starField = new();

    public void Update(GameTime gameTime)
    {
        var inputState = inputReader.ReadInput();

        if (inputState.WasKeyPressedInThisFrame(Key.Space)) {
            _isPaused = !_isPaused;
        }

        _starField.Update(gameTime);

        if (_isPaused) {
            return;
        }

        var playerLInput = InGameControlInput.FromInputState(inputState, _inputConfigurationPlayerL);
        var playerRInput = InGameControlInput.FromInputState(inputState, _inputConfigurationPlayerR);

        _paddleL.Update(gameTime, playerLInput);
        _paddleR.Update(gameTime, playerRInput);
        _ball.Update(gameTime);

        CheckIfBallHitWall();
        CheckIfBallLeftPlayField();
        CheckIfBallHitPaddle(_paddleL);
        CheckIfBallHitPaddle(_paddleR);
    }

    public void Draw()
    {
        _starField.Draw(renderer);
        _paddleL.Draw(renderer);
        _paddleR.Draw(renderer);
        _scoreBoard.Draw(renderer);
        _ball.Draw(renderer);

        if (_isPaused) {
            renderer.DrawString(
                "Press Space to Play | W/S to move left Paddle | Up/Down to move right Paddle",
                new Vector2(Resolution.DesignWidth / 2f, Resolution.DesignHeight - 40)
            );
        }
    }

    private void CheckIfBallHitWall()
    {
        var upperBound = _ball.Size.Height / 2f;
        var lowerBound = Resolution.DesignHeight - upperBound;

        if (_ball.Position.Y < upperBound) {
            _ball.Direction = _ball.Direction with { Y = Math.Abs(_ball.Direction.Y) };
            _ball.Position = _ball.Position with { Y = upperBound };
            soundPlayer.PlaySound(SoundId.BallHitWall);
        } else if (_ball.Position.Y > lowerBound) {
            _ball.Direction = _ball.Direction with { Y = -Math.Abs(_ball.Direction.Y) };
            _ball.Position = _ball.Position with { Y = lowerBound };
            soundPlayer.PlaySound(SoundId.BallHitWall);
        }
    }

    private void CheckIfBallLeftPlayField()
    {
        switch (_ball.Position.X) {
            case > 0 and < Resolution.DesignWidth:
                return;
            case < 0:
                _scoreBoard.ScorePlayerR++;
                break;
            default:
                _scoreBoard.ScorePlayerL++;
                break;
        }

        soundPlayer.PlaySound(SoundId.BallLeftPlayField);
        ResetBallAndPaddles();
    }

    private void CheckIfBallHitPaddle(Paddle hitPaddle)
    {
        var overlap = Rectangle.Intersect(_ball.BoundingBox, hitPaddle.BoundingBox);
        if (overlap.IsEmpty) {
            return;
        }

        var newDirection = ReflectBallFromPaddle(hitPaddle);
        if (overlap.Width > overlap.Height) {
            var deltaY = _ball.Direction.Y > 0 ? -overlap.Height : overlap.Height;
            _ball.Position = _ball.Position with { Y = _ball.Position.Y + deltaY };
        } else {
            var deltaX = _ball.Direction.X > 0 ? -overlap.Width : overlap.Width;
            _ball.Position = _ball.Position with { X = _ball.Position.X + deltaX };
        }

        _ball.Direction = newDirection;

        soundPlayer.PlaySound(SoundId.BallHitPaddle);
    }

    private Vector2 ReflectBallFromPaddle(Paddle paddle)
    {
        var deltaY = (paddle.Position.Y - _ball.Position.Y) / (paddle.BoundingBox.Height / 2f);
        var newDirection = Vector2.Normalize(
            _ball.Direction with {
                X = -_ball.Direction.X,
                Y = Math.Clamp(_ball.Direction.Y - deltaY, -1f, 1f)
            }
        );
        if (_ball.Speed < MaxSpeed) {
            _ball.Speed += 10;
        }

        return newDirection;
    }

    private void ResetBallAndPaddles()
    {
        _ball.Speed = StartSpeed;
        _ball.Position = GetBallStartingPosition();
        _ball.Direction = GetInitialBallDirection();
        _paddleL.Position = GetStartingPositionPaddleL();
        _paddleR.Position = GetStartingPositionPaddleR();
    }

    private static Vector2 GetBallStartingPosition()
    {
        return new Vector2(Resolution.DesignWidth / 2f, Resolution.DesignHeight / 2f);
    }

    private static Vector2 GetInitialBallDirection()
    {
        var x = Random.Next(0, 2) * 2 - 1;
        var y = (float)Random.NextDouble() * 2 - 1;
        var direction = Vector2.Normalize(new Vector2(x, y));
        return direction;
    }

    private static Vector2 GetStartingPositionPaddleR()
    {
        return new Vector2(Resolution.DesignWidth - 8, Resolution.DesignHeight / 2f);
    }

    private static Vector2 GetStartingPositionPaddleL()
    {
        return new Vector2(8, Resolution.DesignHeight / 2f);
    }
}