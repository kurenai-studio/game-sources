using Codebound.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.UI
{
    // Draws RoomFlow.Screen and forwards clicks. No rules live here.
    public class RoomFlowPresenter : MonoBehaviour
    {
        static readonly Color CorrectColor = new Color(0.5f, 0.95f, 0.5f);
        static readonly Color CloseColor = new Color(1f, 0.85f, 0.3f);
        static readonly Color WrongColor = new Color(1f, 0.45f, 0.4f);

        [SerializeField] TMP_Text _promptText;
        [SerializeField] TMP_Text _bodyText;
        [SerializeField] TMP_Text _noticeText;
        [SerializeField] TMP_Text _verdictText;
        [SerializeField] Button[] _optionButtons;
        [SerializeField] TMP_Text[] _optionLabels;
        [SerializeField] Button _nextButton;
        [SerializeField] TMP_Text _nextLabel;
        [SerializeField] Button _hintButton;
        [SerializeField] TMP_Text _hintLabel;

        RoomFlow _flow;

        public void Init(RoomFlow flow)
        {
            _flow = flow;
            for (var i = 0; i < _optionButtons.Length; i++)
            {
                var index = i;
                _optionButtons[i].onClick.AddListener(() => _flow.Pick(index));
            }
            _nextButton.onClick.AddListener(_flow.Next);
            _hintButton.onClick.AddListener(_flow.Hint);
            _flow.Changed += Render;
            Render();
        }

        void OnDestroy()
        {
            if (_flow != null) _flow.Changed -= Render;
        }

        static Color ColorFor(Verdict verdict)
        {
            switch (verdict)
            {
                case Verdict.Correct: return CorrectColor;
                case Verdict.Close: return CloseColor;
                default: return WrongColor;
            }
        }

        void Render()
        {
            var screen = _flow.Screen;
            _promptText.text = screen.Prompt;
            _bodyText.gameObject.SetActive(screen.Options.Count == 0);
            _bodyText.text = screen.Body;
            _noticeText.text = screen.Notice;
            _verdictText.text = screen.VerdictTitle;
            _verdictText.color = screen.Verdict.HasValue ? ColorFor(screen.Verdict.Value) : Color.white;

            for (var i = 0; i < _optionButtons.Length; i++)
            {
                var used = i < screen.Options.Count;
                _optionButtons[i].gameObject.SetActive(used);
                if (!used) continue;

                _optionLabels[i].text = screen.Options[i];
                var mark = i < screen.OptionMarks.Count ? screen.OptionMarks[i] : null;
                _optionButtons[i].image.color = mark.HasValue ? ColorFor(mark.Value) : Color.white;
            }

            _nextButton.gameObject.SetActive(screen.NextLabel != null);
            _nextButton.interactable = screen.NextEnabled;
            _nextLabel.text = screen.NextLabel ?? string.Empty;

            _hintButton.gameObject.SetActive(screen.HintVisible);
            _hintLabel.text = screen.HintLabel;
        }
    }
}
