using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthPickup : MonoBehaviour
{
    public float frameLength;

    private SpriteRenderer sr;
    private Sprite[] pickup_sprites;
    private int currentSpriteFrame;
    private float lastFrameUpdate;

    // Start is called before the first frame update
    void Start()
    {
        Init();
    }

    // Update is called once per frame
    void Update()
    {
        SpriteUpdate();
    }

    void Init() {
        sr = gameObject.GetComponent<SpriteRenderer>();
        pickup_sprites = Resources.LoadAll<Sprite>("health_pickup");
        currentSpriteFrame = 0;
        lastFrameUpdate = Time.time;
    }

    void SpriteUpdate() {
        if (Time.time - lastFrameUpdate >= frameLength) {
            if (currentSpriteFrame == 3) {
                currentSpriteFrame = 0;
            } else {
                currentSpriteFrame++;
            }
            lastFrameUpdate = Time.time;
            sr.sprite = pickup_sprites[currentSpriteFrame];
        }
    }

    private void OnCollisionEnter2D(Collision2D collision) {
        if (collision.gameObject.CompareTag("Player")) {
            Destroy(gameObject);
        }
    }
}
