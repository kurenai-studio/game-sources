using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class Rumble : MonoBehaviour
{
    Rigidbody2D rb;

    public float magnitude = 0.3f;
    public float frequency = 3f;
    public AnimationCurve intensity;
    public float duration = 2f;
    public float cooldown = 6f;

    public AudioClip rumbleSound;

    float time;
    float maxTime;
    Vector2 origPos;
    bool sound;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
        origPos = rb.position;
        time = Time.time;
        maxTime = intensity.keys[intensity.length - 1].time * duration;
    }

    private void FixedUpdate()
    {
        float t = Time.time - time;
        if (t >= maxTime)
        {
            time += cooldown * Random.Range(0.9f, 1.1f);
            sound = true;
        }
        else if (t >= 0)
        {
            if (sound)
            {
                AudioManager.Play(rumbleSound, AudioManager.SoundType.Ambient);
                sound = false;
            }
            float offset = intensity.Evaluate(t / duration) * Mathf.Sin(t * Mathf.PI * frequency) * magnitude;
            rb.MovePosition(origPos + new Vector2(offset, 0f));
        }
    }
}
