using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelManager : MonoBehaviour
{
    List<Goblin> goblins;
    Animator animator;

    int openLayer;
    public bool isOpen = false;

    AudioSource audioSource;
    public AudioClip openSound;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        openLayer = LayerMask.NameToLayer("Exit");

        GameObject[] goblinObjects = GameObject.FindGameObjectsWithTag("Goblin");
        goblins = new List<Goblin>();
        foreach (GameObject gob in goblinObjects) {
            Goblin goblin = gob.GetComponent<Goblin>();
            goblins.Add(goblin);
        }

        InvokeRepeating("CheckGoblins", 1f, 1f);
        audioSource = GetComponent<AudioSource>();
    }

    IEnumerator FinishGame()
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync("Congratulations");

        while (!asyncLoad.isDone)
        {
            yield return null;
        }
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        if (other.gameObject.tag == "Player")
        {
            StartCoroutine(FinishGame());
        }
    }

    public void Open()
    {
        isOpen = true;
        gameObject.layer = openLayer;
    }

    void CheckGoblins()
    {
        foreach (Goblin goblin in goblins) {
            if (goblin.alive && !goblin.polymorphed) {
                return;
            }
        }

        animator.SetBool("Open", true);
        audioSource.PlayOneShot(openSound, 1);
        CancelInvoke();
    }

    // Update is called once per frame
    void Update()
    {
    }
}
