using UnityEngine;

public class BlockBreakController : MonoBehaviour
{
    private Animator animator;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        animator = GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update() { }

    public void OnStomp()
    {
        Debug.Log("Stomped on block");
        BoxCollider2D boxCollider = GetComponent<BoxCollider2D>();
        boxCollider.enabled = false;
        animator.SetTrigger("break");
    }

    public void OnAnimationEnd()
    {
        Destroy(gameObject);
    }
}
