using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{

    [SerializeField] PlayerManager player;
    [SerializeField] Transform enemyHolder;
    [SerializeField] GameObject winScreen;
    IPlayerManager enemy;
    int enemyIndex;
    bool playersTurn;

    public Board groundTargets;

    private void Start() {
        enemyIndex = 0;
        enemy = null;
        StartCoroutine(Utils.ExecuteLater(NextCombat, 2.5f));
    }

    public void NextTurn() {
        groundTargets.Unlight();
        if (enemy == null) {
            return;
        } else if (playersTurn) {
            playersTurn = false;
            player.StartTurn();
        } else {
            playersTurn = true;
            enemy.StartTurn();
        }
    }

    public void NextCombat() {
        groundTargets.Unlight();
        if (enemy == null) {
            if (enemyHolder.childCount <= enemyIndex) {
                winScreen.SetActive(true);
                return;
            }
            player.StartCombat(this);
            enemy = enemyHolder.GetChild(enemyIndex).GetComponent<EnemyManager>();
            enemyIndex++;
            enemy.StartCombat(this);
            playersTurn = false;
            NextTurn();
        }
    }

    public void Loose(IPlayerManager looser) {
        if (enemy == null)
            return;
        if (player == (Object)looser) {
            enemy.EndCombat(true);
            enemy = null;
            player.EndCombat(false);
        } else if (enemy == looser) {
            enemy.EndCombat(false);
            enemy = null;
            if (enemyHolder.childCount <= enemyIndex) {
                winScreen.SetActive(true);
            } else {
                player.EndCombat(true);
            }
        }
    }

    public IPlayerManager GetOtherPlayer(IPlayerManager curr) {
        if (player == (Object)curr)
            return enemy;
        else
            return player;
    }
}
