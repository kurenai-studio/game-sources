using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class SirtetBlock : MonoBehaviour
{

    Rigidbody2D rb;
    Vector2 targetPos;
    float targetRot;
    bool move;
    bool rotate;
    bool down;

    float soundTime;

    public float speed = 3.0f;
    public float fastMult = 2.0f;
    public float moveSpeed = 4.0f;
    public float rotSpeed = 360f;
    public ColorPalette palette;

    public AudioClip dropSound;
    public AudioClip releaseSound;
    public AudioClip collideSound;

    private void OnEnable()
    {
        move = false;
        rotate = false;
        down = false;
        rb = GetComponent<Rigidbody2D>();
        rb.bodyType = RigidbodyType2D.Kinematic;
        rb.useFullKinematicContacts = true;
        Color c = palette.Sample();
        foreach (var renderer in GetComponentsInChildren<SpriteRenderer>())
        {
            renderer.color = c;
        }
        rb.sleepMode = RigidbodySleepMode2D.NeverSleep;
    }

    public void Down(bool on)
    {
        down = on;
    }

    public void Right()
    {
        if (!move)
            targetPos = rb.position;
        targetPos.x = Mathf.Round(targetPos.x + 1.0f);
        move = true;
    }

    public void Left()
    {
        if (!move)
            targetPos = rb.position;
        targetPos.x = Mathf.Round(targetPos.x - 1.0f);
        move = true;
    }

    public void RotateLeft()
    {
        if (!rotate)
            targetRot = rb.rotation;
        targetRot = Mathf.Round(targetRot / 90f - 1f) * 90f;
        rotate = true;
    }

    public void RotateRight()
    {
        if (!rotate)
            targetRot = rb.rotation;
        targetRot = Mathf.Round(targetRot / 90f + 1f) * 90f;
        rotate = true;
    }

    public void Drop()
    {
        Disable();
        if (Time.time - soundTime > 0.1f && dropSound)
        {
            AudioManager.Play(dropSound, rb.position, AudioManager.SoundType.SFX);
            soundTime = Time.time;
        }
    }

    private void FixedUpdate()
    {
        if (!move && !rotate)
        {
            if (down)
                rb.velocity = new Vector2(0, -speed * fastMult);
            else
                rb.velocity = new Vector2(0, -speed);
        }
        else
        {
            rb.velocity = Vector2.zero;
        }
        if (move)
        {
            var pos = Vector2.MoveTowards(rb.position, targetPos, moveSpeed * Time.fixedDeltaTime);
            if (Vector2.SqrMagnitude(pos - targetPos) < 0.0001)
            {
                rb.MovePosition(targetPos);
                move = false;
            }
            else
            {
                rb.MovePosition(pos);
            }
        }
        if (rotate)
        {
            var rot = Mathf.MoveTowardsAngle(rb.rotation, targetRot, rotSpeed * Time.fixedDeltaTime);
            if (Mathf.Abs(rot - targetRot) < 0.001)
            {
                rb.MoveRotation(targetRot);
                rotate = false;
            }
            else
            {
                rb.MoveRotation(rot);
            }

        }
    }

    private void OnCollisionEnter2D(Collision2D other)
    {
        if (enabled)
        {
            Disable();
            if (move || rotate)
            {
                rb.velocity *= 0.5f;
                rb.angularVelocity *= 0.5f;
            }
            else if (!down)
            {
                rb.velocity *= 0.25f;
                rb.angularVelocity *= 0.25f;
            }
            if (Time.time - soundTime > 0.1f && releaseSound)
            {
                AudioManager.Play(releaseSound, rb.position, AudioManager.SoundType.SFX);
                soundTime = Time.time;
            }
        }
        else if (Time.time - soundTime > 0.2f && rb.velocity.sqrMagnitude > 0.01f && collideSound)
        {
            AudioManager.Play(collideSound, rb.position, AudioManager.SoundType.SFX);
            soundTime = Time.time;
        }
    }

    void Disable()
    {
        rb.bodyType = RigidbodyType2D.Dynamic;
        rb.sleepMode = RigidbodySleepMode2D.StartAwake;
        rb.WakeUp();
        this.enabled = false;
    }
}
