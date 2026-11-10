using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class Storybook : MonoBehaviour
{
    public RectTransform pages;
    [SerializeField] Button nextButton;
    [SerializeField] Button prevButton;

    int currentPanel;
    bool eatFirstNext;

    void Start()
    {
        nextButton.onClick.AddListener(Continue);
        prevButton.onClick.AddListener(Previous);
        prevButton.gameObject.SetActive(false);
        currentPanel = 0;
        for (int i = 0; i < pages.childCount; i++)
        {
            pages.GetChild(i).gameObject.SetActive(false);
        }
        pages.GetChild(currentPanel).gameObject.SetActive(true);
        eatFirstNext = Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.Space);

    }

    void Update()
    {
        if (Input.GetKeyUp(KeyCode.LeftArrow) || Input.GetKeyUp(KeyCode.A))
            Previous();
        if (Input.GetKeyUp(KeyCode.RightArrow) || Input.GetKeyUp(KeyCode.D) || Input.GetKey(KeyCode.Space))
        {
            if (eatFirstNext)
                eatFirstNext = false;
            else
                Continue();
        }
    }

    public void Continue()
    {
        if (currentPanel < pages.childCount - 1)
        {
            prevButton.gameObject.SetActive(true);
            pages.GetChild(currentPanel).gameObject.SetActive(false);
            currentPanel++;
            pages.GetChild(currentPanel).gameObject.SetActive(true);
        }
        else
        {
            int nextScene = (SceneManager.GetActiveScene().buildIndex + 1) % SceneManager.sceneCountInBuildSettings;
            SceneManager.LoadScene(nextScene, LoadSceneMode.Single);
        }
    }

    public void Previous()
    {
        if (currentPanel > 0)
        {
            pages.GetChild(currentPanel).gameObject.SetActive(false);
            currentPanel--;
            pages.GetChild(currentPanel).gameObject.SetActive(true);
            if (currentPanel == 0)
                prevButton.gameObject.SetActive(false);
        }
    }
}
