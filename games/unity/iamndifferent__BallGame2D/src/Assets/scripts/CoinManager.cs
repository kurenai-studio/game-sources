
using UnityEngine;
using TMPro;

public class CoinManager : MonoBehaviour
{
    public int coins = 0;
    public TMP_Text coinText;

    void Start()
    {
        UpdateText();
    }

    public void AddCoin()
    {
        coins = coins + 1;
        UpdateText();
    }

    void UpdateText()
    {
        coinText.text = "Monedas: " + coins;
    }
}
