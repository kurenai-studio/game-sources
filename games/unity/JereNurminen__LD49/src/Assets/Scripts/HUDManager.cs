using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[System.Serializable]
public class SpellMapping
{
   public Sprite icon;
   public Utils.SpellName spellName;
}

public class HUDManager : MonoBehaviour
{
    public List<SpellMapping> spellMappings;
    public int maxWidth;
    public Color fullHealthColor;
    public Color lowHealthColor;
    public float lowHealthTreshold;

    private Image spellDisplay;
    private Image hpDisplay;

    private float hpBarHeight;

    // Start is called before the first frame update
    void Start()
    {
        spellDisplay = transform.Find("Spell").GetComponent<Image>();
        Debug.Log(spellDisplay);
        hpDisplay = transform.Find("HP").GetComponent<Image>();
        hpBarHeight = hpDisplay.rectTransform.sizeDelta.y;
    }

    public void SetSpell(Utils.SpellName spellName) {
        foreach(SpellMapping spell in spellMappings) {
            Debug.Log(spell);
            if (spell.spellName == spellName) {
                spellDisplay.sprite = spell.icon;
                spellDisplay.color = Color.white;
            }
        }
    }

    public void SetHP(Health health)
    {
        float healthLeftProportion = (float)health.currentHealth / health.maxHealth;
        hpDisplay.rectTransform.sizeDelta = new Vector2(healthLeftProportion * maxWidth, hpBarHeight);
        if (healthLeftProportion < lowHealthTreshold) {
            hpDisplay.color = lowHealthColor;
        } else {
            hpDisplay.color = fullHealthColor;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
