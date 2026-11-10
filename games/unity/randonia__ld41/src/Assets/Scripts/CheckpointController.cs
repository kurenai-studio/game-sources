using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CheckpointController : MonoBehaviour
{
    private GameController mGameController;
    private Renderer mRenderer;
    public GameObject WinScreenUI;
    public GameObject mConfettiSystem;
    private ParticleSystem mConfetti;

    public string PlaytimeStr
    {
        get
        {
            return string.Format("{0}:{1:00}", Mathf.FloorToInt(mGameController.Playtime / 60), Mathf.FloorToInt(mGameController.Playtime % 60));
        }
    }

    // Use this for initialization
    private void Start()
    {
        Debug.Assert(WinScreenUI != null);
        mRenderer = GetComponent<Renderer>();
        mGameController = GameObject.Find("GameController").GetComponent<GameController>();
        mConfetti = mConfettiSystem.GetComponent<ParticleSystem>();
    }

    // Update is called once per frame
    private void Update()
    {
        Vector2 offset = mRenderer.material.mainTextureOffset;
        offset.x += 0.01f;
        mRenderer.material.mainTextureOffset = offset;
    }

    public void OpenTweetLink()
    {
        string tweetStr = string.Format("https://twitter.com/intent/tweet?text=I%20can't%20believe%20I%20beat%20%40zambini845%20's%20ridiculous%20game%20in%20only%20{0}!%20https%3A%2F%2Fldjam.com%2Fevents%2Fludum-dare%2F41%2Fhypata-kortti&hashtags=LDJAM%2CLDJAM41", PlaytimeStr);
        Application.OpenURL(tweetStr);
    }

    private void OnTriggerEnter(Collider other)
    {
        mConfetti.Play();
        mGameController.WinGame();
        Debug.Log("Player Completed the game!");
        WinScreenUI.SetActive(true);
        GameObject playTimeUI = GameObject.Find("PlayTimeTextUI");
        playTimeUI.GetComponent<Text>().text = string.Format("Playtime: {0}", PlaytimeStr);
    }
}