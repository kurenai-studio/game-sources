using MonoGameLibrary.Components;

namespace Proto4X.Components
{
    public struct Damage(int value)
    {
        public int Value { get; private set; } = value;
    }
}
