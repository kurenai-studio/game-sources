using System.Text;

namespace Codebound.Core
{
    public static class PlayerNameRules
    {
        public const int MaxLength = 16;
        public const string FallbackName = "Apprentice";

        public static bool IsAllowedChar(char c)
        {
            if (char.IsLetter(c)) return true;
            if (c >= '0' && c <= '9') return true;
            return c == ' ' || c == '-' || c == '\'' || c == '.';
        }

        public static string Clean(string raw)
        {
            if (string.IsNullOrEmpty(raw)) return FallbackName;

            var builder = new StringBuilder(raw.Length);
            foreach (var c in raw)
            {
                var next = char.IsWhiteSpace(c) ? ' ' : c;
                if (!IsAllowedChar(next)) continue;
                if (next == ' ' && (builder.Length == 0 || builder[builder.Length - 1] == ' ')) continue;
                builder.Append(next);
            }

            var cleaned = builder.ToString().TrimEnd();
            if (cleaned.Length > MaxLength) cleaned = cleaned.Substring(0, MaxLength).TrimEnd();
            return cleaned.Length == 0 ? FallbackName : cleaned;
        }
    }
}
