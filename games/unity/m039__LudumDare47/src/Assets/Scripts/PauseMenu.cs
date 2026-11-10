using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PauseMenu : MonoBehaviour
{
    public Transform canvas;

    private void Awake()
    {
        canvas.gameObject.SetActive(false);
    }

    public void QuitGame()
    {
        Application.Quit();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetButtonDown("Cancel"))
        {
            var isPaused = canvas.gameObject.activeSelf;

            Time.timeScale = isPaused ? 1.0f : 0.0f;

            canvas.gameObject.SetActive(!isPaused);
        }
    }

    
}
