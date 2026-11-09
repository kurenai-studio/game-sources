using System.Collections;
using UnityEngine;

[RequireComponent(typeof(ScreenFader))]
public class LoadingScreen : MonoBehaviour
{
    private ScreenFader screenFader;

    private void Awake()
    {
        this.screenFader = GetComponent<ScreenFader>();
    }

    public IEnumerator FadeOnRoutine()
    {
        this.gameObject.SetActive(true);
        this.screenFader.FadeOn();
        yield return new WaitForSeconds(this.screenFader.FadeOnDuration);
    }

    public IEnumerator FadeOffRoutine()
    {
        this.screenFader.FadeOff();
        yield return new WaitForSeconds(this.screenFader.FadeOffDuration);
        this.gameObject.SetActive(false);
    }
}
