using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Upgrades : MonoBehaviour
{
    public Transform addNewCard;
    public Transform replaceOldCard;
    public Transform replaceNewCard;
    public Transform equipmentOldCard;
    public Transform equipmentNewCard;
    public TMPro.TextMeshProUGUI title;
    public PlayerManager player;

    public List<BaseCard> baseCards;
    public List<Equipment> equipment;

    public int numUpgrades = 1;

    int numUsed;
    BaseCard _addNewCard;
    BaseCard _replaceOldCard;
    BaseCard _replaceNewCard;
    Equipment _equipmentOldCard;
    Equipment _equipmentNewCard;

    public void Show() {
        numUsed = 0;
        SetupUpgrades();
        gameObject.SetActive(true);
    }

    private void SetupUpgrades() {
        title.text = string.Format("Select One    ({0}/{1})", numUsed + 1, numUpgrades);
        _addNewCard = baseCards[UnityEngine.Random.Range(0, baseCards.Count)];
        PopulateCard(_addNewCard, addNewCard);
        _replaceOldCard = player.deck.deck[UnityEngine.Random.Range(0, player.deck.deck.Count)];
        PopulateCard(_replaceOldCard, replaceOldCard);
        if (_replaceOldCard.upgrades.Length == 0) {
            _replaceNewCard = baseCards[UnityEngine.Random.Range(0, baseCards.Count)];
        } else {
            _replaceNewCard = _replaceOldCard.upgrades[UnityEngine.Random.Range(0, _replaceOldCard.upgrades.Length)];
        }
        PopulateCard(_replaceNewCard, replaceNewCard);
        _equipmentOldCard = null;
        _equipmentNewCard = null;
        Array values = Enum.GetValues(typeof(Equipment.Type));
        var rar = 0;
        Equipment.Type type = (Equipment.Type)values.GetValue(UnityEngine.Random.Range(0, values.Length));
        do {
            type = (Equipment.Type)values.GetValue(UnityEngine.Random.Range(0, values.Length));
            switch(type) {
                case Equipment.Type.Chest:
                    _equipmentOldCard = player.chestItem;
                    break;
                case Equipment.Type.Hand:
                    _equipmentOldCard = player.handItem;
                    break;
                case Equipment.Type.Head:
                    _equipmentOldCard = player.headItem;
                    break;
            }
            rar = _equipmentOldCard != null ? rar = _equipmentOldCard.rarity : 0;
            _equipmentNewCard = equipment[UnityEngine.Random.Range(0, equipment.Count)];
        } while (!(_equipmentNewCard.rarity == rar || _equipmentNewCard.rarity == rar + 1) || _equipmentNewCard == _equipmentOldCard || _equipmentNewCard.type != type);
        PopulateEquipment(_equipmentNewCard, equipmentNewCard);
        PopulateEquipment(_equipmentOldCard, equipmentOldCard);
    }

    public void UpgradeHealth() {
        if (!gameObject.activeSelf)
            return;
        player.Heal(4, true);
        FinishUpgrade();
    }

    public void UpgradeNew() {
        if (!gameObject.activeSelf)
            return;
        player.deck.AddToDeck(_addNewCard);
        FinishUpgrade();
    }

    public void UpgradeReplace() {
        if (!gameObject.activeSelf)
            return;
        player.deck.RemoveFromDeck(_replaceOldCard);
        player.deck.AddToDeck(_replaceNewCard);
        FinishUpgrade();
    }

    public void UpgradeEquipment() {
        switch(_equipmentNewCard.type) {
            case Equipment.Type.Chest:
                player.chestItem?.OnDequip(player);
                player.chestItem = _equipmentNewCard;
                _equipmentNewCard.OnEquip(player);
                break;
            case Equipment.Type.Hand:
                player.handItem?.OnDequip(player);
                player.handItem = _equipmentNewCard;
                _equipmentNewCard.OnEquip(player);
                break;
            case Equipment.Type.Head:
                player.headItem?.OnDequip(player);
                player.headItem = _equipmentNewCard;
                _equipmentNewCard.OnEquip(player);
                break;
        }
        FinishUpgrade();
    }

    private void FinishUpgrade() {
        numUsed++;
        if (numUsed < numUpgrades) {
            SetupUpgrades();
        } else {
            gameObject.SetActive(false);
            player.Upgraded();
        }
    }

    private void PopulateCard(BaseCard card, Transform parent) {
        var col = card.color;
        col.a = 1f;
        parent.GetChild(0).GetComponent<Image>().sprite = card.sprite;
        parent.GetChild(1).GetComponent<Image>().color = col;
        parent.GetChild(2).GetComponent<TMPro.TextMeshProUGUI>().text = card.cardName;
        parent.GetChild(2).GetComponent<TMPro.TextMeshProUGUI>().color = col;
        parent.GetChild(3).GetComponent<TMPro.TextMeshProUGUI>().text = card.GetDescription();
        parent.GetChild(4).GetChild(0).GetComponent<TMPro.TextMeshProUGUI>().text = card.cost.ToString();
    }

    private void PopulateEquipment(Equipment equip, Transform parent) {
        if (equip == null) {
            parent.gameObject.SetActive(false);
        } else {
            parent.gameObject.SetActive(true);
            parent.GetChild(1).GetComponent<Image>().sprite = equip.sprite;
            parent.GetChild(2).GetComponent<TMPro.TextMeshProUGUI>().text = equip.description;
        }
    }
}
