using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MineDirt.Src;
public class Camera
{
    private GraphicsDevice graphicsDevice = null;
    private GameWindow gameWindow = null;

    private MouseState mState = default(MouseState);
    private KeyboardState kbState = default(KeyboardState);

    public static float MovementUnitsPerSecond { get; set; } = 20f;
    public static float SprintMovementUnitsPerSecond { get; set; } = 60f;

    public float ReachDistance { get; set; } = 20.0f;

    public float RotationSpeed { get; set; } = 0.005f;
    public float fieldOfViewDegrees = 90f;

    public float ViewDistance { get; set; } = 1000.0f;

    public bool MouseLookEnabled = true;

    private float yaw;
    private float pitch;

    public Matrix View = Matrix.Identity;
    public Matrix Projection = Matrix.Identity;

    public Vector3 Position = new(0, 100, 0);

    public float AspectRatio;

    public Vector3 Forward;
    public Matrix RotationMatrix;

    public Block PointedBlock { get; set; }
    public Vector3 PointedBlockPosition;
    public Vector3 PointedBlockFace;

    private bool wasMenuModeToggleKeyPressed = false;
    private bool mouseLeftWasDown = false;
    private bool mouseRightWasDown = false;

    public bool IsUnderwater = false;
    
    private Vector3 lastFixedPosition = Vector3.Zero;

    public Camera(GraphicsDevice graphicsDevice, GameWindow gameWindow)
    {
        this.graphicsDevice = graphicsDevice;
        this.gameWindow = gameWindow;

        UpdateView();
        UpdateProjection();
    }

    public void UpdateView()
    {
        View = Matrix.CreateLookAt(Position, Forward + Position, Vector3.Up);
    }

    public void UpdateProjection()
    {
        AspectRatio = graphicsDevice.Viewport.Width / (float)graphicsDevice.Viewport.Height;
        Projection = Matrix.CreatePerspectiveFieldOfView(fieldOfViewDegrees * (float)((3.14159265358f) / 180f), AspectRatio, .1f, ViewDistance);
    }

    public void Update(GameTime gameTime)
    {
        mState = Mouse.GetState(gameWindow);
        kbState = Keyboard.GetState();

        bool moved = HandleMovement(gameTime);
        bool rotated = HandleRotation(gameTime);
        bool triggered = HandlePlacement(gameTime);

        if (moved || rotated)
        {
            UpdateView();
            UpdatePointedBlock();

            if (Vector3.Floor(Position) != lastFixedPosition)
            {
                lastFixedPosition = Vector3.Floor(Position);

                World.TryGetBlock(lastFixedPosition, out Block block);
                IsUnderwater = block.Type == BlockType.Water;
            }
        }

        if (triggered)
            UpdatePointedBlock();
    }

    public float GetMovementSpeed()
    {
        if (kbState.IsKeyDown(Keys.LeftControl))
            return SprintMovementUnitsPerSecond;

        return MovementUnitsPerSecond;
    }

    public bool HandleRotation(GameTime gameTime)
    {
        int centerX = graphicsDevice.Viewport.Width / 2;
        int centerY = graphicsDevice.Viewport.Height / 2;

        if (MouseLookEnabled)
        {
            int deltaX = mState.X - centerX;
            int deltaY = mState.Y - centerY;

            if (deltaX != 0f || deltaY != 0f)
            {
                yaw -= deltaX * RotationSpeed;
                pitch -= deltaY * RotationSpeed;

                pitch = MathHelper.Clamp(
                    pitch,
                    -MathHelper.PiOver2 + 0.001f,
                    MathHelper.PiOver2 - 0.001f
                );

                RotateFromYawPitch(yaw, pitch);

                Mouse.SetPosition(centerX, centerY);
                return true;
            }
        }

        // Toggle mouse control mode
        if (kbState.IsKeyDown(Keys.Tab) && !wasMenuModeToggleKeyPressed)
        {
            MouseLookEnabled = !MouseLookEnabled;
            wasMenuModeToggleKeyPressed = true;

            if (MouseLookEnabled)
            {
                MineDirtGame.IsMouseCursorVisible = false;
                Mouse.SetPosition(centerX, centerY);
            }
            else
            {
                MineDirtGame.IsMouseCursorVisible = true;
            }
        }

        if (kbState.IsKeyUp(Keys.Tab))
        {
            wasMenuModeToggleKeyPressed = false;
        }

        return false;
    }

    public bool HandleMovement(GameTime gameTime)
    {
        Vector3 moveDirection = Vector3.Zero;

        Matrix yawRotation = Matrix.CreateRotationY(yaw);

        Vector3 forwardPlanar = Vector3.Transform(Vector3.Forward, yawRotation);
        Vector3 rightPlanar = Vector3.Transform(Vector3.Right, yawRotation);

        if (kbState.IsKeyDown(Keys.W))
            moveDirection += forwardPlanar;

        if (kbState.IsKeyDown(Keys.S))
            moveDirection -= forwardPlanar;

        if (kbState.IsKeyDown(Keys.A))
            moveDirection -= rightPlanar;

        if (kbState.IsKeyDown(Keys.D))
            moveDirection += rightPlanar;

        if (kbState.IsKeyDown(Keys.LeftShift))
            moveDirection += Vector3.Down;

        if (kbState.IsKeyDown(Keys.Space))
            moveDirection += Vector3.Up;

        if (moveDirection.LengthSquared() > 0.001f)
        {
            Position += Vector3.Normalize(moveDirection) * GetMovementSpeed() * (float)gameTime.ElapsedGameTime.TotalSeconds;
            return true;
        }

        return false;
    }

    public bool HandlePlacement(GameTime gameTime)
    {
        bool triggered = false;

        // Check if player is in menu mode
        if (MouseLookEnabled)
        {
            if (mState.LeftButton == ButtonState.Pressed && !mouseLeftWasDown)
            {
                mouseLeftWasDown = true;
                if (PointedBlock.Type != BlockType.Air)
                {
                    World.BreakBlock(PointedBlockPosition);
                    triggered = true;
                }
            }
            else if (mState.RightButton == ButtonState.Pressed && !mouseRightWasDown)
            {
                mouseRightWasDown = true;
                Block block = new(BlockType.Glass);

                World.PlaceBlock(PointedBlockPosition + PointedBlockFace, block);
                triggered = true;
            }
        }

        if (mState.LeftButton == ButtonState.Released)
            mouseLeftWasDown = false;

        if (mState.RightButton == ButtonState.Released)
            mouseRightWasDown = false;

        return triggered;
    }

    public void RotateFromYawPitch(float yaw, float pitch)
    {
        RotationMatrix = Matrix.CreateFromYawPitchRoll(yaw, pitch, 0);
        Forward = Vector3.Transform(Vector3.Forward, RotationMatrix);
    }

    public void UpdatePointedBlock()
    {
        /*Vector3 rayPosition = Position;
        Vector3 rayDirection = Vector3.Normalize(Forward);*/

        World.RayCast(new Ray(Position, Vector3.Normalize(Forward)), (int)ReachDistance,
            out PointedBlockPosition,
            out PointedBlockFace,
            out Block block
        );
        PointedBlock = block;

        /*Vector3 lastPosition;

        for (float t = 0; t < ReachDistance; t += 0.01f)
        {
            lastPosition = rayPosition;
            rayPosition += rayDirection * 0.01f;
            Vector3 blockPos = Vector3.Floor(rayPosition);

            if (World.TryGetBlock(blockPos, out Block block))
            {
                if (block.Type == BlockType.Air)
                    continue;

                PointedBlockPosition = blockPos;
                PointedBlock = block;

                Vector3 hitFace = Vector3.Floor(rayPosition) - Vector3.Floor(lastPosition);
                PointedBlockFace = new Vector3((int)hitFace.X * -1, (int)hitFace.Y * -1, (int)hitFace.Z * -1);

                return;
            }
        }

        PointedBlockPosition = default;
        PointedBlock = default;
        PointedBlockFace = default;*/
    }
}
