using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;
using TMPro;

public class InteractionUI : MonoBehaviour
{
    public TextMeshProUGUI title;
    public Transform options;

    int index;

    public void Show()
    {
        gameObject.SetActive(true);
    }

    public void Hide()
    {
        gameObject.SetActive(false);
    }

    public void ClearOptions(string title)
    {
        gameObject.SetActive(false);
        for (int i = 0; i < options.childCount; i++)
        {
            options.GetChild(i).gameObject.SetActive(false);
        }
        this.title.text = title;
        index = 0;
    }

    public void AddOption(string description, bool enabled, UnityAction callback)
    {
        Transform tr;
        if (index == options.childCount)
        {
            tr = Instantiate<Transform>(options.GetChild(0), options.position, options.rotation, options);
        }
        else
        {
            tr = options.GetChild(index);
        }
        index++;
        var button = tr.GetComponent<Button>();
        button.interactable = enabled;
        button.onClick.RemoveAllListeners();
        button.onClick.AddListener(Hide);
        button.onClick.AddListener(callback);
        var text = tr.GetChild(0).GetComponent<TextMeshProUGUI>().text = description;
        tr.gameObject.SetActive(true);
    }

    public void StartEncounter(HexPlayer player, CustomTile.TileInfo ti)
    {
        ClearOptions(ti.GetTitle());
        var inventory = player.CurrentInventory;
        switch (ti.interaction)
        {
            case CustomTile.Interaction.None:
                player.GiveControl();
                return;
            case CustomTile.Interaction.Road:
                AddOption("Greet strangers", true, () =>
                {
                    switch (Random.Range(0, 4))
                    {
                        case 0:
                            ClearOptions("Strangers");
                            AddOption("They ignore you", true, player.GiveControl);
                            break;
                        case 1:
                            ClearOptions("Strangers");
                            AddOption("You tell them about your adventure and they give you <sprite name=Food><sprite name=Food><sprite name=Food>", true, () =>
                            {
                                inventory.food.Refill(3);
                                player.GiveControl();
                            });
                            break;
                        case 2:
                            ClearOptions("Strangers");
                            AddOption("They offer to trade 5<sprite name=Food> for a <sprite name=Gold>", inventory.gold.value > 0 && !inventory.food.IsFull(), () =>
                            {
                                inventory.gold.value--;
                                inventory.food.Refill(5);
                                player.GiveControl();
                            });
                            AddOption("Decline", true, player.GiveControl);
                            break;
                        case 3:
                            ClearOptions("Robbers");
                            AddOption("They demand half of your <sprite name=Gold>", !inventory.gold.IsEmpty(), () =>
                            {
                                inventory.gold.value /= 2;
                                player.GiveControl();
                            });
                            AddOption("They demand half of your <sprite name=Food>", !inventory.food.IsEmpty(), () =>
                            {
                                inventory.food.value /= 2;
                                player.GiveControl();
                            });
                            AddOption("Try to fight them, loose <sprite name=Health><sprite name=Health>", true, () =>
                            {
                                inventory.health.value -= 2;
                                player.GiveControl();
                            });
                            AddOption("Try to fight them with your <sprite name=Bow>, loose <sprite name=Health>", inventory.bow.value > 0, () =>
                            {
                                inventory.health.value -= 1;
                                inventory.bow.value -= 1;
                                player.GiveControl();
                            });
                            AddOption("Try to fight them with your <sprite name=Dagger>, loose <sprite name=Health>", inventory.dagger.value > 0, () =>
                            {
                                inventory.health.value -= 1;
                                inventory.dagger.value -= 1;
                                player.GiveControl();
                            });
                            AddOption("Try to fight them with your <sprite name=Axe>, loose <sprite name=Health>", inventory.axe.value > 0, () =>
                            {
                                inventory.health.value -= 1;
                                inventory.axe.value -= 1;
                                player.GiveControl();
                            });
                            break;
                    }
                    Show();
                });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                AddOption("Keep to yourself", true, player.GiveControl);
                break;
            case CustomTile.Interaction.Fields:
                if (Random.value < 0.1f)
                {
                    AddOption("You meet a sheperd, who offers to share his lunch, gain 4<sprite name=Food>", !inventory.food.IsFull(), () => { inventory.food.Refill(4); player.GiveControl(); });
                }
                AddOption("Pick some berries, gain <sprite name=Food><sprite name=Food>", !inventory.food.IsFull(), () => { inventory.food.Refill(2); player.GiveControl(); });
                AddOption("Rest, gain <sprite name=Energy><sprite name=Energy> extra", true, () => { inventory.energy.value += 2; player.GiveControl(); });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                break;
            case CustomTile.Interaction.Forest:
                AddOption("Pick some berries, gain <sprite name=Food><sprite name=Food><sprite name=Food>", true, () => { inventory.food.Refill(3); player.GiveControl(); });
                AddOption("Hunt for food, spend <sprite name=Bow><sprite name=Bow> to gain 6<sprite name=Food>", inventory.bow.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.food.Refill(6);
                    inventory.bow.value -= 2;
                    player.GiveControl();
                });
                AddOption("Craft arrows, spend <sprite name=Dagger><sprite name=Dagger> to gain 5<sprite name=Bow>", inventory.dagger.value > 1 && !inventory.bow.IsFull(), () =>
                {
                    inventory.dagger.value -= 2;
                    inventory.bow.Refill(5);
                    player.GiveControl();
                });
                AddOption(
                    "Craft arrows, spend <sprite name=Dagger><sprite name=Axe> to gain 5<sprite name=Bow>",
                    inventory.dagger.value > 0 && inventory.axe.value > 0 && !inventory.bow.IsFull(),
                    () =>
                    {
                        inventory.dagger.value--;
                        inventory.axe.value--;
                        inventory.bow.Refill(5);
                        player.GiveControl();
                    });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                AddOption("Continue Exploring", true, player.GiveControl);
                break;
            case CustomTile.Interaction.OldGrowth:
                if (Random.value < 0.1f)
                {
                    ClearOptions("Hunted by Wolves");
                    AddOption("Try to run away from wolves, loose <sprite name=Health><sprite name=Health>", true, () =>
                    {
                        inventory.health.value -= 2;
                        player.GiveControl();
                    });
                    AddOption("Offer some food, loose <sprite name=Health><sprite name=Food><sprite name=Food>", inventory.food.value > 1, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.food.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Bow>, loose <sprite name=Health>", inventory.bow.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.bow.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Dagger>, loose <sprite name=Health>", inventory.dagger.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.dagger.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Axe>, loose <sprite name=Health>", inventory.axe.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.axe.value -= 1;
                        player.GiveControl();
                    });
                    break;
                }
                if (Random.value < 0.1f)
                {
                    AddOption("You see an old man wandering in the forest", true, () =>
                    {
                        ClearOptions("Meeting a Druid");
                        AddOption("Trade 10<sprite name=Food> for a <sprite name=Bandage>", inventory.food.value > 9 && !inventory.bandage.IsFull(), () =>
                        {
                            inventory.bandage.value++;
                            inventory.food.value -= 10;
                            player.GiveControl();
                        });
                        AddOption("Trade a <sprite name=Bandage> for 10<sprite name=Food>", !inventory.bandage.IsEmpty() && !inventory.bandage.IsFull(), () =>
                        {
                            inventory.bandage.value--;
                            inventory.food.Refill(10);
                            player.GiveControl();
                        });
                        AddOption("Let him be", true, player.GiveControl);
                        Show();
                    });
                }
                AddOption("Hunt for food, spend <sprite name=Bow><sprite name=Bow> to gain 8<sprite name=Food>",
                    inventory.bow.value > 1 && !inventory.food.IsFull(), () =>
                    {
                        inventory.food.Refill(8);
                        inventory.bow.value -= 2;
                        player.GiveControl();
                    });
                AddOption(
                    "Hunt for leather, spend <sprite name=Bow><sprite name=Dagger> to enlargen your backpack",
                    inventory.bow.value > 0 && inventory.dagger.value > 0,
                     () =>
                     {
                         inventory.bow.value--;
                         inventory.dagger.value--;
                         inventory.gold.max += 1;
                         inventory.food.max += 2;
                         inventory.bandage.max += 1;
                         player.GiveControl();
                     });
                AddOption(
                    "Hunt for trophies, spend <sprite name=Bow><sprite name=Bow> to gain <sprite name=Gold><sprite name=Gold><sprite name=Gold>",
                    inventory.bow.value > 1 && !inventory.gold.IsFull(), () =>
                    {
                        inventory.bow.value -= 2;
                        inventory.gold.Refill(3);
                        player.GiveControl();
                    });
                AddOption("Craft arrows, spend <sprite name=Dagger><sprite name=Dagger> to gain 5<sprite name=Bow>",
                    inventory.dagger.value > 1 && !inventory.bow.IsFull(), () =>
                    {
                        inventory.dagger.value -= 2;
                        inventory.bow.Refill(5);
                        player.GiveControl();
                    });
                AddOption("Craft arrows, spend <sprite name=Dagger><sprite name=Axe> to gain 5<sprite name=Bow>",
                    inventory.dagger.value > 0 && inventory.axe.value > 0 && !inventory.bow.IsFull(), () =>
                     {
                         inventory.dagger.value--;
                         inventory.axe.value--;
                         inventory.bow.Refill(5);
                         player.GiveControl();
                     });
                AddOption(
                    "Sculpt wooden idol, spend <sprite name=Dagger><sprite name=Axe> to gain <sprite name=Gold><sprite name=Gold><sprite name=Gold>",
                    inventory.dagger.value > 0 && inventory.axe.value > 0 && !inventory.gold.IsFull(),
                    () =>
                    {
                        inventory.dagger.value--;
                        inventory.axe.value--;
                        inventory.gold.Refill(3);
                        player.GiveControl();
                    });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                AddOption("Continue Exploring", true, player.GiveControl);
                break;
            case CustomTile.Interaction.Hills:
                if (Random.value < 0.15f)
                {
                    ClearOptions("Hunted by Wolves");
                    AddOption("Try to run away from wolves, loose <sprite name=Health><sprite name=Health>", true, () =>
                    {
                        inventory.health.value -= 2;
                        player.GiveControl();
                    });
                    AddOption("Offer some food, loose <sprite name=Health><sprite name=Food><sprite name=Food>", inventory.food.value > 1, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.food.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Bow>, loose <sprite name=Health>", inventory.bow.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.bow.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Dagger>, loose <sprite name=Health>", inventory.dagger.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.dagger.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight the wolves with your <sprite name=Axe>, loose <sprite name=Health>", inventory.axe.value > 0, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.axe.value -= 1;
                        player.GiveControl();
                    });
                    break;
                }
                if (Random.value < 0.1f)
                {
                    AddOption("You see a door on the side of an hill, and knock on it", true, () =>
                    {
                        ClearOptions("The shortling");
                        AddOption("The (very short) owner offers you dinner, gain 5<sprite name=Food>", !inventory.food.IsFull(), () =>
                        {
                            inventory.food.Refill(5);
                            player.GiveControl();
                        });
                        AddOption("The (very short) helps you with your wounds, gain <sprite name=Health><sprite name=Health>", !inventory.health.IsFull(), () =>
                        {
                            inventory.health.Refill(2);
                            player.GiveControl();
                        });
                        AddOption("The (very short) lends you his sharpening stone, gain <sprite name=Dagger>", !inventory.dagger.IsFull(), () =>
                        {
                            inventory.dagger.Refill();
                            player.GiveControl();
                        });
                        AddOption("Let him be", true, player.GiveControl);
                        Show();
                    });
                }
                AddOption("Hunt for food, spend <sprite name=Bow><sprite name=Bow> to gain 6<sprite name=Food>",
                    inventory.bow.value > 1 && !inventory.food.IsFull(), () =>
                    {
                        inventory.food.Refill(6);
                        inventory.bow.value -= 2;
                        player.GiveControl();
                    });
                AddOption("Build a trap, spend <sprite name=Axe><sprite name=Axe> to gain 8<sprite name=Food>",
                    inventory.axe.value > 1 && !inventory.food.IsFull(), () =>
                    {
                        inventory.food.Refill(8);
                        inventory.axe.value -= 2;
                        player.GiveControl();
                    });
                AddOption(
                    "Sculpt wooden idol, spend <sprite name=Dagger><sprite name=Axe> to gain <sprite name=Gold><sprite name=Gold><sprite name=Gold>",
                    inventory.dagger.value > 0 && inventory.axe.value > 0 && !inventory.gold.IsFull(),
                    () =>
                    {
                        inventory.dagger.value--;
                        inventory.axe.value--;
                        inventory.gold.Refill(3);
                        player.GiveControl();
                    });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                AddOption("Slide downhill, gain <sprite name=Energy><sprite name=Energy> extra", true, () => { inventory.energy.value += 2; player.GiveControl(); });
                break;
            case CustomTile.Interaction.Rocks:
            case CustomTile.Interaction.Mountain:
                if (Random.value < 0.1f)
                {
                    ClearOptions("Attacked by a Bear");
                    AddOption("Try to run away, loose <sprite name=Health><sprite name=Health><sprite name=Health>", true, () =>
                    {
                        inventory.health.value -= 3;
                        player.GiveControl();
                    });
                    AddOption("Offer some food, loose <sprite name=Health><sprite name=Food><sprite name=Food>", inventory.food.value > 1, () =>
                    {
                        inventory.health.value -= 1;
                        inventory.food.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fightwith your <sprite name=Bow>, loose <sprite name=Health><sprite name=Health>", inventory.bow.value > 0, () =>
                    {
                        inventory.health.value -= 2;
                        inventory.bow.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight with your <sprite name=Dagger>, loose <sprite name=Health><sprite name=Health>", inventory.dagger.value > 0, () =>
                    {
                        inventory.health.value -= 2;
                        inventory.dagger.value -= 1;
                        player.GiveControl();
                    });
                    AddOption("Fight with your <sprite name=Axe>, loose <sprite name=Health><sprite name=Health>", inventory.axe.value > 0, () =>
                    {
                        inventory.health.value -= 2;
                        inventory.axe.value -= 1;
                        player.GiveControl();
                    });
                    break;
                }
                AddOption("Hunt for food, spend <sprite name=Bow><sprite name=Bow> to gain 4<sprite name=Food>", inventory.bow.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.food.Refill(4);
                    inventory.bow.value -= 2;
                    player.GiveControl();
                });
                AddOption("Build a trap, spend <sprite name=Axe><sprite name=Axe> to gain 4<sprite name=Food>", inventory.axe.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.food.Refill(4);
                    inventory.axe.value -= 2;
                    player.GiveControl();
                });
                AddOption("Seek shelter, gain <sprite name=Energy><sprite name=Energy> extra", true, () => { inventory.energy.value += 2; player.GiveControl(); });
                if (!inventory.health.IsFull() && !inventory.bandage.IsEmpty())
                    AddOption("Use bandage, spend <sprite name=Bandage> to gain <sprite name=Health><sprite name=Health>", true, () => { inventory.bandage.value--; inventory.health.Refill(2); player.GiveControl(); });
                break;
            case CustomTile.Interaction.Snow:
                inventory.outro.ShowGood(inventory.time.ToString());
                return;
            case CustomTile.Interaction.Settlement:
                AddOption("Buy 5<sprite name=Food> for a <sprite name=Gold>", inventory.gold.value > 0 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value--;
                    inventory.food.Refill(5);
                    player.GiveControl();
                });
                AddOption("Buy 12<sprite name=Food> for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value -= 2;
                    inventory.food.Refill(12);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Bow> for 4<sprite name=Gold>", inventory.gold.value > 3 && !inventory.bow.IsFull(), () =>
                {
                    inventory.gold.value -= 4;
                    inventory.bow.Refill();
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Dagger> for <sprite name=Gold><sprite name=Gold><sprite name=Gold>", inventory.gold.value > 2 && !inventory.dagger.IsFull(), () =>
                {
                    inventory.gold.value -= 3;
                    inventory.dagger.Refill();
                    player.GiveControl();
                });
                AddOption("Leave", true, () => { inventory.food.Consume(1); player.GiveControl(); });
                break;
            case CustomTile.Interaction.LoggingCamp:
                AddOption("Buy 5<sprite name=Food> for a <sprite name=Gold>", inventory.gold.value > 0 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value--;
                    inventory.food.Refill(5);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Bow> for 4<sprite name=Gold>", inventory.gold.value > 3 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value -= 4;
                    inventory.bow.Refill();
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Axe> for <sprite name=Gold><sprite name=Gold><sprite name=Gold>", inventory.gold.value > 2 && !inventory.axe.IsFull(), () =>
                {
                    inventory.gold.value -= 3;
                    inventory.axe.Refill();
                    player.GiveControl();
                });
                AddOption("Buy a map (<sprite name=Time><sprite name=Time>) for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1, () =>
                {
                    inventory.gold.value -= 2;
                    inventory.time += 2;
                    player.GiveControl();
                });
                AddOption("Leave", true, () => { inventory.food.Consume(1); player.GiveControl(); });
                break;
            case CustomTile.Interaction.ElfVillage:
                AddOption("Buy 5<sprite name=Food> for a <sprite name=Gold>", inventory.gold.value > 0 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value--;
                    inventory.food.Refill(5);
                    player.GiveControl();
                });
                AddOption("Buy 12<sprite name=Food> for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value -= 2;
                    inventory.food.Refill(12);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Bandage> for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1 && !inventory.bandage.IsFull(), () =>
                {
                    inventory.gold.value -= 2;
                    inventory.bandage.Refill(1);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Bow> for <sprite name=Gold><sprite name=Gold><sprite name=Gold>", inventory.gold.value > 2 && !inventory.bow.IsFull(), () =>
                {
                    inventory.gold.value -= 3;
                    inventory.bow.Refill();
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Dagger> for 4<sprite name=Gold>", inventory.gold.value > 3 && !inventory.dagger.IsFull(), () =>
                {
                    inventory.gold.value -= 4;
                    inventory.dagger.Refill();
                    player.GiveControl();
                });
                AddOption("Buy a map (<sprite name=Time><sprite name=Time><sprite name=Time>) for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1, () =>
                {
                    inventory.gold.value -= 2;
                    inventory.time += 3;
                    player.GiveControl();
                });
                AddOption("Leave", true, () => { inventory.food.Consume(1); player.GiveControl(); });
                break;
            case CustomTile.Interaction.DwarfMine:
                AddOption("Buy 5<sprite name=Food> for a <sprite name=Gold>", inventory.gold.value > 0 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value--;
                    inventory.food.Refill(5);
                    player.GiveControl();
                });
                AddOption("Buy 12<sprite name=Food> for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1 && !inventory.food.IsFull(), () =>
                {
                    inventory.gold.value -= 2;
                    inventory.food.Refill(12);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Bandage> for <sprite name=Gold><sprite name=Gold>", inventory.gold.value > 1 && !inventory.bandage.IsFull(), () =>
                {
                    inventory.gold.value -= 2;
                    inventory.bandage.Refill(1);
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Dagger> for <sprite name=Gold><sprite name=Gold><sprite name=Gold>", inventory.gold.value > 2 && !inventory.dagger.IsFull(), () =>
                {
                    inventory.gold.value -= 3;
                    inventory.dagger.Refill();
                    player.GiveControl();
                });
                AddOption("Buy <sprite name=Axe> for <sprite name=Gold><sprite name=Gold><sprite name=Gold>", inventory.gold.value > 2 && !inventory.axe.IsFull(), () =>
                {
                    inventory.gold.value -= 3;
                    inventory.axe.Refill();
                    player.GiveControl();
                });
                AddOption("Leave", true, () => { inventory.food.Consume(1); player.GiveControl(); });
                break;
            case CustomTile.Interaction.Flee:
                inventory.outro.ShowBad("<b>Game Over:</b>\n\nYou decided to not explore, and instead just ran away!");
                return;
            default:
                Debug.LogException(new System.Exception("Missing switch statement"));
                return;
        }
        Show();
    }
}
