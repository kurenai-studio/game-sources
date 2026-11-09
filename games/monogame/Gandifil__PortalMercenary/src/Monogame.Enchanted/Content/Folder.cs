using MonoGame.Extended.Serialization.Json;

namespace Monogame.Enchanted.Content;

public class Folder<T>(ContentManager contentManager, string path)
{
    public T this[string key] => contentManager.Load<T>(path + key);
}