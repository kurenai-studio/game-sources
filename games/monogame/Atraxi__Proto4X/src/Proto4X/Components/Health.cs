using MonoGameLibrary.Components;

namespace Proto4X.Components
{
    public struct Health(int current, int max)
    {
        public int Current { get; private set; } = current;
        public int Max { get; private set; } = max;
    }
}
