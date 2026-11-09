using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Capacitor : MonoBehaviour
{
    public float frameLength;

    private SpriteRenderer sr;
    private Sprite[] capacitor_sprites;
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
        capacitor_sprites = Resources.LoadAll<Sprite>("capacitor_sprites");
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
            sr.sprite = capacitor_sprites[currentSpriteFrame];
        }
    }
}
