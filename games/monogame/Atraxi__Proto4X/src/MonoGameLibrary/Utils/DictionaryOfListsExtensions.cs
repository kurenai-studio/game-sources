using System.Collections.Generic;

namespace MonoGameLibrary.Utils
{
    public static class DictionaryOfListsExtensions
    {
        public static V AddToInternalList<K, V>(this Dictionary<K, List<V>> dictionary, K key, V value) where K : notnull
        {
            if (dictionary.TryGetValue(key, out List<V>? list))
            {
                list.Add(value);
            }
            else
            {
                dictionary.Add(key, [value]);
            }

            return value;
        }
    }
}
