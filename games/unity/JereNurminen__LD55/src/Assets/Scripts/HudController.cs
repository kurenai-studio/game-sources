using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.UI;

public class HudController : MonoBehaviour
{
    public Sprite crowIcon;
    public Sprite ratIcon;
    public float deathScreenPanelTargetAlpha = 0.25f;
    public float deathScreenFadeDuration = 2.0f;
    private float timeSinceFadeStart = 0.0f;

    private Image summoningIcon;
    private Image deathImage;
    private GameObject deathScreenPanel;
    private Image winImage;
    private GameObject winScreenPanel;
    private Animator frameAnimator;
    private Animator deathScreenAnimator;

    private bool screenVisible = false;

    // Start is called before the first frame update
    void Start()
    {
        summoningIcon = GameObject.Find("SummoningIcon").GetComponent<Image>();
        frameAnimator = GameObject.Find("Frame").GetComponent<Animator>();

        deathScreenPanel = GameObject.Find("Death Screen").gameObject;
        deathScreenAnimator = deathScreenPanel.GetComponentInChildren<Animator>();
        deathImage = GameObject.Find("Death Message").GetComponent<Image>();

        winImage = GameObject.Find("Win Message").GetComponent<Image>();
        winScreenPanel = GameObject.Find("Win Screen").gameObject;

        deathScreenPanel.SetActive(false);
        winScreenPanel.SetActive(false);
    }

    public void ChangeIcon(SelectedSummon selectedSummon)
    {
        switch (selectedSummon)
        {
            case SelectedSummon.Crow:
                summoningIcon.sprite = crowIcon;
                break;
            default:
                summoningIcon.sprite = ratIcon;
                break;
        }
    }

    public IEnumerator Die()
    {
        frameAnimator.SetTrigger("die");
        deathScreenPanel.SetActive(true);
        screenVisible = true;
        yield return StartCoroutine(FadePanel(deathScreenPanel, deathImage));
        deathScreenAnimator.SetTrigger("start");
    }

    public IEnumerator Win()
    {
        winScreenPanel.SetActive(true);
        screenVisible = true;
        yield return StartCoroutine(FadePanel(winScreenPanel, winImage));
        winImage.enabled = true;
    }

    public void SetFilling(bool isFilling)
    {
        frameAnimator.SetBool("isFilling", isFilling);
    }

    IEnumerator FadePanel(GameObject panel, Image image)
    {
        Image panelImage = panel.GetComponent<Image>();
        Color panelColor = panelImage.color;
        Color skullColor = image.color;
        while (timeSinceFadeStart < deathScreenFadeDuration)
        {
            timeSinceFadeStart += Time.deltaTime;
            panelColor.a = Mathf.Lerp(
                0.0f,
                deathScreenPanelTargetAlpha,
                timeSinceFadeStart / deathScreenFadeDuration
            );
            skullColor.a = Mathf.Lerp(0.0f, 1.0f, timeSinceFadeStart / deathScreenFadeDuration);
            panelImage.color = panelColor;
            image.color = skullColor;
            yield return null;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (screenVisible && Input.GetKeyDown(KeyCode.R))
        {
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().name
            );
        }
    }
}
