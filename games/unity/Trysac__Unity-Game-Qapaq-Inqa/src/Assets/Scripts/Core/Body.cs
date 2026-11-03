namespace QapaqInqa.Core
{
    /// <summary>
    /// A box that moves through the tile map: first along x, then along y, stopping flush against
    /// stone. Ledges (and ladder tops) only stop a body that falls onto them from above.
    /// Position is the bottom-centre (the feet).
    /// </summary>
    public class Body
    {
        const float Skin = 0.001f;

        public Body(float width, float height, Vec2 feet)
        {
            Width = width;
            Height = height;
            X = feet.X;
            Y = feet.Y;
        }

        public float Width { get; }
        public float Height { get; }
        public float X { get; set; }
        public float Y { get; set; }
        public float VelocityX { get; set; }
        public float VelocityY { get; set; }
        public bool Grounded { get; protected set; }
        public bool HitWall { get; private set; }
        public bool HitCeiling { get; private set; }

        public Vec2 Feet => new Vec2(X, Y);
        public Box Bounds => new Box(X, Y, Width, Height);

        public void Place(Vec2 feet)
        {
            X = feet.X;
            Y = feet.Y;
            VelocityX = 0f;
            VelocityY = 0f;
        }

        /// <summary>Moves by velocity * dt. <paramref name="ignoreLedges"/> lets the body drop through ledges.</summary>
        public void Move(LevelMap map, float dt, bool ignoreLedges = false)
        {
            HitWall = false;
            HitCeiling = false;
            MoveX(map, VelocityX * dt);
            MoveY(map, VelocityY * dt, ignoreLedges);
        }

        void MoveX(LevelMap map, float dx)
        {
            if (dx == 0f) return;
            float half = Width / 2f;
            float target = X + dx;
            int bottom = LevelMap.Floor(Y + Skin);
            int top = LevelMap.Floor(Y + Height - Skin);
            if (dx > 0f)
            {
                int column = LevelMap.Floor(target + half - Skin);
                for (int y = bottom; y <= top; y++)
                {
                    if (map.IsSolid(column, y))
                    {
                        X = column - half - Skin;
                        VelocityX = 0f;
                        HitWall = true;
                        return;
                    }
                }
            }
            else
            {
                int column = LevelMap.Floor(target - half + Skin);
                for (int y = bottom; y <= top; y++)
                {
                    if (map.IsSolid(column, y))
                    {
                        X = column + 1 + half + Skin;
                        VelocityX = 0f;
                        HitWall = true;
                        return;
                    }
                }
            }
            X = target;
        }

        void MoveY(LevelMap map, float dy, bool ignoreLedges)
        {
            float half = Width / 2f;
            int left = LevelMap.Floor(X - half + Skin);
            int right = LevelMap.Floor(X + half - Skin);
            Grounded = false;
            if (dy == 0f)
            {
                dy = -Skin; // still look for ground under a body at rest
            }
            if (dy < 0f)
            {
                float target = Y + dy;
                int row = LevelMap.Floor(target);
                // Only the row the feet cross into can stop a fall.
                if (row < LevelMap.Floor(Y + Skin))
                {
                    for (int x = left; x <= right; x++)
                    {
                        bool solid = map.IsSolid(x, row);
                        bool ledge = !ignoreLedges && map.IsStandableTop(x, row) && Y >= row + 1 - Skin;
                        if (solid || ledge)
                        {
                            Y = row + 1f;
                            VelocityY = 0f;
                            Grounded = true;
                            return;
                        }
                    }
                }
                Y = target;
            }
            else
            {
                float target = Y + dy;
                int row = LevelMap.Floor(target + Height - Skin);
                for (int x = left; x <= right; x++)
                {
                    if (map.IsSolid(x, row))
                    {
                        Y = row - Height - Skin;
                        VelocityY = 0f;
                        HitCeiling = true;
                        return;
                    }
                }
                Y = target;
            }
        }

        /// <summary>True when stone or a ledge is right under the given x at the feet.</summary>
        public static bool GroundAt(LevelMap map, float x, float feetY)
        {
            int column = LevelMap.Floor(x);
            int row = LevelMap.Floor(feetY - 0.05f);
            return map.IsSolid(column, row) || map.IsStandableTop(column, row);
        }
    }
}
