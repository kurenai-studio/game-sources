using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PotionPickup : MonoBehaviour
{
    public int healAmount; 

    BoxCollider2D boxCollider;
    bool broken;
    Animator animator;

    AudioSource audioSource;
    public AudioClip healSound;
    public AudioClip breakSound;

    // Start is called before the first frame update
    void Start()
    {
        boxCollider = GetComponent<BoxCollider2D>();       
        animator = GetComponent<Animator>();       
        audioSource = GetComponent<AudioSource>();
    }

    public void Break()
    {
        animator.SetTrigger("Break");
        broken = true;
        audioSource.PlayOneShot(breakSound, 1f);
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        Health otherHealth = other.gameObject.GetComponent<Health>();
        if ( !broken && otherHealth ) {
            otherHealth.Heal(healAmount);
            audioSource.PlayOneShot(healSound, 1f);
            Destroy(gameObject);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
