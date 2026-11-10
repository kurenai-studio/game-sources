using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Character : MonoBehaviour
{

    public float speed;
    public Text height;

    public Animator fallAnimation;
    public Rigidbody rb;

    void Start() {
        fallAnimation = GetComponent<Animator>();
        rb = GetComponent<Rigidbody>();
    }

    void Update()
    {
        if(GameManager.dead || GameManager.alive) return;
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");

        Vector3 direction = new Vector3(horizontal, 0, vertical);
        this.gameObject.transform.Translate(direction.normalized * Time.deltaTime * speed);

        if(Mathf.Round(transform.position.y) < 2) height.text = "0 meters";
        else if(Mathf.Round(transform.position.y) > 0) height.text = Mathf.Round(transform.position.y) + " meters";
    }

    void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.tag == "Saver" && !GameManager.dead)
        {
            GameManager.alive = true;
            fallAnimation.enabled = false;
            rb.isKinematic = true;
            rb.useGravity = false;
            rb.velocity = Vector3.zero;
        }

        if (collision.gameObject.tag == "Death" && !GameManager.alive)
        {
            GameManager.dead = true;
            fallAnimation.enabled = false;
            rb.isKinematic = true;
            rb.useGravity = false;
            rb.velocity = Vector3.zero;
        }
    }
}
