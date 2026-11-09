using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Bullet : MonoBehaviour
{
    public float lifetime;
    public float damage = 5;
    public float speed = 10;
    public ParticleSystem explosionParticle;

    async void Start()
    {
        var body = GetComponent<Rigidbody>();

        while (lifetime > 0)
        {
            await Awaitable.NextFrameAsync();
            body.linearVelocity = transform.forward * speed;
            lifetime -= Time.deltaTime;
        }

        var explosion = Instantiate(explosionParticle);
        explosion.transform.position = transform.position;
        Destroy(gameObject);
    }

    void OnCollisionEnter(Collision collision)
    {
        lifetime = 0;
        if (collision.collider.TryGetComponent(out PlayerController player))
            player.GetHit(transform, damage);
        if (collision.collider.TryGetComponent(out Enemy enemy))
            enemy.GetHit(transform, damage);
        if (collision.body?.TryGetComponent(out Dragon dragon) ?? false)
        {
            dragon.getShot = true;
            dragon.health -= damage;
        }
    }
}
