using MonoGameLibrary.Components;

namespace Proto4X.Components
{
    public struct Lvl(int level)
    {
        public int Level { get; private set; } = level;
    }
}
