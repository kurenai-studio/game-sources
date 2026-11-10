using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;

public class PlayerController : MonoBehaviour
{

    [SerializeField]
    private float speed = 0.1f;

    [SerializeField]
    private float barkDistance = 2;

    private Gamestate gamestate;

    private Animator doggoAnimator;

    private AudioSource audioSource;

    void Start()
    {
        gamestate = GameObject.Find("Gamestate").GetComponent<Gamestate>();
        doggoAnimator = GetComponent<Animator>();
        audioSource = GetComponent<AudioSource>();
    }

    void Update()
    {
        if (!gamestate.IsGameOver())
        {
            int rotation = 0;
            int keysPressed = 0;

            bool aPressed = false;
            bool sPressed = false;

            if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
            {
                gameObject.transform.position += Vector3.forward * speed * Time.deltaTime;
                PlayRunningAnimation();
                keysPressed++;
                rotation += 180;
            }
            if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
            {
                gameObject.transform.position += Vector3.back * speed * Time.deltaTime;
                PlayRunningAnimation();
                keysPressed++;
                rotation += 360;
                sPressed = true;
            }
            if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
            {
                gameObject.transform.position += Vector3.left * speed * Time.deltaTime;
                PlayRunningAnimation();
                keysPressed++;
                rotation += 90;
                aPressed = true;
            }
            if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
            {
                gameObject.transform.position += Vector3.right * speed * Time.deltaTime;
                PlayRunningAnimation();
                keysPressed++;
                rotation += 270;
            }
            if(Input.GetKey(KeyCode.Space))
            {
                Bark();
            }

            //Hotfix, because I'm too lazy to think now ;)
            if(aPressed && sPressed)
            {
                keysPressed = 1;
                rotation = 45;
            }


            if (!Input.anyKey || keysPressed == 0)
            {
                StopRunningAnimation();
            } else
            {
                gameObject.transform.rotation = Quaternion.Euler(0, rotation / keysPressed, 0);
            }
        }
        else
        {
            if (Input.GetKeyUp(KeyCode.R))
            {
                SceneManager.LoadScene(SceneManager.GetActiveScene().name);
            }
        }

        if (Input.GetKeyUp(KeyCode.Escape))
        {
            Application.Quit();
        }
    }

    private void Bark()
    {
        List<BarkTarget> possibleBarkTargets = new List<BarkTarget>();
        possibleBarkTargets.AddRange(FindObjectsOfType<WolfController>());
        possibleBarkTargets.AddRange(FindObjectsOfType<SheepController>());

        Debug.Log("Found barktargets! " + possibleBarkTargets.Count);

        foreach(BarkTarget target in possibleBarkTargets)
        {
            Vector3 diffToPlayer = target.gameObject.transform.position - gameObject.transform.position;
            if (diffToPlayer.sqrMagnitude < barkDistance * barkDistance)
            {
                Debug.Log("Magnitude2: " + diffToPlayer.sqrMagnitude);
                target.OnBark();
            }
        }

        audioSource.Play();
    }

    private void PlayRunningAnimation()
    {
        doggoAnimator.SetTrigger("Run");
        doggoAnimator.ResetTrigger("Stop");
    }

    private void StopRunningAnimation()
    {
        doggoAnimator.SetTrigger("Stop");
        doggoAnimator.ResetTrigger("Run");
    }
}
