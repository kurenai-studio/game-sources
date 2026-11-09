using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ShopBehaviour : MonoBehaviour
{
    public static bool[] clickable;

    private GameObject player;
    private int currentPlayerHealth;
    private int[] currentPlayerAbilityLevels; //TODO: Add this to player
    private Sprite[] shop_sprites;

    // Prices
    public int HealthUpCost;
    public int SpeedUpCost;
    public int ResistanceUpCost;
    public int EPSDownCost;

    // Start is called before the first frame update
    void Start()
    {
        Init();
    }

    // Update is called once per frame
    void Update()
    {
        GetPlayer();
        GetPlayerCurrentHealth();
        GetPlayerCurrentAbilities();
        SetEnergyText();
        UpdateCostTextsAndIcons();
    }

    void Init() {
        shop_sprites = Resources.LoadAll<Sprite>("button_sprites");
        GetPlayer();
        currentPlayerAbilityLevels = new int[4] { 1,1,1,1 };
        clickable = new bool[4] { false,false,false,false };
        GetPlayerCurrentAbilities();
        GetPlayerCurrentHealth();
        SetUpShopUI();
    }


    // ****************** Player Info Functions ************************//

    void GetPlayer() {
        player = GameObject.FindGameObjectWithTag("Player");
    }

    void GetPlayerCurrentHealth() {
        currentPlayerHealth = player.GetComponent<Player>().GetCurrentHealth();
    }

    void GetPlayerCurrentAbilities() {
        currentPlayerAbilityLevels[0] = player.GetComponent<Player>().GetPlayerAbilities()[0];
        currentPlayerAbilityLevels[1] = player.GetComponent<Player>().GetPlayerAbilities()[1];
        currentPlayerAbilityLevels[2] = player.GetComponent<Player>().GetPlayerAbilities()[2];
        currentPlayerAbilityLevels[3] = player.GetComponent<Player>().GetPlayerAbilities()[3];
    }

    // ****************** Shop Functions ***************************//

    void SetCosts() {
        if (currentPlayerAbilityLevels[0] < 8) {
            HealthUpCost = (int)(Mathf.Pow(2f, player.GetComponent<Player>().GetPlayerAbilities()[0] - 1) * 10);
        } else {
            HealthUpCost = -1;
        }

        if (currentPlayerAbilityLevels[1] < 10) {
            SpeedUpCost = currentPlayerAbilityLevels[1] * 5;
        } else {
            SpeedUpCost = -1;
        }

        if (currentPlayerAbilityLevels[2] < 8) {
            ResistanceUpCost = (int)(Mathf.Pow(2f, currentPlayerAbilityLevels[2] - 1) * 10);
        } else {
            ResistanceUpCost = -1;
        }

        EPSDownCost = currentPlayerAbilityLevels[3] * 50;
    }

    void SetIcons() {
        if (currentPlayerHealth > HealthUpCost) {
            GameObject.Find("MaxHealthUpButton").GetComponent<Image>().sprite = shop_sprites[0];
            clickable[0] = true;
        } else {
            GameObject.Find("MaxHealthUpButton").GetComponent<Image>().sprite = shop_sprites[2];
            clickable[0] = false;
        }
        
        if (currentPlayerHealth > SpeedUpCost) {
            GameObject.Find("MaxSpeedUpButton").GetComponent<Image>().sprite = shop_sprites[3];
            clickable[1] = true;
        } else {
            GameObject.Find("MaxSpeedUpButton").GetComponent<Image>().sprite = shop_sprites[5];
            clickable[1] = false;
        }

        if (currentPlayerHealth > ResistanceUpCost) {
            GameObject.Find("ResistanceUpButton").GetComponent<Image>().sprite = shop_sprites[6];
            clickable[2] = true;
        } else {
            GameObject.Find("ResistanceUpButton").GetComponent<Image>().sprite = shop_sprites[8];
            clickable[2] = false;
        }
        
        if (currentPlayerHealth > EPSDownCost) {
            GameObject.Find("EPSDownButton").GetComponent<Image>().sprite = shop_sprites[9];
            clickable[3] = true;
        } else {
            GameObject.Find("EPSDownButton").GetComponent<Image>().sprite = shop_sprites[11];
            clickable[3] = false;
        }
    }

    void SetCostText() {
        Text text = GameObject.Find("HealthCostText").GetComponent<Text>();
        text.text = HealthUpCost.ToString() + " Energy";
        text = GameObject.Find("SpeedCostText").GetComponent<Text>();
        text.text = SpeedUpCost.ToString() + " Energy";
        text = GameObject.Find("ResistanceCostText").GetComponent<Text>();
        text.text = ResistanceUpCost.ToString() + " Energy";
        text = GameObject.Find("EPSCostText").GetComponent<Text>();
        text.text = EPSDownCost.ToString() + " Energy";
    }

    public void UpdateCostTextsAndIcons() { 
        SetCosts();
        SetCostText();
        SetIcons();
    }

    void SetEnergyText() {
        GameObject.FindGameObjectWithTag("UI_Shop_Energy_Text").GetComponent<Text>().text = currentPlayerHealth.ToString();
    }

    void SetUpShopUI() {
        SetEnergyText();
        SetCosts();
        SetCostText();
        SetIcons();
    }

    // ************** Utility functions ***************//

    private void OnEnable() {
        Debug.Log("Enabled");
    }

    public void DisableCanvas() {
        gameObject.GetComponent<Canvas>().enabled = false;
        gameObject.GetComponent<ShopBehaviour>().enabled = false;
        Time.timeScale = 1;
    }
}
