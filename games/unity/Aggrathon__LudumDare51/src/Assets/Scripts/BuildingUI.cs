using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class BuildingUI : MonoBehaviour
{
    [SerializeField] Transform buildings;
    [SerializeField] Transform buttons;
    [SerializeField] AudioManager audioManager;
    [SerializeField] AudioClip clip;

    private void OnEnable()
    {
        Time.timeScale = 0f;

        var button = buttons.GetChild(0);
        while (buttons.childCount < buildings.childCount)
        {
            Instantiate(button, buttons);
        }
        for (int i = 0; i < buildings.childCount; i++)
        {
            button = buttons.GetChild(i);
            var plant = buildings.GetChild(i);
            var text = button.GetChild(0).GetComponent<TextMeshProUGUI>();
            text.text = plant.gameObject.name;
            button.gameObject.SetActive(!plant.gameObject.activeSelf);
            var click = button.GetComponent<Button>().onClick;
            click.RemoveAllListeners();
            click.AddListener(() =>
            {
                gameObject.SetActive(false);
                plant.gameObject.SetActive(true);
                audioManager.PlayOneShot(clip);
            });
        }
    }

    private void OnDisable()
    {
        Time.timeScale = 1f;
    }
}
