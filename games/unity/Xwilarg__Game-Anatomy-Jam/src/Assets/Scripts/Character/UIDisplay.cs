using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace AnatomyJam.Character
{
    public class UIDisplay : MonoBehaviour
    {
        [SerializeField]
        private Image _background;

        [SerializeField]
        private SO.CharacterInfo _info;

        [SerializeField]
        private ProgressBar _health, _mana;

        [SerializeField]
        private TMP_Text _name;

        [SerializeField]
        private Image _image;

        [SerializeField]
        private SpriteRenderer _sprite;

        private Animator _anim;

        private Color _backgroundBaseColor;

        public SO.CharacterInfo Info => _info;

        private void Awake()
        {
            if (_background != null)
            {
                _background.color = _backgroundBaseColor;
            }
            _anim = _sprite.GetComponent<Animator>();
        }

        public void Toggle(bool value)
        {
            _name.gameObject.SetActive(value);
            _health.gameObject.SetActive(value);
            _sprite.gameObject.SetActive(value);
        }

        public void Init(SO.CharacterInfo info)
        {
            _name.text = info.Name;
            _health.SetValue(1f);
            if (_background != null)
            {
                _backgroundBaseColor = _background.color;
            }
            if (_image != null)
            {
                _image.gameObject.SetActive(true);
            }
        }

        public void UpdateSprite(Sprite s)
        {
            _sprite.sprite = s;
        }

        public void ToggleWalkAnimation(bool state)
        {
            if (_anim != null)
            {
                _anim.SetBool("IsWalking", state);
            }
        }

        public void TriggerAttackAnimation()
        {
            if (_anim != null)
            {
                _anim.SetTrigger("Attack");
            }
        }

        public void UpdateHealth(float value)
        {
            _health.SetValue(value);
            if (value == 0)
            {
                _sprite.gameObject.SetActive(false);
                if (_image != null)
                {
                    _image.gameObject.SetActive(false);
                }
                if (_background != null)
                {
                    _background.color = new Color(_backgroundBaseColor.r / 2f, _backgroundBaseColor.g / 2f, _backgroundBaseColor.b / 2f, _backgroundBaseColor.a);
                }
            }
        }
    }
}