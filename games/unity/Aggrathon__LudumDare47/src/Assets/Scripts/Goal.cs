using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Goal : MonoBehaviour
{
    public bool checkpoint = false;
    AudioSource audio;

    private void Start()
    {
        audio = GetComponent<AudioSource>();
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        var chr = other.GetComponent<CommandStreamCharacter>();
        if (chr != null && chr.activePlayer)
        {
            if ((GameManager.instance != null) && GameManager.instance.SetSpawn(transform.position) && (audio != null))
                audio.Play();
            if (!checkpoint)
                StartCoroutine(DelayedNextLevel());
        }
    }

    public void NextLevel()
    {
        int nextScene = (SceneManager.GetActiveScene().buildIndex + 1) % SceneManager.sceneCountInBuildSettings;
        SceneManager.LoadScene(nextScene, LoadSceneMode.Single);
    }

    IEnumerator DelayedNextLevel()
    {
        yield return new WaitForSeconds(1.3f);
        NextLevel();
    }
}
