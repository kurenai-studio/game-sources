#nullable enable
using UnityEngine;
using System.Collections;

//This is a basic interface with a single required
//method.
public interface IProjectileSpell
{
    public Vector2 target { get; set; }
    public float speed { get; set; } 
    public PlayerController caster { get; set; }

    void Hit(GameObject hitTarget);
    void Kill();
    void Move();
    void CheckForHit(Vector2 newPos);
}