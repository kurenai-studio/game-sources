using AnatomyJam.Character;
using AnatomyJam.Player;
using UnityEngine;


namespace AnatomyJam.SceneObjects.Station
{
    public class TimerStation : AStation
    {
        [SerializeField]
        private ProgressBar _progress;

        [SerializeField]
        private float _maxTimer = 3f;

        private AudioSource _source;

        private float _timer = -1f;

        private SceneObject _obj;
        private PlayerController _pc;

        public bool IsTimerActive => _timer > 0f;

        public override void Deposit(PlayerController pc, SceneObject obj)
        {
            _pc = pc;
            _obj = obj;
            _timer = _maxTimer;
            _progress.gameObject.SetActive(true);
            _source.Play();
        }

        private void Start()
        {
            _source = GetComponent<AudioSource>();
        }

        private void Update()
        {
            if (_timer > 0f)
            {
                _timer -= Time.deltaTime;
                if (_timer <= 0f)
                {
                    _timer = 0f;
                    var result = GetRecipe(_obj);
                    _source.Stop();
                    ThrowOnFloor(_pc, _obj, result, 0f, null);
                    _progress.gameObject.SetActive(false);
                }
                else
                {
                    _progress.SetValue(_timer / _maxTimer);
                }
            }
        }
    }
}

