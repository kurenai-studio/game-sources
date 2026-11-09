using UnityEngine.SceneManagement;
using System.Collections.Generic;
using UnityEngine;

public class BattleManager : MonoBehaviour
{
    public AudioSource soundtrackPlayer;
    List<BattlePhase> phases = new();
    int activePhasesIndex;
    bool initialized = false;

    void Start()
    {
        foreach (BattlePhase phase in gameObject.GetComponents(typeof(BattlePhase)))
        {
            Debug.Log($"Register battle phase: {phase.GetType()}");
            phases.Add(phase);
        }

        Debug.Log($"Phase count: {phases.Count}");
    }

    void Update() { UpdatePhase(); }

    void FixedUpdate() { UpdatePhase(); }

    void UpdatePhase()
    {
        if (!initialized)
        {
            ActivatePhase(0);
            initialized = true;
        }

        if (phases[activePhasesIndex].phaseOver)
        {
            phases[activePhasesIndex].PhaseExit();
            phases[activePhasesIndex].enabled = false;
            ActivatePhase(activePhasesIndex + 1);
        }
    }

    public void ActivatePhase(int index)
    {
        if (index >= phases.Count)
        {
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
            return;
        }
        activePhasesIndex = index;
        var soundtrack = phases[activePhasesIndex].soundtrack;
        // Debug.Log(soundtrack.name);
        if (soundtrack != null)
        {
            soundtrackPlayer.clip = soundtrack;
            soundtrackPlayer.Play();
        }
        phases[activePhasesIndex].enabled = true;
        phases[activePhasesIndex].PhaseEnter();
    }
}
