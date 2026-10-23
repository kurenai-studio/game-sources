using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace SimpleRPG
{
    /// <summary>
    /// Lớp hiệu ứng hình ảnh dựng hoàn toàn bằng code (không cần chỉnh scene):
    ///  - Post-processing URP: bloom, vignette, tinh chỉnh màu
    ///  - Nhấp đỏ viền màn hình khi người chơi bị đau
    ///  - Hạt tia lửa / mảnh vỡ (có pool, không cấp phát lại)
    ///  - Bóng đổ dưới chân quái
    /// Tự khởi động sau khi scene tải; nếu project không dùng URP thì chỉ bỏ phần post-processing.
    /// </summary>
    public class VisualFX : MonoBehaviour
    {
        public static VisualFX Instance { get; private set; }

        private const int MaxLiveParticles = 220;

        private Vignette _vignette;
        private Volume _volume;
        private float _baseVignette = 0.3f;
        private float _pulse;

        private Transform _particleRoot;
        private readonly Stack<FxParticle> _pool = new Stack<FxParticle>();
        private int _live;

        private static Sprite _particleSprite;
        private static Sprite _shadowSprite;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            if (Instance != null) return;
            new GameObject("VisualFX").AddComponent<VisualFX>();
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            var rootGo = new GameObject("FxParticles");
            rootGo.transform.SetParent(transform, false);
            _particleRoot = rootGo.transform;

            SetupPostProcessing();

            if (_hasPendingAmbient)
            {
                _hasPendingAmbient = false;
                ApplyAmbient(_pendingTint, _pendingHalfW, _pendingHalfH);
            }
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        // ───────────────────────── Post-processing ─────────────────────────

        private void SetupPostProcessing()
        {
            if (!(GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset)) return;

            EnsureCameraPostProcessing();

            var profile = ScriptableObject.CreateInstance<VolumeProfile>();

            var bloom = profile.Add<Bloom>(true);
            bloom.threshold.Override(0.85f);
            bloom.intensity.Override(0.55f);
            bloom.scatter.Override(0.65f);

            _vignette = profile.Add<Vignette>(true);
            _vignette.intensity.Override(_baseVignette);
            _vignette.smoothness.Override(0.55f);
            _vignette.color.Override(Color.black);

            var adjust = profile.Add<ColorAdjustments>(true);
            adjust.saturation.Override(12f);
            adjust.contrast.Override(8f);

            var volGo = new GameObject("PostFXVolume");
            volGo.transform.SetParent(transform, false);
            var volume = volGo.AddComponent<Volume>();
            volume.isGlobal = true;
            volume.priority = 50f;
            volume.sharedProfile = profile;
            _volume = volume;
        }

        private bool _cameraReady;

        /// <summary>Bật post-processing trên camera chính. Thử lại sau nếu camera chưa tồn tại lúc khởi động.</summary>
        private void EnsureCameraPostProcessing()
        {
            var cam = Camera.main;
            if (cam == null) return;

            var camData = cam.GetUniversalAdditionalCameraData();
            if (camData == null) return;

            camData.renderPostProcessing = true;
            _cameraReady = true;
        }

        private void Update()
        {
            if (!_cameraReady && _volume != null && Time.frameCount % 30 == 0)
                EnsureCameraPostProcessing();

            // F3 bật/tắt hậu kỳ cho máy yếu hoặc ai thấy chói
            if (_volume != null && InputHelper.GetToggleFxDown())
                _volume.enabled = !_volume.enabled;

            if (_vignette == null) return;

            if (_pulse > 0f)
                _pulse = Mathf.MoveTowards(_pulse, 0f, Time.unscaledDeltaTime * 2.2f);

            _vignette.intensity.value = Mathf.Lerp(_baseVignette, 0.55f, _pulse);
            _vignette.color.value = Color.Lerp(Color.black, new Color(0.65f, 0f, 0.05f), _pulse);
        }

        /// <summary>Nhấp đỏ viền màn hình (gọi khi người chơi bị đau).</summary>
        public static void DamagePulse(float strength = 1f)
        {
            if (Instance == null) return;
            Instance._pulse = Mathf.Clamp01(Mathf.Max(Instance._pulse, strength));
        }

        // ───────────────────────── Hạt ─────────────────────────

        /// <summary>Bắn một chùm hạt toả ra từ vị trí pos.</summary>
        public static void Burst(Vector3 pos, Color color, int count, float speed, float life)
        {
            if (Instance == null) return;
            Instance.DoBurst(pos, color, count, speed, life);
        }

        private void DoBurst(Vector3 pos, Color color, int count, float speed, float life)
        {
            if (_particleSprite == null)
                _particleSprite = SpriteFactory.CreateCircle(8, Color.white, Color.clear, 0);

            // Khi quá đông thì giảm số hạt để giữ khung hình
            if (_live > MaxLiveParticles) count = Mathf.Max(1, count / 3);
            if (_live > MaxLiveParticles * 2) return;

            for (int i = 0; i < count; i++)
            {
                FxParticle p = _pool.Count > 0 ? _pool.Pop() : CreateParticle();
                float angle = Random.value * Mathf.PI * 2f;
                float spd = speed * Random.Range(0.4f, 1f);
                Vector2 vel = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * spd;

                // Hơi sáng/tối ngẫu nhiên cho tự nhiên
                float shade = Random.Range(0.8f, 1.15f);
                Color c = new Color(Mathf.Clamp01(color.r * shade), Mathf.Clamp01(color.g * shade), Mathf.Clamp01(color.b * shade), 1f);

                p.Begin(this, pos, vel, c, life * Random.Range(0.7f, 1.1f), Random.Range(0.5f, 1.1f));
                _live++;
            }
        }

        private FxParticle CreateParticle()
        {
            var go = new GameObject("P");
            go.transform.SetParent(_particleRoot, false);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = _particleSprite;
            sr.sortingOrder = 14;
            var p = go.AddComponent<FxParticle>();
            p.Init(sr);
            return p;
        }

        private void Recycle(FxParticle p)
        {
            _live = Mathf.Max(0, _live - 1);
            p.gameObject.SetActive(false);
            _pool.Push(p);
        }

        public class FxParticle : MonoBehaviour
        {
            private SpriteRenderer _sr;
            private VisualFX _owner;
            private Vector2 _vel;
            private Color _color;
            private float _life, _t, _scale;

            public void Init(SpriteRenderer sr) { _sr = sr; }

            public void Begin(VisualFX owner, Vector3 pos, Vector2 vel, Color color, float life, float scale)
            {
                _owner = owner;
                _vel = vel;
                _color = color;
                _life = Mathf.Max(0.05f, life);
                _scale = scale;
                _t = 0f;
                transform.position = pos;
                transform.localScale = Vector3.one * scale;
                _sr.color = color;
                gameObject.SetActive(true);
            }

            private void Update()
            {
                _t += Time.deltaTime;
                if (_t >= _life)
                {
                    _owner.Recycle(this);
                    return;
                }

                float k = _t / _life;
                transform.position += (Vector3)(_vel * Time.deltaTime);
                _vel *= Mathf.Max(0f, 1f - 4.5f * Time.deltaTime);

                transform.localScale = Vector3.one * (_scale * (1f - k * 0.7f));
                _sr.color = new Color(_color.r, _color.g, _color.b, 1f - k * k);
            }
        }

        // ───────────────────────── Bụi môi trường ─────────────────────────

        private readonly List<AmbientMote> _motes = new List<AmbientMote>();
        private const int MoteCount = 34;

        /// <summary>Đặt bụi/đốm sáng lơ lửng trong phòng, tô theo màu bioma của tầng.</summary>
        public static void SetAmbient(Color tint, float halfWidth, float halfHeight)
        {
            if (Instance == null)
            {
                // Chưa khởi động xong: nhớ lại để áp dụng ngay khi Awake
                _hasPendingAmbient = true;
                _pendingTint = tint;
                _pendingHalfW = halfWidth;
                _pendingHalfH = halfHeight;
                return;
            }
            Instance.ApplyAmbient(tint, halfWidth, halfHeight);
        }

        private static bool _hasPendingAmbient;
        private static Color _pendingTint;
        private static float _pendingHalfW, _pendingHalfH;

        private void ApplyAmbient(Color tint, float halfW, float halfH)
        {
            if (_particleSprite == null)
                _particleSprite = SpriteFactory.CreateCircle(8, Color.white, Color.clear, 0);

            while (_motes.Count < MoteCount)
            {
                var go = new GameObject("Mote");
                go.transform.SetParent(_particleRoot, false);
                var sr = go.AddComponent<SpriteRenderer>();
                sr.sprite = _particleSprite;
                sr.sortingOrder = 9;
                var m = go.AddComponent<AmbientMote>();
                m.Init(sr);
                _motes.Add(m);
            }

            foreach (var m in _motes)
                m.Configure(tint, halfW, halfH);
        }

        public class AmbientMote : MonoBehaviour
        {
            private SpriteRenderer _sr;
            private Color _tint = Color.white;
            private float _halfW = 11f, _halfH = 7f;
            private float _speed, _phase, _twinkle, _baseAlpha, _sway;

            public void Init(SpriteRenderer sr) { _sr = sr; }

            public void Configure(Color tint, float halfW, float halfH)
            {
                _tint = tint;
                _halfW = halfW + 0.5f;
                _halfH = halfH + 0.5f;
                _speed = Random.Range(0.15f, 0.45f);
                _phase = Random.value * 10f;
                _twinkle = Random.Range(0.8f, 2.2f);
                _baseAlpha = Random.Range(0.12f, 0.32f);
                _sway = Random.Range(0.15f, 0.4f);
                transform.position = new Vector3(Random.Range(-_halfW, _halfW), Random.Range(-_halfH, _halfH), 0f);
                transform.localScale = Vector3.one * Random.Range(0.35f, 0.9f);
            }

            private void Update()
            {
                Vector3 p = transform.position;
                p.y += _speed * Time.deltaTime;
                p.x += Mathf.Sin(Time.time * 0.7f + _phase) * _sway * Time.deltaTime;
                if (p.y > _halfH) { p.y = -_halfH; p.x = Random.Range(-_halfW, _halfW); }
                transform.position = p;

                float a = _baseAlpha * (0.55f + 0.45f * Mathf.Sin(Time.time * _twinkle + _phase));
                _sr.color = new Color(_tint.r, _tint.g, _tint.b, Mathf.Max(0f, a));
            }
        }

        // ───────────────────────── Hiệu ứng lên cấp ─────────────────────────

        /// <summary>Vòng sáng vàng-xanh toả ra khi người chơi lên cấp.</summary>
        public static void LevelUpBurst(Vector3 pos)
        {
            if (Instance == null) return;
            Burst(pos + Vector3.up * 0.3f, new Color(1f, 0.92f, 0.45f), 26, 6f, 0.8f);
            Burst(pos + Vector3.up * 0.3f, new Color(0.5f, 0.95f, 1f), 14, 3.5f, 0.7f);
        }

        // ───────────────────────── Bóng đổ ─────────────────────────

        /// <summary>Thêm bóng elip mờ dưới chân một thực thể (bỏ qua nếu đã có).</summary>
        public static void AddShadow(Transform target, SpriteRenderer body)
        {
            if (target == null || body == null || body.sprite == null) return;
            if (target.Find("Shadow") != null) return;

            if (_shadowSprite == null)
                _shadowSprite = SpriteFactory.CreateCircle(32, new Color(0f, 0f, 0f, 0.38f), Color.clear, 0);

            Bounds b = body.sprite.bounds;
            float width = Mathf.Max(0.5f, b.size.x * 0.8f);

            var go = new GameObject("Shadow");
            go.transform.SetParent(target, false);
            go.transform.localPosition = new Vector3(0f, b.min.y + 0.1f, 0f);
            go.transform.localScale = new Vector3(width, width * 0.34f, 1f);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = _shadowSprite;
            sr.sortingOrder = 8;
        }
    }
}
