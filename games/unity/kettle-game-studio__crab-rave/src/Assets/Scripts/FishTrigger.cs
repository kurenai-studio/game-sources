using UnityEngine;

public class FishTrigger : MonoBehaviour
{
    public Animator animator;

    void OnTriggerEnter(Collider other)
    {
        if (other.GetComponent<PlayerController>() == null){
            return;
        }

        animator.SetTrigger("Blink");
    }
}
