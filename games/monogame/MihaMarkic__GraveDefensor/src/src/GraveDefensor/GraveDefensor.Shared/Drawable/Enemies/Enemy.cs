using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Messages;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Righthand.MessageBus;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Enemies
{
    public abstract class Enemy: Drawable
    {
        public static TimeSpan VisibleBeforeDone { get; } = TimeSpan.FromSeconds(1);
        public static TimeSpan VisibleKilledBeforeDone { get; } = TimeSpan.FromSeconds(.5);
        Texture2D texture;
        public Vector2 Center { get; protected set; }
        public Vector2 OffsetToCenter { get; private set; }
        public float Angle { get; set; }
        public int Width { get; private set; }
        public int Height { get; private set; }
        public int LastPoint { get; set; }
        public double Traversed { get; private set; }
        public double SegmentLength { get; set; }
        public double DistanceToEnd { get; protected set; }
        public EnemyStatus Status { get; protected set; }
        public int Health { get; private set; }
        public TimeSpan FinishedStatusSpan { get; private set; }
        public TimeSpan KilledStatusSpan { get; private set; }
        IDispatcher dispatcher;
        Settings.Enemy settings;
        public Path Path { get; private set; }
        /// <summary>
        /// Determines whether the enemy can be fired upon
        /// </summary>
        public bool IsTarget => Status == EnemyStatus.Ready || Status == EnemyStatus.Frozen || Status == EnemyStatus.Walking;
        public void Init(IInitContext context, Settings.Enemy settings, Path path)
        {
            this.settings = settings;
            Path = path;
            dispatcher = context.Dispatcher;
            Center = Vector2.Zero;
            Status = EnemyStatus.Ready;
            Health = settings.Health;
        }
        public override void InitContent(IInitContentContext context)
        {
            texture = context.Load<Texture2D>(@"Enemies\Walker");
            OffsetToCenter = new Vector2(texture.Width / 2.0f, texture.Height / 2.0f);
            base.InitContent(context);
        }
        public void Start()
        {
            LastPoint = 0;
            Center = Path.Settings.Points[0].AsVector2();
            SegmentLength = Path.SegmentsLengths[LastPoint];
            Angle = (float)Path.Angles[LastPoint];
            Status = EnemyStatus.Walking;
            FinishedStatusSpan = TimeSpan.FromSeconds(1);
            DistanceToEnd = Path.CalculateLengthFromSegment(0);
        }
        public override void Update(UpdateContext context)
        {
            switch (Status)
            {
                case EnemyStatus.Walking:
                    double distance = settings.Speed * context.GameTime.ElapsedGameTime.TotalSeconds;
                    DistanceToEnd -= distance;
                    if (Traversed + distance < SegmentLength)
                    {
                        Traversed += distance;
                    }
                    else
                    {
                        // continue to next line segment
                        if (LastPoint < Path.SegmentsLengths.Length-1)
                        {
                            LastPoint++;
                            Traversed = Traversed + distance - SegmentLength;
                            SegmentLength = Path.SegmentsLengths[LastPoint];
                            Angle = (float)Path.Angles[LastPoint];
                        }
                        // finished path
                        else
                        {
                            TransitionToFinished();
                        }
                    }
                    Center = Vector2.Lerp(Path.Settings.Points[LastPoint].AsVector2(), Path.Settings.Points[LastPoint + 1].AsVector2(), (float)(Traversed / SegmentLength));
                    break;
                case EnemyStatus.Finished:
                    FinishedStatusSpan -= context.GameTime.ElapsedGameTime;
                    if (FinishedStatusSpan < TimeSpan.Zero)
                    {
                        TransitionToDone();
                    }
                    break;
                case EnemyStatus.Killed:
                    KilledStatusSpan -= context.GameTime.ElapsedGameTime;
                    if (KilledStatusSpan < TimeSpan.Zero)
                    {
                        TransitionToDone();
                    }
                    break;
            }
            base.Update(context);
        }
        internal void TransitionToFinished()
        {
            Center = Path.LastPoint.AsVector2();
            Status = EnemyStatus.Finished;
            dispatcher.Dispatch(new ChangeStatusMessage(0, -Health));
            DistanceToEnd = 0;
        }
        internal void TransitionToKilled()
        {
            KilledStatusSpan = TimeSpan.FromMilliseconds(500);
            dispatcher.Dispatch(new ChangeStatusMessage(settings.Award, 0));
            Status = EnemyStatus.Killed;
        }
        internal void TransitionToDone()
        {
            Status = EnemyStatus.Done;
        }
        internal void Hit(int power)
        {
            Health -= power;
            if (Health < 0)
            {
                Health = 0;
                TransitionToKilled();
            }
        }
        public override void Draw(IDrawContext context)
        {
            if (IsVisible)
            {
                context.Draw(texture, Center, null, Color.White, Angle, OffsetToCenter, new Vector2(1, 1), SpriteEffects.None, 0);
                DrawHealth(context);
            }
            base.Draw(context);
        }
        void DrawHealth(IDrawContext context)
        {
            const float width = 40;
            const float height = 10;
            const float verticalOffset = 5;
            var topLeft = Center - OffsetToCenter + new Vector2(0, -height - verticalOffset);
            if (Health == settings.Health)
            {
                context.FillRectangle(topLeft, new Vector2(width, height), Color.Red);
            }
            else
            {
                float percent = (float)Health / settings.Health;
                float healthWidth = width * percent;
                context.FillRectangle(topLeft, new Vector2(healthWidth, height), Color.Red);
                var blackTopLeft = topLeft + new Vector2(healthWidth, 0);
                context.FillRectangle(blackTopLeft, new Vector2(width - healthWidth, height), Color.Black);
            }
        }
        public void CopyContentFrom(Enemy enemy)
        {
            texture = enemy.texture;
            OffsetToCenter = enemy.OffsetToCenter;
        }
        public bool IsDone => Status == EnemyStatus.Done;
        public bool IsVisible => Status != EnemyStatus.Ready && Status != EnemyStatus.Done;
        public double CalculateDistanceToEnd()
        {
            return Path.SegmentsLengths[LastPoint] - Traversed + Path.CalculateLengthFromSegment(LastPoint+1);
        }
    }
}
