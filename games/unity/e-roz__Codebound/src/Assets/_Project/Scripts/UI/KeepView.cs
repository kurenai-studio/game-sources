using System.Collections;
using Codebound.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.UI
{
    // Draws a KeepState: guards on top, chests below, one thread per guard that points at a chest.
    public class KeepView : MonoBehaviour
    {
        static readonly Color ErrorColor = new Color(1f, 0.45f, 0.4f);
        static readonly Color FlashColor = new Color(1f, 0.85f, 0.3f);
        static readonly Color GreenColor = new Color(0.5f, 0.9f, 0.55f);
        static readonly Color ReaderColor = new Color(0.7f, 0.75f, 0.85f);

        [SerializeField] RectTransform[] _guardRoots;
        [SerializeField] TMP_Text[] _guardLabels;
        [SerializeField] Image[] _threads;
        [SerializeField] RectTransform[] _chestRoots;
        [SerializeField] Image[] _chestImages;
        [SerializeField] TMP_Text[] _chestLabels;
        [SerializeField] GameObject[] _chestSwords;
        [SerializeField] TMP_Text[] _gateRows;
        [SerializeField] TMP_Text[] _logRows;
        [SerializeField] TMP_Text _captionText;
        [SerializeField] TMP_Text _outputText;
        [SerializeField] float _guardHalfHeight = 90f;
        [SerializeField] float _chestHalfHeight = 100f;

        void Awake()
        {
            foreach (var label in _chestLabels)
            {
                label.enableAutoSizing = true;
                label.fontSizeMax = label.fontSize;
                label.fontSizeMin = 16f;
            }
        }

        public void Render(KeepState state)
        {
            for (var i = 0; i < _guardRoots.Length; i++)
            {
                var used = i < state.Guards.Count;
                _guardRoots[i].gameObject.SetActive(used);
                _threads[i].gameObject.SetActive(false);
                if (!used) continue;

                var guard = state.Guards[i];
                _guardLabels[i].text = guard.Value.HasValue ? $"{guard.Name} = {guard.Value.Value}"
                    : guard.IsNull ? $"{guard.Name} = null" : guard.Name;

                var chestIndex = state.ChestIndex(guard.ObjectId);
                if (!guard.IsNull && chestIndex >= 0 && chestIndex < _chestRoots.Length)
                    PlaceThread(_threads[i], _guardRoots[i].anchoredPosition + Vector2.down * _guardHalfHeight,
                        _chestRoots[chestIndex].anchoredPosition + Vector2.up * _chestHalfHeight);
            }

            for (var j = 0; j < _chestRoots.Length; j++)
            {
                var used = j < state.Chests.Count;
                _chestRoots[j].gameObject.SetActive(used);
                if (!used) continue;

                var chest = state.Chests[j];
                _chestLabels[j].text = $"{chest.TypeName} #{chest.Id}" +
                                       (chest.ItemCount > 0 ? $": {string.Join(", ", state.DescribeItems(chest))}" : string.Empty);
                // The items are named in the label, so the generic sword icon would only mislead.
                _chestSwords[j].SetActive(false);
            }

            RenderGateRows(state);
            RenderReport(state);

            _captionText.text = state.Caption;
            _outputText.color = Color.white;
            _outputText.text = state.Error.Length > 0 ? ErrorLine(state)
                : state.Output.Length > 0 ? $"Output: {state.Output}" : string.Empty;
        }

        // A crash in red. When the program printed something first, that stays visible above it.
        static string ErrorLine(KeepState state)
        {
            var error = $"<color=#{ColorUtility.ToHtmlStringRGB(ErrorColor)}>{state.Error}</color>";
            return state.Output.Length > 0 ? $"Output: {state.Output}\n{error}" : error;
        }

        // Variables, then the evaluation steps. The newest line is highlighted.
        void RenderGateRows(KeepState state)
        {
            if (_gateRows == null) return;

            var lines = state.HasRows ? state.WatchLines() : null;
            var count = lines == null ? 0 : lines.Count;
            for (var i = 0; i < _gateRows.Length; i++)
            {
                var used = i < count;
                _gateRows[i].gameObject.SetActive(used);
                if (!used) continue;

                _gateRows[i].text = lines[i];
                _gateRows[i].color = i == count - 1 ? FlashColor : Color.white;
            }
        }

        // Log Reader / Test Runner: a header row, then the newest lines that fit.
        void RenderReport(KeepState state)
        {
            if (_logRows == null || _logRows.Length == 0) return;

            var report = state.Report;
            var tests = report.Count > 0 && (report[0].Kind == ReportKind.Red || report[0].Kind == ReportKind.Green);
            var lineRows = _logRows.Length - 1;
            var first = Mathf.Max(0, report.Count - lineRows);

            for (var i = 0; i < _logRows.Length; i++)
            {
                var index = first + i - 1;
                var used = state.HasReport && (i == 0 || index < report.Count);
                _logRows[i].gameObject.SetActive(used);
                if (!used) continue;

                if (i == 0)
                {
                    _logRows[i].text = tests ? "TEST RUNNER" : report.Count == 0 ? "LOG READER: empty" : "LOG READER";
                    _logRows[i].color = ReaderColor;
                    continue;
                }

                var line = report[index];
                switch (line.Kind)
                {
                    case ReportKind.Red:
                        _logRows[i].text = $"RED    {line.Text}";
                        _logRows[i].color = ErrorColor;
                        break;
                    case ReportKind.Green:
                        _logRows[i].text = $"GREEN  {line.Text}";
                        _logRows[i].color = GreenColor;
                        break;
                    case ReportKind.Error:
                        _logRows[i].text = $"> {line.Text}";
                        _logRows[i].color = ErrorColor;
                        break;
                    default:
                        _logRows[i].text = $"> {line.Text}";
                        _logRows[i].color = Color.white;
                        break;
                }
            }
        }

        public void Flash(int chestIndex)
        {
            if (chestIndex < 0 || chestIndex >= _chestImages.Length) return;
            StartCoroutine(FlashRoutine(_chestImages[chestIndex]));
        }

        static IEnumerator FlashRoutine(Image image)
        {
            for (var t = 0f; t < 0.4f; t += Time.deltaTime)
            {
                image.color = Color.Lerp(FlashColor, Color.white, t / 0.4f);
                yield return null;
            }
            image.color = Color.white;
        }

        static void PlaceThread(Image thread, Vector2 from, Vector2 to)
        {
            var delta = to - from;
            var rect = thread.rectTransform;
            rect.anchoredPosition = (from + to) / 2f;
            rect.sizeDelta = new Vector2(delta.magnitude, rect.sizeDelta.y);
            rect.localRotation = Quaternion.Euler(0f, 0f, Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg);
            thread.gameObject.SetActive(true);
        }
    }
}
