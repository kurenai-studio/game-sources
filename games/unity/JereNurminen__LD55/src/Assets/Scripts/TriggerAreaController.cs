using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class TriggerAreaController : MonoBehaviour
{
    private BoxCollider2D boxCollider;
    public UnityEvent[] actions;

    // Start is called before the first frame update
    void Start() { }

    public void OnTriggerEnter2D(Collider2D other)
    {
        if (other.gameObject.CompareTag("Player"))
        {
            Debug.Log("Player entered trigger area");
            foreach (var a in actions)
            {
                a.Invoke();
            }
        }
    }

    // Update is called once per frame
    void Update() { }
}
