using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class TutorialController : MonoBehaviour
{
    public Player player;
    public Text mainText;
    public Image blackoutPanel;


    public string[] texts;
    public string finalMessageText;

    private int index = 0;

    public static TutorialController instance;

    public void Awake()
    {
        if (instance == null)
        {
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(gameObject);
            DontDestroyOnLoad(gameObject);
        }
    }

    private void Start()
    {
        mainText.text = texts[index];
    }

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            if (index < texts.Length - 1)
            {
                index++;
                mainText.text = texts[index];
            }

            if (index == 2)
            {
                player.tutorialMove = true;
            }
        }
    }

    public void ShowFinalMessage()
    {
        StartCoroutine(FinalMessage(blackoutPanel, 0, 1, 3));
    }

    public Color GetColor(Color color, float alpha)
    {
        color.a = alpha;
        return color;
    }

    IEnumerator FinalMessage(Image img, float start, float end, float delay)
    {
        index = texts.Length;
        mainText.text = finalMessageText;

        Color startColor = img.color;

        float t = 0;
        float n = delay;
        while (t <= n)
        {
            img.color = GetColor(startColor, Mathf.Lerp(start, end, t / n));
            t += Time.deltaTime;
            yield return null;
        }
        img.color = GetColor(startColor, end);

        yield return new WaitForSeconds(5f);

        SceneManager.LoadScene("Main", LoadSceneMode.Single);
    }
}
