using UnityEngine;
using System.Collections;
using System;

public static class Utils {
    public static void print(params object[] args) {
        Debug.Log(string.Join(" ", args));
    }

    public static IEnumerator Delay(Action action, float time) {
        if (time > 0f)
            yield return new WaitForSeconds(time);
        action();
    }

    public static (float, Vector3) TryShootAt(Unit shooter, Unit target, Vector3 shooterPos, Vector3 targetPos, int samples = 10) {
        var dir = targetPos - shooterPos;
        if (dir.sqrMagnitude > shooter.weapon.range * shooter.weapon.range) {
            return (0f, targetPos);
        }
        shooterPos.y += shooter.weapon.attackHeight;
        var goal = targetPos + new Vector3(-dir.z, dir.x).normalized * UnityEngine.Random.Range(-target.approxRadius, target.approxRadius);
        goal.y += UnityEngine.Random.Range(0f, target.approxHeight);
        dir = goal - shooterPos;
        float dist = dir.magnitude;
        if (dist > shooter.weapon.range)
            return (0f, goal);
        dir /= dist;
        shooterPos += dir * shooter.weapon.attackStart;
        if (Physics.Raycast(shooterPos, dir, dist - shooter.approxRadius - shooter.weapon.attackStart))
            return (0f, goal);
        int hits = 0;
        for (int i = 0; i < samples; i++)
        {
            var dir2 = dir + UnityEngine.Random.insideUnitSphere * shooter.weapon.variance;
            var end = new Ray(shooterPos, dir).GetPoint(dist - shooter.weapon.attackStart);
            if (end.y >= 0f && end.y <= target.approxHeight)
                if (Mathf.Pow(end.x - targetPos.x, 2f) + Mathf.Pow(end.z - targetPos.z, 2f) < target.approxRadius * target.approxRadius)
                    hits++;
        }
        return ((float)hits / (float)samples, goal);
    }

    public static (float, Vector3) Danger(Unit shooter, Unit target, Vector3 shooterPos, Vector3 targetPos, int rays = 20) {
        (float hits, Vector3 hit) = TryShootAt(shooter, target, shooterPos, targetPos);
        for (int i = 1; i < rays; i++)
            hits += TryShootAt(shooter, target, shooterPos, targetPos).Item1;
        return (hits / (float)rays, hit);
    }
}