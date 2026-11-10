using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class PressurePlate : MonoBehaviour
{
    public UnityEvent onPressed;
    public UnityEvent onReleased;

    public SpriteRenderer visual;

    private int pressers;
    AudioSource audio;

    private void Start()
    {
        audio = GetComponent<AudioSource>();
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.isTrigger)
            return;
        pressers++;
        if (pressers == 1)
        {
            onPressed.Invoke();
            if (visual)
            {
                var scale = visual.transform.localScale;
                scale.y = 0.1f;
                visual.transform.localScale = scale;
                visual.color = Color.gray;
            }
            if (audio)
                audio.Play();
        }
    }

    private void OnTriggerExit2D(Collider2D other)
    {
        if (other.isTrigger)
            return;
        pressers--;
        if (pressers == 0)
        {
            onReleased.Invoke();
            if (visual)
            {
                var scale = visual.transform.localScale;
                scale.y = 0.2f;
                visual.transform.localScale = scale;
                visual.color = Color.white;
            }
            if (audio)
                audio.Play();
        }
    }
}
