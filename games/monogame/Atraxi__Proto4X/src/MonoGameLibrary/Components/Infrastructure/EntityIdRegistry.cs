namespace MonoGameLibrary.Components.Infrastructure
{
    //Currently this just increments, but it's possible we'll switch to pooled/reused Ids or something hashed or randomised
    internal static class EntityIdRegistry
    {
        private static int NextId = 0;

        public static int GetNextFreeId()
        {
            return NextId++;
        }
    }
}
