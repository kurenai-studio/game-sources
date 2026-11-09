using UnityEngine;

public class ElectricalDevice : MonoBehaviour {
    public bool hasPower = false;

    private CableGrid cableGrid;
    private int x;
    private int y;

    private void Start() {
        cableGrid = GameObject.Find("CableGrid").GetComponent<CableGrid>();
    
        var position = transform.position;
        x = (int)position.x;
        y = (int)position.y;
        
        RegeneratePowerInfo();
    }

    public void RegeneratePowerInfo() {
        hasPower = cableGrid.IsTilePowered(x, y); // TODO: MIGHT BE A PERF PROBLEM
    }
}