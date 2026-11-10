using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class Inventory : MonoBehaviour
{

    public Transform ui;
    public Outro outro;

    [System.Serializable]
    public struct Capacity
    {
        public int value;
        public int max;

        public void Refill()
        {
            value = max;
        }
        public void Refill(int amount)
        {
            value = Mathf.Min(max, value + amount);
        }

        public void Consume(int amount)
        {
            value -= amount;
        }

        public bool IsFull()
        {
            return value >= max;
        }

        public bool IsEmpty()
        {
            return value <= 0;
        }
    }

    private void Start()
    {
        UpdateUI();
    }

    public Capacity food;
    public Capacity energy;
    public Capacity health;
    public Capacity gold;
    public Capacity bandage;
    public Capacity bow;
    public Capacity axe;
    public Capacity dagger;
    public int time;


    public bool CheckDead()
    {
        if (health.value <= 0)
        {
            outro.ShowBad("<b>Game Over:</b>\n\nYou died!");
            return true;
        }
        if (food.value < 0)
        {
            outro.ShowBad("<b>Game Over:</b>\n\nYou ran out of food!");
            return true;
        }
        if (time <= 0)
        {
            outro.ShowBad("<b>Game Over:</b>\n\nYou took too long, no one remembers you anymore!");
            return true;
        }
        return false;
    }

    public bool CanEnterTile(CustomTile.TileInfo ti)
    {
        return energy.value >= ti.energy && food.value >= ti.food;
    }

    public void UpdateUI()
    {
        ui.GetChild(0).GetChild(1).GetComponent<TextMeshProUGUI>().text = time.ToString();
        ui.GetChild(1).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", energy.value, energy.max);
        ui.GetChild(2).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", food.value, food.max);
        ui.GetChild(3).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", health.value, health.max);
        ui.GetChild(4).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", gold.value, gold.max);
        ui.GetChild(5).gameObject.SetActive(bandage.value > 0);
        ui.GetChild(5).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", bandage.value, bandage.max);
        ui.GetChild(6).gameObject.SetActive(bow.value > 0);
        ui.GetChild(6).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", bow.value, bow.max);
        ui.GetChild(7).gameObject.SetActive(dagger.value > 0);
        ui.GetChild(7).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", dagger.value, dagger.max);
        ui.GetChild(8).gameObject.SetActive(axe.value > 0);
        ui.GetChild(8).GetChild(1).GetComponent<TextMeshProUGUI>().text = string.Format("{0} / {1}", axe.value, axe.max);
    }
}
