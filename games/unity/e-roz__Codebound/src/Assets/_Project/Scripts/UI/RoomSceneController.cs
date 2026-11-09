using System;
using System.Collections;
using System.IO;
using Codebound.App;
using Codebound.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Codebound.UI
{
    public class RoomSceneController : MonoBehaviour
    {
        const float RunDelay = 0.7f;

        [SerializeField] TMP_Text _ticketText;
        [SerializeField] CodePanelView _codePanel;
        [SerializeField] KeepView _keepView;
        [SerializeField] RoomFlowPresenter _flowView;
        [SerializeField] Button _runButton;
        [SerializeField] Button _stepButton;
        [SerializeField] Button _resetButton;
        [SerializeField] Button _backButton;
        [SerializeField] Button _chestClassButton;
        [SerializeField] GameObject _chestClassBox;
        [SerializeField] TMP_Text _chestClassText;
        [SerializeField] AudioSource _sfxSource;
        [SerializeField] AudioClip _clickClip;

        readonly KeepState _state = new KeepState();
        RoomSession _session;
        RoomFlow _flow;
        TracePlayer _player;
        Coroutine _running;

        bool IsRunning => _running != null;

        void Start()
        {
            if (!AllReferencesAssigned()) return;

            var roomId = string.IsNullOrEmpty(GameSession.SelectedRoomId) ? Room11.Id : GameSession.SelectedRoomId;
            if (!RoomLibrary.TryCreate(roomId, out var room))
            {
                Debug.LogError($"RoomSceneController: no room with id '{roomId}'.", this);
                SceneLoader.LoadKeepMap();
                return;
            }

            _session = new RoomSession(room);
            _flow = new RoomFlow(_session, _state);
            if (GameServices.Save.TryLoad(out var player) && !string.IsNullOrWhiteSpace(player.playerName))
                _flow.PlayerName = player.playerName;
            _flow.Changed += RefreshButtons;
            _flow.Completed += OnCompleted;
            _flow.LeaveRequested += SceneLoader.LoadKeepMap;
            _session.StepChanged += OnStepChanged;

            _ticketText.text = $"Ticket: {room.Ticket}";
            _codePanel.SetCode(room.CodeLines);
            _chestClassText.text = room.SupportCode;
            _chestClassBox.SetActive(false);
            _chestClassButton.gameObject.SetActive(room.HasSupportCode);
            _chestClassButton.GetComponentInChildren<TMP_Text>().text = "Class code";

            _runButton.onClick.AddListener(OnRun);
            _stepButton.onClick.AddListener(() => { if (!IsRunning) _player.Step(); });
            _resetButton.onClick.AddListener(OnResetClicked);
            _backButton.onClick.AddListener(SceneLoader.LoadKeepMap);
            _chestClassButton.onClick.AddListener(() => _chestClassBox.SetActive(!_chestClassBox.activeSelf));
            foreach (var button in FindObjectsOfType<Button>(true))
                button.onClick.AddListener(PlayClick);

            BindPlayer(_session.Trace);
            _flowView.Init(_flow);
        }

        void OnDestroy()
        {
            if (_player != null)
            {
                _player.EventPlayed -= OnEventPlayed;
                _player.WasReset -= OnReset;
            }
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape)) SceneLoader.LoadKeepMap();
        }

        // The Keep and the code panel follow whichever trace is being watched: the room's own, or a chosen fix.
        void BindPlayer(TracePlayer player)
        {
            if (_player != null)
            {
                _player.EventPlayed -= OnEventPlayed;
                _player.WasReset -= OnReset;
            }

            _player = player;
            _player.EventPlayed += OnEventPlayed;
            _player.WasReset += OnReset;
            OnReset();
        }

        void OnStepChanged(RoomStep step)
        {
            if (step == RoomStep.Prove)
            {
                StopRun();
                _codePanel.SetCode(_session.CurrentFix.CodeLines);
                BindPlayer(_session.FixTrace);
                _running = StartCoroutine(RunRoutine());
            }
            RefreshButtons();
        }

        void OnRun()
        {
            if (IsRunning || !_player.HasNext) return;
            _running = StartCoroutine(RunRoutine());
            RefreshButtons();
        }

        IEnumerator RunRoutine()
        {
            while (_player.HasNext)
            {
                _player.Step();
                yield return new WaitForSeconds(RunDelay);
            }
            _running = null;
            RefreshButtons();
            _flow.Refresh();
        }

        void StopRun()
        {
            if (_running == null) return;
            StopCoroutine(_running);
            _running = null;
        }

        void OnResetClicked()
        {
            StopRun();
            _player.Reset();
        }

        void OnEventPlayed(TraceEvent e)
        {
            _state.Apply(e);
            _keepView.Render(_state);
            _codePanel.Highlight(_state.CurrentLine);
            if (e.Type == TraceEventType.ObjectMutated) _keepView.Flash(_state.ChestIndex(e.ObjectId));
            RefreshButtons();
            _flow.Refresh();
            if (_session.Step == RoomStep.Prove && !_player.HasNext) _flow.FixReplayFinished();
        }

        void OnReset()
        {
            _state.Clear();
            _keepView.Render(_state);
            _codePanel.Highlight(0);
            RefreshButtons();
        }

        void RefreshButtons()
        {
            if (_flow == null || _player == null) return;

            var canReplay = _flow.Screen.CanReplay;
            var canPlay = canReplay && !IsRunning && _player.HasNext;
            _runButton.interactable = canPlay;
            _stepButton.interactable = canPlay;
            _resetButton.interactable = canReplay && (IsRunning || _player.Position > 0);
        }

        void OnCompleted(int stars)
        {
            if (!GameServices.Save.TryLoad(out var save)) return;

            UnlockRules.Record(save.progress, _session.Room.Id, stars);
            if (_session.Room.HasEnding) save.endingSeen = true;
            try
            {
                GameServices.Save.Save(save);
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                Debug.LogError($"Could not save your stars: {e.Message}");
            }
        }

        void PlayClick()
        {
            _sfxSource.volume = GameServices.Settings.Settings.sfxVolume;
            _sfxSource.PlayOneShot(_clickClip);
        }

        bool AllReferencesAssigned()
        {
            var references = new (string name, UnityEngine.Object value)[]
            {
                (nameof(_ticketText), _ticketText), (nameof(_codePanel), _codePanel), (nameof(_keepView), _keepView),
                (nameof(_flowView), _flowView), (nameof(_runButton), _runButton), (nameof(_stepButton), _stepButton),
                (nameof(_resetButton), _resetButton), (nameof(_backButton), _backButton),
                (nameof(_chestClassButton), _chestClassButton), (nameof(_chestClassBox), _chestClassBox),
                (nameof(_chestClassText), _chestClassText), (nameof(_sfxSource), _sfxSource),
                (nameof(_clickClip), _clickClip)
            };

            var ok = true;
            foreach (var (name, value) in references)
            {
                if (value != null) continue;
                Debug.LogError($"RoomSceneController: '{name}' is not assigned in the Inspector.", this);
                ok = false;
            }
            return ok;
        }
    }
}
