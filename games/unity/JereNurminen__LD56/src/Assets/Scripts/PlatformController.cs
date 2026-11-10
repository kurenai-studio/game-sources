using System.Data.Common;
using System.Linq;
using UnityEngine;

public class PlatformController : MonoBehaviour
{
    public bool startOpen = false;
    public LayerMask launchLayers;
    public Vector2 launchBoxOffset;
    public Vector2 launchBoxSize;
    private Animator animator;
    private Animator stemAnimator;
    private Rigidbody2D rb;
    private Collider2D col;

    void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube((Vector2)transform.position + launchBoxOffset, launchBoxSize);
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        col = GetComponent<Collider2D>();
        animator = GetComponent<Animator>();
        stemAnimator = GetComponentsInChildren<Animator>()
            .Where(animator => animator.gameObject != gameObject)
            .First();

        animator.SetBool("is_open", startOpen);
        stemAnimator.SetBool("is_active", false);
    }

    public void Open()
    {
        animator.SetBool("is_open", true);
        stemAnimator.SetBool("is_active", !startOpen);
        col.enabled = false;
    }

    public void Close()
    {
        animator.SetBool("is_open", false);
        stemAnimator.SetBool("is_active", startOpen);

        var hits = Physics2D.OverlapBoxAll(
            (Vector2)transform.position + launchBoxOffset,
            launchBoxSize,
            0,
            launchLayers
        );

        foreach (Collider2D hit in hits)
        {
            var other = hit.gameObject;
            if (other.GetComponent<PlayerController>() != null)
            {
                other.GetComponent<PlayerController>().Jump();
            }
            else if (other.GetComponent<SheepController>() != null)
            {
                other.GetComponent<SheepController>().Jump(SheepJumpStrength.ExtraLong);
            }
        }
    }

    public void OnCloseAnimationComplete()
    {
        col.enabled = true;
    }

    // Update is called once per frame
    void Update() { }
}
