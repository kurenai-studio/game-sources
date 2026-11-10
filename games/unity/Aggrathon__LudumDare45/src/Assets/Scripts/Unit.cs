using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.EventSystems;

public class Unit : MonoBehaviour
{
    [NonSerialized] public DeckManager team;
    public string unitName;

    [SerializeField] int health = 2;
    int maxHealth;
    [SerializeField] TMPro.TextMeshPro healthText;
    [SerializeField] MeshRenderer spriteRenderer;
    [SerializeField] Texture2D spriteTexture;
    [SerializeField] Executor projectilePrefab;

    [NonSerialized] public bool hasMoved;
    public float moveDist = 1f;
    public float attackDist = 1f;
    public int damage = 1;

    private BoardTarget location;

    public void Setup(DeckManager team, BoardTarget target) {
        this.team = team;
        maxHealth = health;
        healthText.text = health + " / " + maxHealth;
        if (target.unit != null)
            Debug.LogWarning("Boardlocation is not empty ("+unitName+", "+target+")");
        location = target;
        location.unit = this;
        team.units.Add(this);
        hasMoved = true;

        var mpb = new MaterialPropertyBlock();
        spriteRenderer.GetPropertyBlock(mpb);
        mpb.SetTexture("_BaseMap", spriteTexture);
        spriteRenderer.SetPropertyBlock(mpb);
    }

    public bool Damage(int amount) {
        health -= amount;
        if (health <= 0) {
            healthText.text = "0 / " + maxHealth;
            if (location.unit == this)
                location.unit = null;
            Destroy(gameObject, 0.5f);
            team.units.Remove(this);
            return true;
        } else {
            healthText.text = health + " / " + maxHealth;
            return false;
        }
    }

    public void Heal(int amount) {
        health = Mathf.Min(health + amount, maxHealth);
        healthText.text = health + " / " + maxHealth;
    }

    public bool Move(BoardTarget target) {
        if (target == null) {
            return false;
        }
        if (!team.interactable) {
            team.Alert("Not your unit or not your turn!");
            return false;
        }
        var sqrDist = (target.transform.localPosition - location.transform.localPosition).sqrMagnitude;
        if (target.unit != null) {
            if (target.unit.team == team) {
                team.Alert("Space already occupied!");
                return false;
            } else if (sqrDist <= attackDist * attackDist) {
                hasMoved = true;
                AttackFX(target.transform.position);
                if (target.unit.Damage(damage) && sqrDist <= moveDist * moveDist) {
                    StopAllCoroutines();
                    StartCoroutine(Utils.LerpMoveTo(transform, target.transform.position));
                    if (location.unit == this)
                        location.unit = null;
                    target.unit = this;
                    location = target;
                    return true;
                } else {
                    return false;
                }
            } else {
                team.Alert("Target is too far away!");
                return false;
            }
        } else if (sqrDist <= moveDist * moveDist) {
            hasMoved = true;
            StopAllCoroutines();
            StartCoroutine(Utils.LerpMoveTo(transform, target.transform.position));
            target.unit = this;
            if (location.unit == this)
                location.unit = null;
            location = target;
            return true;
        } else {
            team.Alert("Cannot move that far!");
            Debug.Log("dist: "+sqrDist);
        }
        return false;
    }

    private void OnDestroy() {
        if (location.unit == this)
            location.unit = null;
        team.units.Remove(this);
    }

    internal virtual void AttackFX(Vector3 target) {
        if (projectilePrefab != null) {
            var ex = Instantiate(projectilePrefab, transform.position + Vector3.up*0.5f, Quaternion.LookRotation(target - transform.position, Vector3.up));
            ex.Execute(Utils.ChainIEnumerator(
                Utils.LerpMoveTo(ex.transform, target + Vector3.up*0.5f, 0.2f),
                Utils.ExecuteNextFrame(() => { Destroy(ex.gameObject); })
            ));
        } else {
            var half = transform.position + (target - transform.position) * 0.5f;
            var back = transform.position;
            StartCoroutine(Utils.ChainIEnumerator(Utils.LerpMoveTo(transform, half, 0.25f), Utils.LerpMoveTo(transform, back, 0.25f)));
        }
    }
}
