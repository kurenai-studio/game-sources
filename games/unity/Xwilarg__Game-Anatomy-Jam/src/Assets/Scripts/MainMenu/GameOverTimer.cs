using System.Collections;
using UnityEngine.SceneManagement;
using UnityEngine;

public class GameOverTimer : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(LoadMainMenu());
    }
    public IEnumerator LoadMainMenu()
    {
        yield return new WaitForSeconds(3f);
        SceneManager.LoadScene("MainMenu");

    }

}
