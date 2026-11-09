using System;
using Codebound.Core;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Codebound.UI
{
    public class NameLookPanelController : MonoBehaviour
    {
        static readonly Color LookNormal = new Color(0.55f, 0.55f, 0.55f);
        static readonly Color LookSelected = Color.white;

        [SerializeField] TMP_InputField _nameInput;
        [SerializeField] TMP_Text _counterText;
        [SerializeField] TMP_Text _previewText;
        [SerializeField] Button[] _lookButtons;
        [SerializeField] TMP_Text[] _selectedLabels;
        [SerializeField] Button _startButton;
        [SerializeField] Button _backButton;

        int _selectedLook = LookCatalog.DefaultId;

        public event Action<PlayerSave> Started;
        public event Action Cancelled;

        public GameObject InitialFocus => _nameInput.gameObject;

        void Awake()
        {
            _nameInput.characterLimit = PlayerNameRules.MaxLength;
            _nameInput.lineType = TMP_InputField.LineType.SingleLine;
            _nameInput.onValidateInput = (text, index, character) =>
                PlayerNameRules.IsAllowedChar(character) ? character : '\0';
            _nameInput.onValueChanged.AddListener(_ => Refresh());
            _nameInput.onSubmit.AddListener(_ => OnStartClicked());

            for (var i = 0; i < _lookButtons.Length; i++)
            {
                var index = i;
                _lookButtons[i].onClick.AddListener(() => SelectLook(index));
            }

            _startButton.onClick.AddListener(OnStartClicked);
            _backButton.onClick.AddListener(() => Cancelled?.Invoke());
        }

        void OnEnable()
        {
            _nameInput.text = string.Empty;
            SelectLook(LookCatalog.DefaultId);
            Refresh();
        }

        void Update()
        {
            if (!Input.GetKeyDown(KeyCode.LeftArrow) && !Input.GetKeyDown(KeyCode.RightArrow)) return;
            if (EventSystem.current == null) return;

            var focused = IndexOfLookButton(EventSystem.current.currentSelectedGameObject);
            if (focused >= 0 && focused != _selectedLook) SelectLook(focused);
        }

        void OnStartClicked()
        {
            Started?.Invoke(new PlayerSave
            {
                playerName = PlayerNameRules.Clean(_nameInput.text),
                lookId = _selectedLook
            });
        }

        void SelectLook(int index)
        {
            _selectedLook = LookCatalog.Normalize(index);

            for (var i = 0; i < _lookButtons.Length; i++)
            {
                var isSelected = i == _selectedLook;
                var colors = _lookButtons[i].colors;
                colors.normalColor = isSelected ? LookSelected : LookNormal;
                _lookButtons[i].colors = colors;
                _selectedLabels[i].text = isSelected ? "Selected" : string.Empty;
            }
        }

        void Refresh()
        {
            var typed = _nameInput.text;
            _counterText.text = $"{typed.Length}/{PlayerNameRules.MaxLength}";
            _previewText.text =
                $"\"Welcome, {PlayerNameRules.Clean(typed)}. Everything is on fire. Mostly figuratively.\"";
        }

        int IndexOfLookButton(GameObject candidate)
        {
            for (var i = 0; i < _lookButtons.Length; i++)
                if (_lookButtons[i].gameObject == candidate) return i;
            return -1;
        }
    }
}
