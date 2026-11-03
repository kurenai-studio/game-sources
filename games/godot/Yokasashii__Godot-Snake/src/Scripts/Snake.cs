using Godot;
using Godot.Collections;
using System;

public partial class Snake : Node2D
{
    [Export] PackedScene sceneHead;
    [Export] PackedScene sceneBody;
    [Export] PackedScene sceneApple;
    [Export] Timer gameTimer;

    Area2D head, body, apple;
    Array<Area2D> snake = [];
    RandomNumberGenerator rand = new RandomNumberGenerator();

    int colomnMax, lineMax;
    int headRotation;
    int bodyRotation;
    int oldBodyRotation;
    int cell = 64;

    Vector2 screenSize;
    Vector2 vectorDirection = Vector2.Up;
    Vector2 headPosition;
    Vector2 bodyPosition;
    Vector2 oldBodyPosition;

    public override void _Ready()
    {
        screenSize = GetWindow().Size;
        colomnMax = (int)screenSize.Y / cell;
        lineMax = (int)screenSize.X / cell;
        gameTimer.Timeout += HeadMove;
        gameTimer.Timeout += BodyMove;

        StartGame();
    }

    public override void _Process(double pDelta)
    {
        Direction();
    }

    void StartGame()
    {
        snake = [head = (Area2D)sceneHead.Instantiate(), body = (Area2D)sceneBody.Instantiate()];
        for (int i = 0; i < 2; i++) AddChild(snake[i]);

        head.Position = new Vector2(lineMax / 2 * cell + 32, colomnMax / 2 * cell + 32);
        head.AreaEntered += CollisionSnake;
        apple = (Area2D)sceneApple.Instantiate();
        apple.AreaEntered += CollisionApple;
        apple.Position = new Vector2(cell * rand.RandiRange(1, lineMax) + 32, cell * rand.RandiRange(1, colomnMax) + 32);
        AddChild(apple);
    }

    void Direction()
    {
        ;

        if (Input.IsKeyPressed(Key.Z) && vectorDirection != Vector2.Down)
        {
            vectorDirection = Vector2.Up;
            headRotation = 0;
        }
        if (Input.IsKeyPressed(Key.S) && vectorDirection != Vector2.Up)
        {
            vectorDirection = Vector2.Down;
            headRotation = 180;
        }
        if (Input.IsKeyPressed(Key.Q) && vectorDirection != Vector2.Right)
        {
            vectorDirection = Vector2.Left;
            headRotation = -90;
        }
        if (Input.IsKeyPressed(Key.D) && vectorDirection != Vector2.Left)
        {
            vectorDirection = Vector2.Right;
            headRotation = 90;
        }
    }

    void HeadMove()
    {
        headPosition = head.Position;

        if (head.Position.X <= screenSize.X
            && head.Position.Y <= screenSize.Y
            && head.Position.X >= 0
            && head.Position.Y >= 0)
        {
            head.Position += vectorDirection * cell;
            head.RotationDegrees = headRotation;
        }
    }

    void BodyMove()
    {
        bodyPosition = headPosition;
        bodyRotation = headRotation;

        for (int i = 1; i <= snake.Count - 1; i++)
        {
            oldBodyPosition = snake[i].Position;
            oldBodyRotation = (int)snake[i].RotationDegrees;

            snake[i].Position = bodyPosition;
            snake[i].RotationDegrees = bodyRotation;

            bodyPosition = oldBodyPosition;
            bodyRotation = oldBodyRotation;
        }
    }

    void CollisionApple(Area2D pArea)
    {
        CallDeferred(nameof(EatApple));
    }

    void CollisionSnake(Area2D pArea)
    {
        if (pArea != apple)
        {
            CallDeferred(nameof(EndGame));
        }
    }

    void EndGame()
    {
        for (int i = 0; i < snake.Count; ++i)
        {
            snake[i].QueueFree();
        }
        snake.Clear();
        apple.QueueFree();
        StartGame();
    }

    void EatApple()
    {
        apple.Position = new Vector2(cell * rand.RandiRange(1, lineMax - 2) + 32, cell * rand.RandiRange(1, colomnMax - 2) + 32);

        body = (Area2D)sceneBody.Instantiate();
        body.Position = snake[snake.Count - 1].Position;
        snake.Add(body);
        AddChild(body);
    }
}
