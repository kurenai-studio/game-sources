using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.UI
{
    // One text object per code line so a single line can be highlighted.
    // Up to 5 lines use the roomy layout; 6 to 8 lines shrink the rows to fit the same frame.
    public class CodePanelView : MonoBehaviour
    {
        const int RoomyLines = 5;
        const float RoomySpacing = 62f;
        const float PanelHeight = 310f;

        static readonly Color Off = new Color(1f, 1f, 1f, 0f);
        static readonly Color On = new Color(1f, 0.8f, 0.4f, 0.35f);

        [SerializeField] GameObject[] _rows;
        [SerializeField] TMP_Text[] _texts;
        [SerializeField] Image[] _highlights;

        float _firstRowY;
        bool _measured;

        public int RowCount => _rows == null ? 0 : _rows.Length;

        public void SetCode(IReadOnlyList<string> lines)
        {
            Measure();
            var count = Mathf.Min(lines.Count, _rows.Length);
            var spacing = count <= RoomyLines ? RoomySpacing : PanelHeight / count;
            var fontSize = count <= RoomyLines ? 32f : count == 6 ? 30f : count == 7 ? 28f : 26f;

            for (var i = 0; i < _rows.Length; i++)
            {
                var used = i < count;
                _rows[i].SetActive(used);
                _highlights[i].color = Off;
                if (!used) continue;

                var rect = (RectTransform)_rows[i].transform;
                rect.anchoredPosition = new Vector2(rect.anchoredPosition.x, _firstRowY - i * spacing);
                rect.sizeDelta = new Vector2(rect.sizeDelta.x, spacing - 8f);
                _texts[i].fontSize = fontSize;
                _texts[i].text = $"{i + 1}  {lines[i]}";
            }
        }

        // line is 1-based; 0 clears the highlight.
        public void Highlight(int line)
        {
            for (var i = 0; i < _highlights.Length; i++)
                _highlights[i].color = i == line - 1 ? On : Off;
        }

        // The first row's position is the anchor for every layout.
        void Measure()
        {
            if (_measured) return;
            _firstRowY = ((RectTransform)_rows[0].transform).anchoredPosition.y;
            _measured = true;
        }
    }
}
