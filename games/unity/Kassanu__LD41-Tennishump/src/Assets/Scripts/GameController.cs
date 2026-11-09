using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityStandardAssets.ImageEffects;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GameController : MonoBehaviour {

    [SerializeField] PlayerController pc;
    [SerializeField] Racket racket;
    [SerializeField] GameObject gameOverScreen;
    [SerializeField] int scoreMultiplier = 100;
    [SerializeField] Text scoreText, gameOverScoreText;
    [SerializeField] GameObject heartContainer, heartPrefab;
    [SerializeField] Sprite fullHeart, emptyHeart;
    public List<GameObject> heartContainerHearts;
    private AudioSource audioSource;
    [SerializeField] private AudioClip zombieEndSound;


    public int score = 0;
    public int Score
    {
        get
        {
            return score;
        }

        set
        {
            score = value;
        }
    }

    private int zombieKillCount = 0;
    public int ZombieKillCount
    {
        get
        {
            return zombieKillCount;
        }

        set
        {
            zombieKillCount = value;
        }
    }

    private int zombiesAlive = 0;
    public int ZombiesAlive
    {
        get
        {
            return zombiesAlive;
        }

        set
        {
            zombiesAlive = value;
        }
    }

    private void Awake() {
        this.audioSource = GetComponent<AudioSource>();
        this.scoreText.text = "Score: " + this.Score;
        this.gameOverScoreText.text = "Score: " + this.Score;
        CreateHearts();
    }

    private void CreateHearts() {
        float offset = 150f;
        Vector3 position = new Vector3(0, 0, 0);
        GameObject heart;
        RectTransform heartTransform;
        this.heartContainerHearts = new List<GameObject>();
        for (int i = 0; i < this.pc.Health; i++) {
            heart = Instantiate(this.heartPrefab, this.heartContainer.transform);
            heartTransform = heart.GetComponent<RectTransform>();
            heartTransform.localPosition += position;
            position.x += offset;
            heartContainerHearts.Add(heart);
        }
    }

    private void UpdateHearts() {
        if (this.pc.Health >= 0) {
            GameObject heart = this.heartContainerHearts[this.pc.Health];
            heart.GetComponent<Image>().overrideSprite = this.emptyHeart;
        }
    }

    public void RestartGame() {
        print("restarting");
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

    public void ZombieReachedEnd() {
        pc.DamagePlayer(1);
        UpdateHearts();
        this.zombiesAlive -= 1;
        this.audioSource.Stop();
        this.audioSource.PlayOneShot(this.zombieEndSound);
        if (!pc.IsAlive()) {
            print("Oh no! I is Dead");
            // TODO: end game
            Camera.main.gameObject.GetComponent<BlurOptimized>().enabled = true;
            racket.gameObject.SetActive(false);
            this.gameOverScreen.SetActive(true);
            Cursor.visible = true;
        }
    }
    
    public void AddToScore(int score) {
        this.Score += score * scoreMultiplier;
        this.scoreText.text = "Score: " + this.Score;
        this.gameOverScoreText.text = "Score: " + this.Score;
    }

    public void AddToZombieKillCount(int killCount) {
        this.ZombieKillCount += killCount;
        //print("Zombie was killed");
    }

    public float ChangeZombieWalkingVariation(float currentVariation) {
        float changedVariation = 1;

        if(ZombieKillCount < 5) {
            changedVariation = currentVariation * 1;
        }
        else if(ZombieKillCount >= 5 && ZombieKillCount < 8) {
            changedVariation = currentVariation * 2;
        }
        else if (ZombieKillCount >= 8 && ZombieKillCount < 10) {
            changedVariation = currentVariation * 3;
        }
        else if (ZombieKillCount >= 10)
        {
            changedVariation = currentVariation * 4;
        }

        return changedVariation;

    }

    public float ChangeZombieSpawnTimeVariation(float currentVariation) {
        float changedVariation = 1;

        if (ZombieKillCount < 5)
        {
            changedVariation = 0;
        }
        else if (ZombieKillCount >= 5 && ZombieKillCount < 8)
        {
            changedVariation = currentVariation * 0.75f;
        }
        else if (ZombieKillCount >= 8 && ZombieKillCount < 10)
        {
            changedVariation = currentVariation* 1.00f;
        }
        else if (ZombieKillCount >= 10)
        {
            changedVariation = currentVariation * 1.25f;
        }

        return changedVariation;
    }
}
