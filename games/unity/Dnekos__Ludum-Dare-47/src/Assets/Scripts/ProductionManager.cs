using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ProductionManager : MonoBehaviour
{
    Text WorkerBuytext;

    [SerializeField]
    GameObject Upgradeprefab;
    [SerializeField]
    Transform UpgradeTab;

    // Start is called before the first frame update
    void Start()
    {
        WorkerBuytext = GameObject.Find("WorkerBuytext").GetComponent<Text>();
    }

    // Update is called once per frame
    void Update()
    {
        WorkerBuytext.text = "Buy Farmhand\n$" + PlayerManager.Inst.worker.price;

        for (int i = 0; i < transform.childCount; i++)
        {
            Purchasable item = PlayerManager.Inst.purchases[i];

            if (item.quantity > 0)
            {
                transform.GetChild(i).gameObject.SetActive(true);
                transform.GetChild(i).GetChild(2).GetComponent<Text>().text = item.quantity + "\n" + item.used;
            }
            else
                transform.GetChild(i).gameObject.SetActive(false);
        }
    }

    public void BuyWorker()
    {
        Worker item = PlayerManager.Inst.worker;
        if (item.Purchase())
        {
            if (item.quantity >= 5)
            {
                PlayerManager.Inst.unlocked_Upgrades = true;
                Upgradeprefab.GetComponent<UpgradeManager>().index = item.first_upgrade_index;
                Instantiate(Upgradeprefab, UpgradeTab);
            }
            UnityEngine.EventSystems.EventSystem.current.currentSelectedGameObject.GetComponentInChildren<Text>().text = 
                "Buy Farmhand\n$" + PlayerManager.Inst.worker.price;
        }
    }

    public void GoToProduction()
    {
        transform.parent.SetAsLastSibling();
    }

    public void AddWorker(int index)
    {
        Worker workers = PlayerManager.Inst.worker;
        Workspace item = PlayerManager.Inst.purchases[index];
        if (workers.used < workers.quantity && item.used < item.quantity)
        {
            workers.used++;
            PlayerManager.Inst.purchases[index].used++;
        }
    }

    public void RemoveWorker(int index)
    {
        Worker workers = PlayerManager.Inst.worker;
        Workspace item = PlayerManager.Inst.purchases[index];
        if (workers.used > 0 && item.used > 0)
        {
            workers.used--;
            PlayerManager.Inst.purchases[index].used--;
        }
    }
}
