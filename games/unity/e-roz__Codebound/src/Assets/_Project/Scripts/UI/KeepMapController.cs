using System;
using System.Collections.Generic;
using Codebound.App;
using Codebound.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.UI
{
    public class KeepMapController : MonoBehaviour
    {
        static readonly Color Bright = Color.white;
        static readonly Color Dimmed = new Color(0.45f, 0.45f, 0.45f);
        static readonly Color SelectedColor = new Color(1f, 0.8f, 0.4f);

        [SerializeField] KeepCatalogAsset _catalog;
        [SerializeField] Sprite[] _lookSprites;

        [Header("Wings")]
        [SerializeField] Image _portrait;
        [SerializeField] TMP_Text _nameText;
        [SerializeField] TMP_Text _starsText;
        [SerializeField] TMP_Text _talaText;
        [SerializeField] Button _menuButton;
        [SerializeField] Button[] _wingButtons;
        [SerializeField] TMP_Text[] _wingNames;
        [SerializeField] TMP_Text[] _wingStatuses;

        [Header("Rooms")]
        [SerializeField] TMP_Text _roomsTitle;
        [SerializeField] Button _roomsBackButton;
        [SerializeField] Button[] _doorButtons;
        [SerializeField] TMP_Text[] _doorLabels;
        [SerializeField] TMP_Text[] _doorStatuses;
        [SerializeField] TMP_Text _infoTitle;
        [SerializeField] TMP_Text _infoDetail;
        [SerializeField] Button _enterButton;

        [Header("Menu")]
        [SerializeField] Button _resumeButton;
        [SerializeField] Button _menuSettingsButton;
        [SerializeField] Button _menuTitleButton;
        [SerializeField] Button _confirmTitleYesButton;
        [SerializeField] Button _confirmTitleNoButton;

        MenuNavigator _navigator;
        PlayerSave _save;
        int _chapterIndex;
        int _selectedRoom = -1;
        GameObject _wingsFocus;

        public event Action<KeepRoom, string> EnterRoomRequested;

        public GameObject WingsFocus => _wingsFocus != null ? _wingsFocus : _wingButtons[0].gameObject;

        public GameObject RoomsFocus =>
            _selectedRoom >= 0 && _selectedRoom < _doorButtons.Length
                ? _doorButtons[_selectedRoom].gameObject
                : _doorButtons[0].gameObject;

        public GameObject MenuFocus => _resumeButton.gameObject;

        public GameObject ConfirmFocus => _confirmTitleNoButton.gameObject;

        IReadOnlyList<KeepChapter> Chapters => _catalog.chapters;

        public bool Init(MenuNavigator navigator)
        {
            if (!ReferencesOk()) return false;

            _navigator = navigator;
            _menuButton.onClick.AddListener(() => _navigator.Show(MenuScreen.KeepMenu));
            _resumeButton.onClick.AddListener(() => _navigator.Show(MenuScreen.KeepWings));
            _menuSettingsButton.onClick.AddListener(() => _navigator.Show(MenuScreen.Settings));
            _menuTitleButton.onClick.AddListener(() => _navigator.Show(MenuScreen.ConfirmTitle));
            _confirmTitleYesButton.onClick.AddListener(() => _navigator.Show(MenuScreen.Title));
            _confirmTitleNoButton.onClick.AddListener(() => _navigator.Show(MenuScreen.KeepMenu));
            _roomsBackButton.onClick.AddListener(() => _navigator.Show(MenuScreen.KeepWings));
            _enterButton.onClick.AddListener(OnEnter);

            for (var i = 0; i < _wingButtons.Length; i++)
            {
                var index = i;
                _wingButtons[i].onClick.AddListener(() => OnWing(index));
            }

            for (var i = 0; i < _doorButtons.Length; i++)
            {
                var index = i;
                _doorButtons[i].onClick.AddListener(() => SelectRoom(index));
            }
            return true;
        }

        public void Refresh(PlayerSave save)
        {
            if (_navigator == null || save == null) return;

            _save = save;
            RefreshWings();
            if (_selectedRoom < 0) _selectedRoom = DefaultRoom(_chapterIndex);
            RefreshRooms();
        }

        void RefreshWings()
        {
            var progress = _save.progress;
            var look = LookCatalog.Normalize(_save.lookId);
            if (look < _lookSprites.Length) _portrait.sprite = _lookSprites[look];

            _nameText.text = _save.playerName;
            _starsText.text = $"Stars {UnlockRules.TotalStars(Chapters, progress)} / {UnlockRules.MaxStars(Chapters)}";
            _talaText.text = KeepMapRules.TalaLine(_save.playerName,
                UnlockRules.CompletedRooms(Chapters, progress), KeepMapRules.IsMvpComplete(Chapters, progress));

            _wingsFocus = null;
            for (var i = 0; i < _wingButtons.Length; i++)
            {
                var inUse = i < Chapters.Count;
                _wingButtons[i].gameObject.SetActive(inUse);
                if (!inUse) continue;

                var state = UnlockRules.GetWingState(Chapters, i, progress);
                _wingNames[i].text = Chapters[i].name;
                _wingStatuses[i].text = KeepMapRules.WingStatus(Chapters, i, progress);
                _wingButtons[i].image.color = state == WingState.Sealed || state == WingState.Locked ? Dimmed : Bright;
                if (_wingsFocus == null && state == WingState.Open) _wingsFocus = _wingButtons[i].gameObject;
            }
        }

        void RefreshRooms()
        {
            var chapter = Chapters[_chapterIndex];
            var progress = _save.progress;
            _roomsTitle.text = $"Chapter {_chapterIndex + 1}: {chapter.name}";

            for (var j = 0; j < _doorButtons.Length; j++)
            {
                var inUse = j < chapter.rooms.Count;
                _doorButtons[j].gameObject.SetActive(inUse);
                if (!inUse) continue;

                var state = UnlockRules.GetRoomState(Chapters, _chapterIndex, j, progress);
                var stars = UnlockRules.GetStars(progress, chapter.rooms[j].id);
                _doorLabels[j].text = KeepMapRules.RoomLabel(_chapterIndex, j);
                _doorLabels[j].color = j == _selectedRoom ? SelectedColor : Bright;
                _doorStatuses[j].text = KeepMapRules.RoomStatus(state, stars);
                _doorButtons[j].image.color = state == RoomState.Locked ? Dimmed : Bright;
            }

            RefreshInfo(chapter);
        }

        void RefreshInfo(KeepChapter chapter)
        {
            if (_selectedRoom < 0 || _selectedRoom >= chapter.rooms.Count)
            {
                _infoTitle.text = string.Empty;
                _infoDetail.text = string.Empty;
                _enterButton.interactable = false;
                return;
            }

            var room = chapter.rooms[_selectedRoom];
            var state = UnlockRules.GetRoomState(Chapters, _chapterIndex, _selectedRoom, _save.progress);
            _infoTitle.text =
                $"{KeepMapRules.RoomLabel(_chapterIndex, _selectedRoom)}  {KeepMapRules.DisplayTitle(room, state)}";
            _infoDetail.text =
                $"Type: {KeepMapRules.DisplayType(room, state)} | Concept: {KeepMapRules.DisplayConcept(room, state)}";
            _enterButton.interactable = state != RoomState.Locked;
        }

        void OnWing(int index)
        {
            if (_save == null || index >= Chapters.Count) return;

            var state = UnlockRules.GetWingState(Chapters, index, _save.progress);
            if (state == WingState.Sealed || state == WingState.Locked) return;

            _chapterIndex = index;
            _selectedRoom = DefaultRoom(index);
            RefreshRooms();
            _navigator.Show(MenuScreen.KeepRooms);
        }

        void SelectRoom(int index)
        {
            _selectedRoom = index;
            RefreshRooms();
        }

        void OnEnter()
        {
            var rooms = Chapters[_chapterIndex].rooms;
            if (_selectedRoom < 0 || _selectedRoom >= rooms.Count) return;
            if (UnlockRules.GetRoomState(Chapters, _chapterIndex, _selectedRoom, _save.progress) == RoomState.Locked)
                return;

            EnterRoomRequested?.Invoke(rooms[_selectedRoom], KeepMapRules.RoomLabel(_chapterIndex, _selectedRoom));
        }

        int DefaultRoom(int chapterIndex)
        {
            var count = Chapters[chapterIndex].rooms.Count;
            for (var j = 0; j < count; j++)
                if (UnlockRules.GetRoomState(Chapters, chapterIndex, j, _save.progress) == RoomState.Open) return j;
            return 0;
        }

        bool ReferencesOk()
        {
            if (_catalog == null || _catalog.chapters.Count == 0)
            {
                Debug.LogError("KeepMapController: the Keep catalog is missing or empty.", this);
                return false;
            }

            var maxRooms = 0;
            foreach (var chapter in _catalog.chapters) maxRooms = Math.Max(maxRooms, chapter.rooms.Count);

            var ok = true;
            ok &= Check(_wingButtons != null && _wingButtons.Length >= _catalog.chapters.Count,
                "not enough wing buttons for the catalog");
            ok &= Check(_doorButtons != null && _doorButtons.Length >= maxRooms,
                "not enough door buttons for the largest chapter");
            ok &= Check(_wingButtons != null && _wingNames != null && _wingStatuses != null &&
                        _wingNames.Length == _wingButtons.Length && _wingStatuses.Length == _wingButtons.Length,
                "wing arrays must be the same length");
            ok &= Check(_doorButtons != null && _doorLabels != null && _doorStatuses != null &&
                        _doorLabels.Length == _doorButtons.Length && _doorStatuses.Length == _doorButtons.Length,
                "door arrays must be the same length");
            ok &= Check(_lookSprites != null && _lookSprites.Length > 0, "look sprites are not assigned");

            var singles = new (string name, UnityEngine.Object value)[]
            {
                (nameof(_portrait), _portrait), (nameof(_nameText), _nameText), (nameof(_starsText), _starsText),
                (nameof(_talaText), _talaText), (nameof(_menuButton), _menuButton),
                (nameof(_roomsTitle), _roomsTitle), (nameof(_roomsBackButton), _roomsBackButton),
                (nameof(_infoTitle), _infoTitle), (nameof(_infoDetail), _infoDetail),
                (nameof(_enterButton), _enterButton), (nameof(_resumeButton), _resumeButton),
                (nameof(_menuSettingsButton), _menuSettingsButton), (nameof(_menuTitleButton), _menuTitleButton),
                (nameof(_confirmTitleYesButton), _confirmTitleYesButton),
                (nameof(_confirmTitleNoButton), _confirmTitleNoButton)
            };
            foreach (var (name, value) in singles)
                ok &= Check(value != null, $"'{name}' is not assigned in the Inspector");
            return ok;
        }

        bool Check(bool condition, string message)
        {
            if (!condition) Debug.LogError("KeepMapController: " + message + ".", this);
            return condition;
        }
    }
}
