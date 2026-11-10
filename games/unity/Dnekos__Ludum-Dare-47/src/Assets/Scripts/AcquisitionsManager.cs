using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class AcquisitionsManager : MonoBehaviour
{
    [SerializeField]
    GameObject Upgradeprefab;
    [SerializeField]
    Transform UpgradeTab;

    bool got_rocket = false;

    // Start is called before the first frame update
    void Start()
    {
        transform.parent.SetAsLastSibling();
        for (int i = 0; i < transform.childCount; i++)
            transform.GetChild(i).GetChild(0).GetComponent<Text>().text =
                "Buy " + PlayerManager.Inst.purchases[i].Name +
                "\n$" + PlayerManager.Inst.purchases[i].price;//.DisplayNumber();
    }

    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < transform.childCount; i++)
        {
            Purchasable item = PlayerManager.Inst.purchases[i];

            if (item.price < PlayerManager.Inst.money || item.quantity > 0)
                transform.GetChild(i).gameObject.SetActive(true);
            else
                transform.GetChild(i).gameObject.SetActive(false);
        }

        if ((PlayerManager.Inst.purchases[5].quantity > 0 || PlayerManager.Inst.money == 2000000) && got_rocket == false)
        {
            Debug.Log("Rocket Spawn");
            Upgradeprefab.GetComponent<UpgradeManager>().index = -1;
            Instantiate(Upgradeprefab, UpgradeTab);
            got_rocket = true;
        }

    }

    public void BuyPurchasable(int index)
    {
        Purchasable item = PlayerManager.Inst.purchases[index];
        if (item.Purchase())
        {
            UnlockUpgrades(item);
            UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.GetComponentInChildren<Text>().text = 
                "Buy " + item.Name + "\n$" + item.price;
        }
    }

    public void UnlockUpgrades(Purchasable item)
    {
        if (item.quantity >= 5)
        {
            PlayerManager.Inst.unlocked_Upgrades = true;
            Upgradeprefab.GetComponent<UpgradeManager>().index = item.first_upgrade_index;
            Instantiate(Upgradeprefab, UpgradeTab);
        }
    }
}
