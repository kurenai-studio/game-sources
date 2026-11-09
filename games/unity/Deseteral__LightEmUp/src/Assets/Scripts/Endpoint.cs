using UnityEngine;
using UnityEngine.UI;

public class Endpoint : MonoBehaviour {
    public bool hasPower = false;

    private CableGrid cableGrid;
    private int tileX;
    private int tileY;

    private GameObject playerObject;
    private GameMaster gameMaster;
    private Text endpointTooltipText;

    private void Start() {
        cableGrid = GameObject.Find("CableGrid").GetComponent<CableGrid>();
        playerObject = GameObject.Find("Player");
        gameMaster = GameObject.Find("GameMaster").GetComponent<GameMaster>();
        endpointTooltipText = GameObject.Find("EndpointTooltip").GetComponent<Text>();
        ResetPositionInfo();
    }

    private void FixedUpdate() {
        var playerPosition = playerObject.transform.position;
        if (Vector3.Distance(transform.position, playerPosition) < 2f) {
            if (hasPower) {
                endpointTooltipText.text = "press e to descent";
                
                if (Input.GetKey(KeyCode.E)) {
                    gameMaster.AdvanceToNextLevel();    
                }
            } else {
                endpointTooltipText.text = "Connect the power to descent";
            }
        } else {
            endpointTooltipText.text = "";
        }
    }

    public void RegeneratePowerInfo() {
        hasPower = cableGrid.IsTilePowered(tileX, tileY);
    }

    public void ResetPositionInfo() {
        var position = transform.position;
        tileX = (int) position.x;
        tileY = (int) position.y;
    }
}