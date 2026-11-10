using m039.Common;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class WelcomeScreen : MonoBehaviour
{
    [SerializeField]
    CanvasGroupFader _CanvasGroupFader;

    // Start is called before the first frame update
    IEnumerator Start()
    {
        yield return new WaitForSeconds(2.0f);

        yield return _CanvasGroupFader.FadeOut();

        yield return new WaitForSeconds(2.0f);

        yield return _CanvasGroupFader.FadeIn();

        SceneManager.LoadScene("Menu");
    }

}
