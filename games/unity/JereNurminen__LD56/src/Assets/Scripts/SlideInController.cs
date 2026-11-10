using System;
using System.Collections;
using System.Linq;
using UnityEngine;

public enum ScreenType
{
    LevelDone,
    GameOver,
    GameDone
}

public class SlideInController : MonoBehaviour
{
    public float slideDuration = 1f;
    public ScreenType screenType;
    private RectTransform panelRectTransform;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        panelRectTransform = GetComponentsInChildren<RectTransform>()
            .Where(rectTransform => rectTransform.name == "Panel")
            .First();
    }

    public void SlideIn(Action onComplete = null)
    {
        StartCoroutine(SlideInEffect(onComplete));
    }

    IEnumerator SlideInEffect(Action onComplete = null)
    {
        float elapsedTime = 0f;
        Vector2 panelStartPosition = panelRectTransform.anchoredPosition;
        //Vector2 panelEndPosition = new(-panelStartPosition.x, -panelStartPosition.y);
        Vector2 panelEndPosition = new(50, 50);

        panelRectTransform.anchoredPosition = panelStartPosition;

        while (elapsedTime < slideDuration)
        {
            elapsedTime += Time.deltaTime;
            float t = Mathf.Clamp01(elapsedTime / slideDuration);

            panelRectTransform.anchoredPosition = Vector2.Lerp(
                panelStartPosition,
                panelEndPosition,
                t
            );

            yield return null;
        }

        onComplete?.Invoke();
    }
}
