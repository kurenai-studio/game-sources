using MonoGame.Extended.Content;

namespace Monogame.Enchanted.Content;

public class ContentLoaderFolder<T>
{
    private readonly Dictionary<string, T> _items = new();
    private readonly ContentManager _contentManager;
    private readonly string _prefix;
    private readonly string _postfix;
    private readonly Func<string, T> _load ;

    public ContentLoaderFolder(ContentManager contentManager, string prefix, string postfix, IContentLoader contentLoader)
    {
        _contentManager = contentManager;
        _prefix = prefix;
        _postfix = postfix;
        _load = x => contentLoader.Load<T>(_contentManager, x);
    }

    public ContentLoaderFolder(ContentManager contentManager, string prefix, string postfix, IContentLoader<T> contentLoader)
    {
        _contentManager = contentManager;
        _prefix = prefix;
        _postfix = postfix;
        _load = x => contentLoader.Load(_contentManager, x);
    }

    public T this[string key]
    {
        get
        {
            if (_items.TryGetValue(key, out var result))
                return result;
            {
                result = _load(_prefix + key + _postfix);
                _items[key] = result;
                return result;
            }
        }
    }
}