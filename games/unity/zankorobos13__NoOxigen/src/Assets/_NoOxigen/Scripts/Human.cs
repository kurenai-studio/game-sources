using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Human : MonoBehaviour
{
    public float speed = 2f;
    public bool isOnLedder = false;
    public Vector3 new_ledder_pos;
    public AudioClip[] step_sound_clips;

    private AudioSource audioSrc => GetComponent<AudioSource>();
    private Rigidbody2D _rb;  
    private bool isAbleToUseLedder = true;
    private bool isRunning;
    private bool isAbleToControl = true;

    public float distance_covered = 0f;
    void Start()
    {
        G.BreakingInteracted += OnBreakingInteracted;
        G.BreakingClosed += OnBreakingClosed;
        _rb = GetComponent<Rigidbody2D>();
    }

    private void Update()
    {
        gameObject.GetComponent<Animator>().SetBool("isRunning", isRunning);
        Rotate();
        if (Input.GetKeyDown(KeyCode.E) && isOnLedder && isAbleToUseLedder)
        {
            StartCoroutine(UseLedder());
        }
        distance_covered += Mathf.Abs(_rb.velocity.x) * Time.deltaTime;
        if (distance_covered > 0.5f)
        {
            distance_covered = 0;
            AudioClip step_clip = step_sound_clips[Random.Range(0, step_sound_clips.Length)];
            audioSrc.pitch = Random.Range(0.9f, 1.1f);
            audioSrc.PlayOneShot(step_clip, 0.3f);
        }
    }

    private void FixedUpdate() {
        Move();
    }

    private void Move()
    {
        float moveX = Input.GetAxis("Horizontal");

        if (Mathf.Abs(moveX) > 0.3f)
            isRunning = true;
        else
            isRunning = false;

        if (isAbleToControl)
            _rb.velocity = new Vector2(moveX*speed, 0);
        else
            _rb.velocity = Vector2.zero;
    }

    private void Rotate()
    {
        if(_rb.velocity.x > 0.05f && isRunning)
           gameObject.transform.Find("Body").gameObject.GetComponent<SpriteRenderer>().flipX = true;
        else if ((isRunning && _rb.velocity.x < -0.05f ) || !isRunning)
           gameObject.transform.Find("Body").gameObject.GetComponent<SpriteRenderer>().flipX = false;

    }

    private IEnumerator UseLedder()
    {
        gameObject.transform.position = new Vector3(-100, 0, 0);

        yield return new WaitForSeconds(0.05f);

        isAbleToUseLedder = false;
        gameObject.transform.position = new_ledder_pos;

        yield return new WaitForSeconds(0.25f);
        isAbleToUseLedder = true;
    }

    private void OnBreakingInteracted()
    {
        isAbleToControl = false;
    }

    private void OnBreakingClosed()
    {
        isAbleToControl = true;
    }
}
