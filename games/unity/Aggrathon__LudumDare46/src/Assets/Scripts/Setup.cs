using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Text;

public class Setup : MonoBehaviour
{

    public List<Unit> possibleBandits;
    public Transform infoPanel;
    public AudioClip sound;

    private void Awake() {
        transform.GetChild(0).gameObject.SetActive(true);
    }

    private void Start() {
        while (infoPanel.parent.childCount < possibleBandits.Count) {
            Instantiate(infoPanel, infoPanel.parent);
        }
        for (int i = 0; i < possibleBandits.Count; i++)
        {
            Unit bandit = possibleBandits[i];
            Transform panel = infoPanel.parent.GetChild(i);
            panel.GetChild(0).GetComponent<Image>().color = bandit.color;
            panel.GetChild(1).GetComponent<TextMeshProUGUI>().text = bandit.name;
            var sb = new StringBuilder().Append("Weapon: ");
            bandit.GetComponent<Weapon>().AppendDescription(sb);
            panel.GetChild(2).GetComponent<TextMeshProUGUI>().text = sb.ToString();
            panel.GetChild(3).GetComponent<Toggle>().isOn = i < 3;
        }
    }

    public void StartGame() {
        for (int i = 0; i < possibleBandits.Count; i++)
        {
            if(infoPanel.parent.GetChild(i).GetChild(3).GetComponent<Toggle>().isOn)
                possibleBandits[i].gameObject.SetActive(true);
        }
        gameObject.SetActive(false);
        if (sound != null)
            FXManager.active.PlayAudio(Vector3.zero, sound);
    }

}
