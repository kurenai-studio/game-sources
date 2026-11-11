using System.Collections;
using UnityEngine;

public class DemonScript : MonoBehaviour
{
    public string Name;
    public float Scale = 1;

    public Rigidbody DemonBody;
    public AudioSource walkSound;

    public MeshRenderer Shadowcaster;
    public Transform SpritePole;
    public SpriteRenderer[] Bodies;
    public SpriteRenderer[] Heads;
    public SpriteRenderer[] Faces;
    public SpriteRenderer[] Horns;
    public SpriteRenderer[] Features;
    public SpriteRenderer[] FaceBlood;
    public SpriteRenderer[] HornsBlood;
    public SpriteRenderer[] Brains;
    public SpriteRenderer[] FacesClosed;

    public ParticleSystem Particles;

    private SpriteRenderer[][] partsArrays;
    private int[] sorting = new[] { 10, 20, 30, 10, 0, 40, 20, 40, 30 };

    [SerializeField]
    private DemonConfiguration _config;

    public DemonConfiguration config => _config;

    public DamageLevel damageLevel = new DamageLevel();

    public bool NoRunning = false;

    private float timeOffset;
    private float animationSpeed;
    private float angleOffset = 0;

    private float _timeUntilBlink;

    private Camera _cachedCamera;

    private enum State
    {
        Idle,
        Walking,
        IsHeld,
        Falling,
    }

    private State _state = State.Idle;
    public bool IsHeld => _state == State.IsHeld;

    private Vector3 _walkDirection;
    private Vector3 _prevPosition;

    void Start()
    {
        _cachedCamera = Camera.main;
        _timeUntilBlink = Random.Range(1.0f, 3.0f);
        timeOffset = Random.Range(0f, 5f);
        animationSpeed = Random.Range(0.9f, 1.1f);
        partsArrays = new SpriteRenderer[][] { Bodies, Heads, Faces, Horns, Features, FaceBlood, HornsBlood, Brains, FacesClosed };
        SpritePole.localScale = new Vector3(Scale, Scale * Mathf.Sqrt(2f), Scale);
        Shadowcaster.transform.localScale = new Vector3(Scale, Scale, Scale);
        if (_config == null)
        {
            Shuffle();
        }
        else
        {
            _config = new DemonConfiguration
            {
                HeadId = _config.HeadId == -1 ? Random.Range(0, Heads.Length) : _config.HeadId,
                FaceId = _config.FaceId == -1 ? Random.Range(0, Faces.Length) : _config.FaceId,
                HornsId = _config.HornsId == -1 ? Random.Range(0, Horns.Length) : _config.HornsId,
                BodyId = _config.BodyId == -1 ? Random.Range(0, Bodies.Length) : _config.BodyId,
                FeatureId = _config.FeatureId == -1 ? Random.Range(0, Features.Length) : _config.FeatureId,
            };
            ApplyConfig();
        }
        StartCoroutine(BehaviorCoroutine());
    }

    void FixedUpdate()
    {
        if (_state == State.Walking && Vector3.Distance(transform.position, _prevPosition) < 0.001f)
        {
            SetRandomDirection();
        }
        _prevPosition = transform.position;
    }

    void SetRandomDirection()
    {
        _walkDirection = new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)).normalized * Random.Range(3.5f, 4f);
    }

    void Update()
    {
        if (_state !=  State.Walking && walkSound.isPlaying)
            walkSound.Stop();

        switch (_state)
        {
            case State.Falling:
                IdleAnimation(animationSpeed * 3);
                if (transform.position.y < 1.0)
                {
                    _state = State.Walking;
                    walkSound.Play();
                    SetRandomDirection();
                }
                break;

            case State.IsHeld:
                IdleAnimation(animationSpeed * 3);
                break;

            case State.Idle:
                IdleAnimation(animationSpeed);
                break;

            case State.Walking:
                if (NoRunning)
                {
                    _state = State.Idle;
                    Update();
                }
                SpritePole.transform.rotation = Quaternion.identity;
                SpritePole.transform.Rotate(Vector3.up, _cachedCamera.transform.rotation.eulerAngles.y);
                SpritePole.localPosition = new Vector3(0, System.MathF.Sin(Time.time * animationSpeed * 10f + timeOffset) * 0.1f, 0);
                DemonBody.velocity = _walkDirection + Vector3.up * DemonBody.velocity.y;
                break;
        }

        for (var i = 0; i < sorting.Length; i++)
        {
            foreach (var part in partsArrays[i])
            {
                part.sortingOrder = sorting[i] - ((int)Vector3.Distance(_cachedCamera.transform.position, transform.position) * 100);
            }
        }

        HandleBlink();
    }

    void IdleAnimation(float animationSpeed)
    {
        SpritePole.localPosition = new Vector3(0, 0, 0);
        var angle = System.MathF.Sin(Time.time * animationSpeed + timeOffset) * 10 + angleOffset;
        SpritePole.transform.rotation = Quaternion.identity;
        SpritePole.transform.Rotate(_cachedCamera.transform.forward, angle);
        SpritePole.transform.Rotate(Vector3.up, _cachedCamera.transform.rotation.eulerAngles.y);
    }

    void HandleBlink()
    {
        _timeUntilBlink -= Time.deltaTime;
        if (_timeUntilBlink > 0) return;

        if (damageLevel.EyesClosed)
        {
            _timeUntilBlink = Random.Range(1.0f, 3.0f);
        }
        else
        {
            _timeUntilBlink = 0.1f;
        }

        damageLevel.EyesClosed = !damageLevel.EyesClosed;
        ApplyConfig();
    }

    void Shuffle()
    {
        _config = new DemonConfiguration
        {
            HeadId = Random.Range(0, Heads.Length),
            FaceId = Random.Range(0, Faces.Length),
            HornsId = Random.Range(0, Horns.Length),
            BodyId = Random.Range(0, Bodies.Length),
            FeatureId = Random.Range(0, Features.Length),
        };
        ApplyConfig();
    }

    IEnumerator BehaviorCoroutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(1f, 2f));
            switch (_state)
            {
                case State.Idle:
                    if (Random.Range(0f, 1f) < 0.1f)
                    {
                        _state = State.Walking;
                        SetRandomDirection();
                    }
                    break;
                case State.Walking:
                    if (Random.Range(0f, 1f) < 0.1f)
                    {
                        // Debug.Log("Stop Walking");
                        _state = State.Idle;
                    }
                    break;
                case State.IsHeld:
                    break;
            }
        }
    }

    public void SetConfig(DemonConfiguration config, DamageLevel damageLevel = null)
    {
        _config = config;
        if (damageLevel != null)
            this.damageLevel = damageLevel;

        ApplyConfig();
    }

    void ApplyConfig()
    {
        for (var i = 0; i < Heads.Length; i++)
            Heads[i].enabled = _config.HeadId == i;

        for (var i = 0; i < FacesClosed.Length; i++)
            FacesClosed[i].enabled = _config.FaceId == i && damageLevel.EyesClosed;

        for (var i = 0; i < Faces.Length; i++)
            Faces[i].enabled = _config.FaceId == i && !damageLevel.EyesClosed;

        for (var i = 0; i < Horns.Length; i++)
            Horns[i].enabled = _config.HornsId == i;

        for (var i = 0; i < Bodies.Length; i++)
            Bodies[i].enabled = _config.BodyId == i;

        for (var i = 0; i < Features.Length; i++)
            Features[i].enabled = _config.FeatureId == i;

        for (var i = 0; i < FaceBlood.Length; i++)
            FaceBlood[i].enabled = _config.FaceId == i && damageLevel.FaceBlood;

        for (var i = 0; i < HornsBlood.Length; i++)
            HornsBlood[i].enabled = _config.HornsId == i && damageLevel.HornsBlood;

        for (var i = 0; i < Brains.Length; i++)
            Brains[i].enabled = /*_config.HornsId == i &&*/ damageLevel.Brains;

    }

    public void StartBeHeld()
    {
        angleOffset = 180;
        Particles.Play();
        _state = State.IsHeld;
    }

    public void StopBeHeld()
    {
        angleOffset = 0;
        Particles.Play();
        _state = State.Falling;
    }
}
