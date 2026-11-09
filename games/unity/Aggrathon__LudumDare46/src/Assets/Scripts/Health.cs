using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.Linq;

public class Health : MonoBehaviour
{
    public int maxHealth = 2;
    int _health;
    public Image ui;

    public int health { 
        get {
            return _health;
        }
        set {
            if (value <= 0)
                Destroy(gameObject);
            else if (value != _health){
                if (value > maxHealth)
                    _health = maxHealth;
                else
                    _health = value;
                if (ui != null) {
                    ui.gameObject.SetActive(true);
                    ui.fillAmount = (float)_health / (float)maxHealth;
                }
            }
        }
    }

    public void Damage(int dmg) {
        health -= dmg;
    }

    private void OnEnable() {
        health = maxHealth;
    }
}
