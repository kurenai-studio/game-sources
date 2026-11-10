using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

public class TitleManager : MonoBehaviour
{
    public string gameSceneName;
    public Camera mainCamera;

    private Vector2 mousePos;
    private BoxCollider2D button;

    // Start is called before the first frame update
    void Start()
    {
        button = GetComponent<BoxCollider2D>();
    }

    IEnumerator LoadGameScene(string sceneName)
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);

        while (!asyncLoad.isDone)
        {
            yield return null;
        }
    }

    void OnClick(InputValue value) {
        if (button.bounds.Contains(mousePos)) {
            StartCoroutine(LoadGameScene(gameSceneName));
        }
    }

    // Update is called once per frame
    void Update()
    {
        mousePos = mainCamera.ScreenToWorldPoint((Vector2)Mouse.current.position.ReadValue());
    }
}
