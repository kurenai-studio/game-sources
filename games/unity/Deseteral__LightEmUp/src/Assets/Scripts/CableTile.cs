using System.Collections.Generic;
using UnityEngine;

public class CableTile : MonoBehaviour {
    public bool hasPower = false;
    public int health = 100;

    public SpriteRenderer[] directionalSprites;

    public CableGrid parentGrid;

    private bool blink = false;
    
    private static readonly Color ENABLED_COLOR = Color.white;
    private static readonly Color DISABLED_COLOR = new Color(0x5A / 255f, 0x5A / 255f, 0x5A / 255f);

    private void FixedUpdate() {
        var position = transform.position;
        
        if (health <= 0) {
            parentGrid.RemoveCable((int)position.x, (int)position.y);
        }

        if (blink) {
            SetColor(Color.red);
            blink = false;
        } else {
            SetColorBasedOnPowerStatus();
        }
    }

    public void ResetSprites(List<bool> neighbours) {
        // Reset values
        foreach (var sprite in directionalSprites) {
            sprite.enabled = false;
        }

        // Enable sprites
        bool anySet = false;
        for (int index = 0; index < neighbours.Count; index++) {
            directionalSprites[index].enabled = neighbours[index];
            if (neighbours[index] == true) anySet = true;
        }

        directionalSprites[4].enabled = !anySet; // Set center
        
        // Change color based on power status
        SetColorBasedOnPowerStatus();
    }

    private void SetColor(Color c) {
        foreach (var sprite in directionalSprites) {
            sprite.color = c;
        }
    }

    private void SetColorBasedOnPowerStatus() {
        SetColor(hasPower ? ENABLED_COLOR : DISABLED_COLOR);
    }
    
    private void OnCollisionEnter2D(Collision2D target) {
        if (target.collider != null && target.collider.gameObject.CompareTag("Enemy")) {
            health -= 25;
            target.collider.GetComponent<Enemy>().PushBack(3f);
            blink = true;
        }
    }
}