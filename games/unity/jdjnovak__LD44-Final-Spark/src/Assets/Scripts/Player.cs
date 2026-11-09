using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Player : MonoBehaviour { 

    // Player Variables
    public float maxVelocity;
    public float currentVelocity;
    public float moveBuffer; // For controller use, care for accidental hits of the joystick
    public int maxHealth;
    public int currentHealth;
    public float frameLength;
    public PlayerStates.States currentState;
    public float minLightRange;
    public float maxLightRange;

    // Input Keys
    public KeyCode upKey;
    public KeyCode downKey;
    public KeyCode leftKey;
    public KeyCode rightKey;
    public KeyCode interactKey;

    // GameObject Components
    private SpriteRenderer sr;
    private Rigidbody2D rb;
    private Light lt;

    // Other Objects
    private Sprite[] player_sprites;
    [SerializeField]
    private int[] abilities;
    [SerializeField]
    private int currentSpriteFrame;
    [SerializeField]
    private int currentSpriteAnimation; // Based on player state
    private float lastFrameUpdate;

    // Start is called before the first frame update
    void Start() { 
        Init();
    }

    // Update is called once per frame
    void Update() {
        MovementUpdate();
        StateUpdate();
        SpriteUpdate();
        LightRangeUpdate();
        UpdateStatsFromAbilities();
        GameOver();
    }

    void Init() {
        sr = gameObject.GetComponent<SpriteRenderer>();
        rb = gameObject.GetComponent<Rigidbody2D>();
        lt = gameObject.GetComponentInChildren<Light>();
        abilities = new int[4] { 1,1,1,1 };
        player_sprites = Resources.LoadAll<Sprite>("spark_v2_w_fx");
        currentSpriteAnimation = 0;
        currentSpriteFrame = 0;
        maxHealth = currentHealth = 100;
        frameLength = 0.1f;
        lastFrameUpdate = Time.time;
    }

    void MovementUpdate() {
        if (Utilities.GetHypo(rb.velocity) <= maxVelocity) {
            rb.velocity = new Vector2(Mathf.Lerp(0, Input.GetAxis("Horizontal") * maxVelocity, 0.8f),
                                      Mathf.Lerp(0, Input.GetAxis("Vertical") * maxVelocity, 0.8f));
        }
    }

    void StateUpdate() {
        float healthPerc = (float)currentHealth / (float)maxHealth;
        if (healthPerc >= 0.81f) {
            currentState = PlayerStates.States.FullCharge;
        } else if (healthPerc >= 0.61f) {
            currentState = PlayerStates.States.HighCharge;
        } else if (healthPerc >= 0.41f) {
            currentState = PlayerStates.States.HalfCharge;
        } else if (healthPerc >= 0.21f) {
            currentState = PlayerStates.States.LowCharge;
        } else if (healthPerc >= 0.01f) {
            currentState = PlayerStates.States.NoCharge;
        } else if (healthPerc <= 0f) {
            currentState = PlayerStates.States.Dead;
        }
    }

    void SpriteAnimationUpdate() {
        currentSpriteAnimation = (int)currentState;
    }

    void SpriteFrameUpdate() {
        if (Time.time - lastFrameUpdate >= frameLength) {
            if (currentSpriteFrame == 3) {
                currentSpriteFrame = 0;
            } else {
                currentSpriteFrame++;
            }
            lastFrameUpdate = Time.time;
        }
        sr.sprite = player_sprites[currentSpriteFrame + (4 * currentSpriteAnimation)];
    }

    void SpriteUpdate() {
        SpriteAnimationUpdate();
        SpriteFrameUpdate();
    }

    void LightRangeUpdate() {
        lt.range = minLightRange + (((float)currentHealth / (float)maxHealth) * (maxLightRange - minLightRange));
    }

    bool IsInMapBounds() {
        return (transform.position.x >= -7.5f && transform.position.x <= 7.5f &&
                transform.position.y >= -7.5f && transform.position.y <= 7.5f);
    }

    bool IsPlayerDead() {
        return currentHealth <= 0;
    }

    void GameOver() {
        if (IsPlayerDead()) {
            SceneManager.LoadScene(2);
        }
    }

    // *************** Ability Upgrade Functions **************** //
    void UpdateStatsFromAbilities() {
        maxHealth = 100 + ((abilities[0] - 1) * 50);
        maxVelocity = 3 + (abilities[1] - 1);
    }

    // *************** Public functions ***************//
    public void TakeDamage(int damage) {
        currentHealth -= damage;
    }

    public bool IsDead() {
        return currentHealth <= 0;
    }

    public int GetCurrentHealth() {
        return currentHealth;
    }

    public int GetMaxHealth() {
        return maxHealth;
    }

    public void Heal(int amount) {
        currentHealth += amount;
    }

    public void SetHealthToMax() {
        currentHealth = maxHealth;
    }

    public void SetPlayerLightRange(float amount) {
        lt.range = amount;
    }

    public int[] GetPlayerAbilities() {
        return abilities;
    }

    public void IncrementPlayerAbilityLevel(int abl) {
        abilities[abl]++;
    }

    // ******************** Collision Functions ************************//
    private void OnCollisionEnter2D(Collision2D collision) {
        if (collision.gameObject.CompareTag("Pickup")) {
            Heal(20);
            if (currentHealth > maxHealth) {
                SetHealthToMax();
            }
        }
    }

    private void OnCollisionStay2D(Collision2D collision) {
        if (collision.gameObject.CompareTag("Shop") && Input.GetKey(interactKey)) {
            Canvas shopCanvas = GameObject.FindGameObjectWithTag("UI_Shop").GetComponentInChildren<Canvas>(true);
            ShopBehaviour sb = GameObject.FindGameObjectWithTag("UI_Shop").GetComponentInChildren<ShopBehaviour>(true);
            shopCanvas.enabled = true;
            sb.enabled = true;
            Time.timeScale = 0;
        }
    }
}
