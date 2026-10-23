namespace Playfield
{
    public class Boundary
    {
        public float Min { get; private set; }
        public float Max { get; private set; }

        public Boundary(float min, float max)
        {
            Min = min;
            Max = max;
        }
    }
}