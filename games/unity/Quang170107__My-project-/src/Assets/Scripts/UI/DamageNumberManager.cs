using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SimpleRPG
{
    public class DamageNumberManager : MonoBehaviour
    {
        public static DamageNumberManager Instance { get; private set; }

        private Font _defaultFont;
        private readonly Queue<GameObject> _pool = new Queue<GameObject>(64);
        private Transform _poolRoot;

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            _defaultFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (_defaultFont == null)
            {
                _defaultFont = Font.CreateDynamicFontFromOSFont("Arial", 24);
            }

            var poolGo = new GameObject("DamagePopup_Pool");
            poolGo.transform.SetParent(transform);
            _poolRoot = poolGo.transform;

            // Pre-warm pool with 16 popups to avoid any runtime allocation hitch
            for (int i = 0; i < 16; i++)
            {
                var item = CreatePopupInstance();
                item.SetActive(false);
                item.transform.SetParent(_poolRoot, false);
                _pool.Enqueue(item);
            }
        }

        private GameObject CreatePopupInstance()
        {
            var go = new GameObject("DamagePopup");

            var canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.WorldSpace;
            canvas.sortingOrder = 100;

            var rect = go.GetComponent<RectTransform>();
            rect.sizeDelta = new Vector2(2f, 1f);
            rect.localScale = Vector3.one * 0.02f;

            var textGo = new GameObject("Text");
            textGo.transform.SetParent(go.transform, false);

            var text = textGo.AddComponent<Text>();
            text.font = _defaultFont;
            text.fontSize = 44;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.raycastTarget = false;

            var outline = textGo.AddComponent<Outline>();
            outline.effectColor = new Color(0f, 0f, 0f, 0.85f);
            outline.effectDistance = new Vector2(2f, -2f);

            var textRect = textGo.GetComponent<RectTransform>();
            textRect.sizeDelta = new Vector2(200f, 60f);

            go.AddComponent<FloatingTextAnimation>();
            return go;
        }

        public void SpawnNumber(Vector3 worldPos, int amount, Color color, string prefix = "")
        {
            GameObject popup = null;
            while (_pool.Count > 0)
            {
                popup = _pool.Dequeue();
                if (popup != null) break;
            }

            if (popup == null)
            {
                popup = CreatePopupInstance();
            }

            popup.transform.SetParent(null);
            popup.transform.position = worldPos + new Vector3(Random.Range(-0.25f, 0.25f), Random.Range(-0.1f, 0.1f), 0f);
            popup.SetActive(true);

            var text = popup.GetComponentInChildren<Text>();
            if (text != null)
            {
                text.text = prefix + amount;
                text.color = color;
            }

            var anim = popup.GetComponent<FloatingTextAnimation>();
            if (anim != null)
            {
                anim.Initialize(text, () => Recycle(popup));
            }
        }

        public void Recycle(GameObject popup)
        {
            if (popup == null) return;
            popup.SetActive(false);
            if (_poolRoot != null)
            {
                popup.transform.SetParent(_poolRoot, false);
            }
            _pool.Enqueue(popup);
        }
    }

    public class FloatingTextAnimation : MonoBehaviour
    {
        private Text _text;
        private float _elapsed = 0f;
        private const float Duration = 0.65f;
        private Vector3 _startPos;
        private Vector3 _targetPos;
        private System.Action _onComplete;

        public void Initialize(Text text, System.Action onComplete = null)
        {
            _text = text;
            _onComplete = onComplete;
            _startPos = transform.position;
            _targetPos = _startPos + Vector3.up * 0.9f;
            _elapsed = 0f;
        }

        private void Update()
        {
            _elapsed += Time.deltaTime;
            float t = _elapsed / Duration;

            if (t >= 1f)
            {
                if (_onComplete != null)
                {
                    _onComplete.Invoke();
                }
                else
                {
                    Destroy(gameObject);
                }
                return;
            }

            // Ease out float
            transform.position = Vector3.Lerp(_startPos, _targetPos, Mathf.Sin(t * Mathf.PI * 0.5f));

            // Punch scale at start then settle
            float scale = (t < 0.2f) ? Mathf.Lerp(0.015f, 0.025f, t / 0.2f) : Mathf.Lerp(0.025f, 0.018f, (t - 0.2f) / 0.8f);
            transform.localScale = Vector3.one * scale;

            // Fade out
            if (_text != null && t > 0.45f)
            {
                float fadeT = (t - 0.45f) / 0.55f;
                var c = _text.color;
                c.a = Mathf.Lerp(1f, 0f, fadeT);
                _text.color = c;
            }
        }
    }
}
