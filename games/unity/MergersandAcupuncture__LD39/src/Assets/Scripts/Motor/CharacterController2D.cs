// Original kinematic 2D mover written for this game-sources snapshot of
// MergersandAcupuncture/LD39. It replaces the upstream copy of
// prime31/CharacterController2D (CC BY-NC-SA 3.0), which cannot be
// redistributed here.
//
// Keeps the class name and the API used by PlayerMotor: isGrounded,
// velocity, and move(Vector3). Licensed Apache-2.0, same as the rest of
// this snapshot.

using UnityEngine;

[RequireComponent(typeof(BoxCollider2D))]
public class CharacterController2D : MonoBehaviour
{
    public bool isGrounded { get; private set; }
    public Vector3 velocity { get; private set; }

    const float Skin = 0.02f;
    const float GroundProbe = 0.06f;

    BoxCollider2D box;
    Rigidbody2D body;
    readonly RaycastHit2D[] hits = new RaycastHit2D[8];
    ContactFilter2D filter;

    void Awake()
    {
        box = GetComponent<BoxCollider2D>();
        body = GetComponent<Rigidbody2D>();
        if (body != null)
        {
            body.isKinematic = true;
            body.gravityScale = 0f;
            body.freezeRotation = true;
        }

        filter = new ContactFilter2D();
        filter.useTriggers = false;
        filter.SetLayerMask(Physics2D.GetLayerCollisionMask(gameObject.layer));
        filter.useLayerMask = true;
    }

    public void move(Vector3 delta)
    {
        var pos = body != null ? body.position : (Vector2)transform.position;
        var start = pos;

        if (Mathf.Abs(delta.x) > 0.0001f)
        {
            var sign = Mathf.Sign(delta.x);
            var allowed = Sweep(pos, new Vector2(sign, 0f), Mathf.Abs(delta.x));
            pos.x += sign * allowed;
            ApplyPosition(pos);
        }

        isGrounded = false;
        var yAbs = Mathf.Abs(delta.y);
        if (yAbs > 0.0001f)
        {
            var sign = Mathf.Sign(delta.y);
            var allowed = Sweep(pos, new Vector2(0f, sign), yAbs);
            if (sign < 0f && allowed < yAbs - 0.0001f)
                isGrounded = true;
            pos.y += sign * allowed;
            ApplyPosition(pos);
        }

        if (!isGrounded)
        {
            var count = box.Cast(Vector2.down, filter, hits, GroundProbe + Skin);
            for (var i = 0; i < count; i++)
            {
                if (hits[i].collider != null && hits[i].distance <= GroundProbe + Skin)
                {
                    isGrounded = true;
                    break;
                }
            }
        }

        var dt = Time.deltaTime;
        velocity = dt > 0.00001f ? (Vector3)(pos - start) / dt : Vector3.zero;
    }

    float Sweep(Vector2 currentPos, Vector2 direction, float distance)
    {
        ApplyPosition(currentPos);
        var count = box.Cast(direction, filter, hits, distance + Skin);
        var allowed = distance;
        for (var i = 0; i < count; i++)
        {
            if (hits[i].collider == null)
                continue;
            var space = hits[i].distance - Skin;
            if (space < allowed)
                allowed = Mathf.Max(0f, space);
        }
        return allowed;
    }

    void ApplyPosition(Vector2 pos)
    {
        var z = transform.position.z;
        if (body != null)
            body.position = pos;
        transform.position = new Vector3(pos.x, pos.y, z);
    }
}
