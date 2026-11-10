using System.Collections;
using System.Collections.Generic;
using UnityEngine;
 using UnityEngine.Events;

public class Health : MonoBehaviour
{
    public int maxHealth;
    public int startingHealth;
    public int currentHealth;
    public UnityEvent OnHealthZero;
    
    AudioSource audioSource;
    public AudioClip hurtSound;

    // Start is called before the first frame update
    void Start()
    {
        currentHealth = startingHealth;
        audioSource = GetComponent<AudioSource>();
    }

    public void TakeDamage(int damage)
    {
        currentHealth -= damage;
        if (currentHealth <= 0) {
            OnHealthZero.Invoke();
        }
        audioSource.PlayOneShot(hurtSound, 1f);
    }

    public void Heal(int amount)
    {
        currentHealth += amount;
        if (currentHealth > maxHealth) {
            currentHealth = maxHealth;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
