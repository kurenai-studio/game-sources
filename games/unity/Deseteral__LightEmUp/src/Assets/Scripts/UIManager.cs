using UnityEngine;
using UnityEngine.UI;

public class UIManager : MonoBehaviour {
    private GameMaster gameMaster;
    private Damageable playerDamageable;
    private Tool playerTool;
    
    private Text coinValueText;
    private Text healthValueText;
    private Text currentLevelValueText;

    private Image[] toolIcons;

    private void Start() {
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();
        var playerObject = GameObject.Find("Player");
        playerDamageable = playerObject.GetComponent<Damageable>();
        playerTool = playerObject.GetComponent<Tool>();
        
        coinValueText = GameObject.Find("CoinValue").GetComponent<Text>();
        healthValueText = GameObject.Find("HealthValue").GetComponent<Text>();
        currentLevelValueText = GameObject.Find("CurrentLevelValue").GetComponent<Text>();

        toolIcons = new[] {
            GameObject.Find("GunIcon").GetComponent<Image>(),
            GameObject.Find("CableIcon").GetComponent<Image>(),
            GameObject.Find("LampIcon").GetComponent<Image>(),
            GameObject.Find("TurretIcon").GetComponent<Image>(),
        };
        
        currentLevelValueText.text = $"Level: {gameMaster.currentLevel}";
    }

    private void FixedUpdate() {
        coinValueText.text = gameMaster.coins.ToString();
        healthValueText.text = playerDamageable.health.ToString();
        
        foreach (var toolIcon in toolIcons) {
            toolIcon.enabled = false;
        }

        toolIcons[(int) playerTool.toolType].enabled = true;
    }
}