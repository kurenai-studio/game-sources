using System.Collections;
using UnityEngine;

public class SwordController : MonoBehaviour
{
    public PlayerController _playerController;

    public float SwordDamage = 20f;
    public Transform sword;
    public Transform gun;
    public ParticleSystem gunParticles;
    public CapsuleCollider swordCollider;
    public Transform swordMountPoint;
    public Bullet bullet;
    public Transform bulletSpawn;

    public float prepareTime = 0.2f;
    public float swingTime = 0.2f;
    public float returnTime = 0.2f;

    public AnimationCurve hitCurve;

    public Transform Hit1Point0;
    public Transform Hit1Point1;
    public Transform Hit2Point0;
    public Transform Hit2Point1;

    public TrailRenderer trail;

    public int totalHitQueue = 2;

    private bool _nowHitting;
    private bool _attackBuffer;

    void Start()
    {
        swordCollider = sword.GetComponent<CapsuleCollider>();
        swordCollider.enabled = false;
        sword.parent = transform.parent;
    }

    void Update()
    {
        if (_nowHitting)
            return;
        sword.position = swordMountPoint.position;
        var angle = Quaternion.Angle(sword.rotation, swordMountPoint.rotation);
        var maxSpeed = Mathf.Clamp(Mathf.Pow(angle, 2f) / 3f, 50f, 3600f);
        if (Mathf.Abs(angle) > 0.0001f)
        {
            var lerp = Mathf.Min(angle, maxSpeed * Time.deltaTime) / angle;
            sword.rotation = Quaternion.Slerp(sword.rotation, swordMountPoint.rotation, lerp);
        }
    }

    public void Hit()
    {
        if (_nowHitting)
            _attackBuffer = true;
        else
            StartCoroutine(HitCoroutine(0));
    }


    public void Shoot()
    {
        StartCoroutine(ShootCoroutine());
    }

    IEnumerator ShootCoroutine()
    {
        gunParticles.Play();
        var spawnedBullet = Instantiate(bullet);
        spawnedBullet.transform.position = bulletSpawn.position;
        spawnedBullet.transform.rotation = bulletSpawn.rotation;

        _playerController.CameraShake(0.2f);

        var gunRollTime = 0.3f;
        var startTime = Time.time;

        while (Time.time < startTime + gunRollTime)
        {
            var delta = (Time.time - startTime) / gunRollTime;
            gun.transform.localEulerAngles = new Vector3(-delta * (360 + 30), 0, -90);
            yield return null;
        }

        var gunBackTime = 0.3f;
        startTime = Time.time;

        while (Time.time < startTime + gunBackTime)
        {
            var delta = (Time.time - startTime) / gunBackTime;
            gun.transform.localEulerAngles = new Vector3(Mathf.Lerp(-30, 0, delta), 0, -90);
            yield return null;
        }

        yield return null;
    }

    IEnumerator HitCoroutine(int hitNumber)
    {
        var (h0, h1) = hitNumber switch
        {
            0 => (Hit1Point0, Hit1Point1),
            1 => (Hit2Point0, Hit2Point1),
            _ => (null, null),
        };
        _nowHitting = true;

        var startPosition = sword.position;
        var startRotation = sword.rotation;
        var startTime = Time.time;

        while (Time.time < startTime + prepareTime)
        {
            var passedTime = Time.time - startTime;
            sword.position = Vector3.Lerp(startPosition, h0.position, passedTime / prepareTime);
            sword.rotation = Quaternion.Slerp(startRotation, h0.rotation, passedTime / prepareTime);
            yield return null;
        }

        startTime = Time.time;
        startPosition = sword.position;
        startRotation = sword.rotation;

        trail.emitting = true;
        swordCollider.enabled = true;
        while (Time.time < startTime + swingTime)
        {
            var passedTime = Time.time - startTime;
            var delta = hitCurve.Evaluate(passedTime / swingTime);

            sword.position = Vector3.Lerp(startPosition, h1.position, delta);
            sword.rotation = Quaternion.Slerp(startRotation, h1.rotation, delta);
            yield return null;
        }
        trail.emitting = false;
        swordCollider.enabled = false;

        startTime = Time.time;
        startPosition = sword.position;
        startRotation = sword.rotation;

        if (_attackBuffer)
        {
            var newHitNumber = (hitNumber + 1) % totalHitQueue;
            _attackBuffer = false;
            yield return HitCoroutine(newHitNumber);
        }
        else
        {
            while (Time.time < startTime + returnTime)
            {
                var passedTime = Time.time - startTime;
                var delta = passedTime / returnTime;

                sword.position = Vector3.Lerp(startPosition, swordMountPoint.position, delta);
                sword.rotation = Quaternion.Slerp(startRotation, swordMountPoint.rotation, delta);
                yield return null;
            }
        }


        _nowHitting = false;
    }
}
