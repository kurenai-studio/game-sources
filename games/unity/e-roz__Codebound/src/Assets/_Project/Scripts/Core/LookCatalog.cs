using System.Collections.Generic;

namespace Codebound.Core
{
    public sealed class LookInfo
    {
        public int Id { get; }
        public string Label { get; }

        public LookInfo(int id, string label)
        {
            Id = id;
            Label = label;
        }
    }

    public static class LookCatalog
    {
        public const int DefaultId = 0;

        static readonly LookInfo[] _looks =
        {
            new LookInfo(0, "Look 1"),
            new LookInfo(1, "Look 2")
        };

        public static IReadOnlyList<LookInfo> Looks => _looks;

        public static bool IsValid(int id) => id >= 0 && id < _looks.Length;

        public static int Normalize(int id) => IsValid(id) ? id : DefaultId;

        public static string LabelFor(int id) => _looks[Normalize(id)].Label;
    }
}
