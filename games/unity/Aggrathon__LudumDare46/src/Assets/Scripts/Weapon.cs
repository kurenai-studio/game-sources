using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class Weapon : MonoBehaviour
{

    public enum Type {
        None,
        Revolver,
        Blunderbuss,
        Rifle,
        Knife,
        Axe,
        Melee,
        Bow,
        Dynamite
    }
    
    public float range = 20f;
    public Type type = Type.Rifle;
    public int maxAmmo = 1;
    int ammo;
    public int shots = 1;
    public int damage = 2;

    [Range(0f, 0.15f)] public float variance = 0f;

    public float attackHeight = 1.5f;
    public float attackStart = 0.5f;

    public AudioClip attackSound;

    private void Start() {
        ammo = maxAmmo;
    }

    public void AppendDescription(System.Text.StringBuilder sb) {
        switch(type) {
            case Type.None:
                sb.Append("Hands are tied!");
                break;
            case Type.Revolver:
                sb.Append("Revolver with ").Append(maxAmmo).Append(" chambers");
                break;
            case Type.Blunderbuss:
                sb.Append("Single barreled blunderbuss");
                break;
            case Type.Rifle:
                sb.Append("Bolt-action rifle");
                break;
            case Type.Axe:
                sb.Append("Axe");
                break;
            case Type.Knife:
                sb.Append("Two knives");
                break;
            case Type.Melee:
                sb.Append("Brawler, fists and feet");
                break;
            case Type.Bow:
                sb.Append("Bow and arrows");
                break;
            case Type.Dynamite:
                sb.Append(ammo).Append(" sticks of dynamite");
                break;
            default:
                sb.Append("Unknown Weapon!");
                break;
        }
    }

    public void AppendStatus(System.Text.StringBuilder sb) {
        switch(type) {
            case Type.None:
                sb.Append("Hands are tied");
                break;
            case Type.Revolver:
                sb.Append("Revolver: ").Append(ammo).Append(" / ").Append(maxAmmo);
                break;
            case Type.Blunderbuss:
                sb.Append("Blunderbuss: ").Append(ammo).Append(" / ").Append(maxAmmo);
                break;
            case Type.Rifle:
                sb.Append("Rifle");
                break;
            case Type.Axe:
                sb.Append("Axe");
                break;
            case Type.Knife:
                sb.Append("Knives");
                break;
            case Type.Melee:
                sb.Append("Brawler");
                break;
            case Type.Bow:
                sb.Append("Bow");
                break;
            case Type.Dynamite:
                sb.Append("Dynamite: ").Append(ammo);
                break;
            default:
                sb.Append("Unknown Weapon!");
                break;
        }
    }

    public IEnumerable<string> GetActions() {
        switch(type) {
            case Type.Revolver:
                if (ammo > 0)
                    yield return "Shoot Once";
                if (ammo > 1)
                    yield return "Shoot Twice";
                if (ammo > 2)
                    yield return "Shoot Thrice";
                if (ammo < maxAmmo)
                    yield return "Reload";
                break;
            case Type.Blunderbuss:
                if (ammo > 0)
                    yield return "Shoot";
                if (ammo < maxAmmo)
                    yield return "Reload";
                break;
            case Type.Rifle:
                yield return "Shoot";
                break;
            case Type.Bow:
                yield return "Shoot";
                break;
            case Type.Axe:
                yield return "Chop";
                break;
            case Type.Knife:
                yield return "Slice";
                yield return "Stab";
                break;
            case Type.Melee:
                yield return "Punch";
                yield return "Kick";
                break;
            case Type.Dynamite:
                yield return "Punch";
                yield return "Throw Dynamite";
                break;
        }
    }

    public void StartAction(int index, System.Action<int> callback) {
        StopAllCoroutines();
        switch(type) {
            case Type.Revolver:
                if (index > ammo || index == 4) {
                    ammo = maxAmmo;
                    callback(1);
                } else {
                    shots = index;
                    CameraController.active.FocusShoulder(transform);
                    StartCoroutine(SelectAttackTarget(type, callback));
                }
                break;
            case Type.Blunderbuss:
                if (ammo > 0 && index == 1) {
                    CameraController.active.FocusShoulder(transform);
                    StartCoroutine(SelectAttackTarget(type, callback));
                } else {
                    ammo = maxAmmo;
                    callback(1);
                }
                break;
            case Type.Rifle:
            case Type.Bow:
                CameraController.active.FocusShoulder(transform);
                StartCoroutine(SelectAttackTarget(type, callback));
                break;
            case Type.Melee:
            case Type.Knife:
            case Type.Axe:
                StartCoroutine(SelectAttackTarget(type, callback));
                break;
            case Type.Dynamite:
                if (index == 1) {
                    StartCoroutine(SelectAttackTarget(type, callback));
                } else {
                    StartCoroutine(SelectAttackTarget(Type.Melee, callback));
                }
                break;
        }
    }

    IEnumerator SelectAttackTarget(Type type, System.Action<int> callback) {
        UnitUI.active.ShowAimHint();
        Vector3 target;
        while (true) {
            yield return null;
            if (Input.GetMouseButtonUp(0) && !EventSystem.current.IsPointerOverGameObject()) {
                RaycastHit hit;
                Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out hit, 100f))
                    target = hit.point;
                else
                    target = ray.GetPoint(100f);
                break;
            }
        }
        yield return AttackTarget(target, type);
        GameManager.activeGM.NotifyCombat();
        //TODO: Implement more weapons for players
        callback(2);
    }

    public IEnumerator AttackTarget(Vector3 target, Type type) {
        var dir = target - transform.position;
        dir.y = 0;
        dir.Normalize();
        transform.rotation = Quaternion.LookRotation(dir, Vector3.up);
        switch(type) {
            case Type.None:
                Debug.LogError("This should not happen!");
                break;
            case Type.Revolver:
                for (int i = 0; i < shots; i++)
                    yield return ShootGun(target, variance * Mathf.Sqrt(shots), true, 0.1f + 0.3f / shots);
                break;
            case Type.Blunderbuss:
                for (int i = 0; i < shots; i++)
                    yield return ShootGun(target, variance, i==0, i == shots -1 ? 0.4f : 0f);
                ammo = 0;
                break;
            case Type.Rifle:
            case Type.Bow:
                yield return ShootGun(target, variance, true, 0.4f);
                break;
            case Type.Axe:
            case Type.Knife:
            case Type.Melee:
                var point = transform.position + dir * attackStart;
                point.y += attackHeight;
                if (attackSound != null)
                    FXManager.active.PlayAudio(point, attackSound);
                var wfs = new WaitForSeconds(0.2f);
                RaycastHit hit;
                if (Physics.Raycast(point, target - point, out hit, range)) 
                    hit.rigidbody?.GetComponent<Health>()?.Damage(damage);
                break;
            case Type.Dynamite:
                Debug.LogError("Dynamite not implemented");
                break;
            default:
                Debug.LogError("Unknown Weapon!");
                break;
        }
    }

    IEnumerator ShootGun(Vector3 target, float variance, bool sound, float wait) {
        ammo--;
        var point = transform.position;
        point.y += attackHeight;
        var dir = target - point;
        dir.Normalize();
        point += dir * attackStart;
        dir += UnityEngine.Random.insideUnitSphere * variance;
        RaycastHit hit;
        Ray ray = new Ray(point, dir);
        Health h = null;
        if (Physics.Raycast(ray, out hit, range)) 
            h = hit.rigidbody?.GetComponent<Health>();
        else
            hit.point = ray.GetPoint(range);
        FXManager.active.Trace(point, hit.point);
        if (sound && attackSound != null)
            FXManager.active.PlayAudio(point, attackSound);
        if (h != null && wait > 0f) {
            var wfs = new WaitForSeconds(wait * 0.5f);
            yield return wfs;
            h.health -= damage;
            yield return wfs;
        } else if (h != null) {
            h.health -= damage;
        } else if (wait > 0f) {
            yield return new WaitForSeconds(wait);
        }
    }

    public void CancelAction() {
        UnitUI.active.HideAimHint();
        StopAllCoroutines();
    }

    private void OnDrawGizmosSelected() {
        Gizmos.color = Color.black;
        Gizmos.DrawSphere(transform.position + new Vector3(attackStart, attackHeight, 0f), 0.1f);
    }
}
