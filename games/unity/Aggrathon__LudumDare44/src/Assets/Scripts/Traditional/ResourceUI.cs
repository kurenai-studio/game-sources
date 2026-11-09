using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.SceneManagement;
using Unity.Entities;

public class ResourceUI : MonoBehaviour
{
    public TextMeshProUGUI alumText;
    public TextMeshProUGUI ironText;
    public TextMeshProUGUI waterText;

    int oldWater = -1;
    int oldIron = -1;
    int oldAlum = -1;

    GameState state;

    private void Start() {
        state = FindObjectOfType<GameState>();
    }

    void Update()
    {
        if ((int)state.water != oldWater) {
            oldWater = (int)state.water;
            waterText.text = oldWater.ToString();
        }
        if (state.iron != oldIron) {
            oldIron = (int)state.iron;
            ironText.text = oldIron.ToString();
        }
        if (state.aluminium != oldAlum) {
            oldAlum = state.aluminium;
            alumText.text = oldAlum.ToString();
        }
    }
}
