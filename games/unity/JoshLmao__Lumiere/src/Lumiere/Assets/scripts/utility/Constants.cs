using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Constants
{
    /// <summary>
    /// Total health of player
    /// </summary>
    public static readonly double PLAYER_TOTAL_HEALTH = 100;
    public static readonly float PLAYER_JUMP_COOLDOWN = 0.25f;
    public static readonly float PLAYER_JUMP_FORCE = 7f;

    /// <summary>
    /// When the player collides with an enemy, the amount for the player to lose in power
    /// </summary>
    public static readonly float PLAYER_TOUCH_ENEMY_POWER_LOSS = 10f;

    public static readonly float ENEMY_MIN_HEALTH = 80;
    public static readonly float ENEMY_MAX_HEALTH = 200;

    public static readonly float ENEMY_MIN_POWER_DROPPED = 15;
    public static readonly float ENEMY_MAX_POWER_DROPPED = 45;

    public static readonly float ENEMY_MIN_GUN_DAMAGE = 5f;
    public static readonly float ENEMY_MAX_GUN_DAMAGE = 30f;

    /// <summary>
    /// The distance the player needs to be within for the enemies to be able to shoot at the player
    /// </summary>
    public static readonly float ENEMY_RANGE_TO_PLAYER = 7f;

    #region Tags
    public static readonly string ENEMY_TAG = "Enemy";
    public static readonly string BULLET_TAG = "Bullet";
    public static readonly string RESTART_LEVEL_TAG = "Restart";
    #endregion

    #region Layers
    public static readonly int FLOOR_LAYER = 9;
    #endregion
}
