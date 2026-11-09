using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Unity.Collections;
using Unity.Physics;
using Unity.Physics.Authoring;
using Unity.Entities;
using Unity.Physics.Systems;
using UnityEngine.Events;

public class Planet : MonoBehaviour
{
    public int totalHealth = 200;
    public Image progress;

    public PhysicsShape blobShape;
    public float radius = 3.2f;

    public UnityEvent onWin;

    int health = 0;
    NativeList<DistanceHit> hits;
    World world;
    EntityManager mgr;
    BuildPhysicsWorld physicsWorldSystem;

    void Start()
    {
        hits = new NativeList<DistanceHit>(Allocator.Persistent);
        world = World.Active;
        mgr = world.EntityManager;
        physicsWorldSystem = mgr.World.GetOrCreateSystem<Unity.Physics.Systems.BuildPhysicsWorld>();
    }

    void Update()
    {
        physicsWorldSystem.FinalJobHandle.Complete();
        var collisionWorld = physicsWorldSystem.PhysicsWorld.CollisionWorld;
        hits.Clear();
        PhysicsCasting.PointRange2(collisionWorld, radius, (uint)blobShape.BelongsTo, transform.position, ref hits);
        bool changed = false;
        for (int i = 0; i < hits.Length; i++)
        {
            var e = collisionWorld.Bodies[hits[i].RigidBodyIndex].Entity;
            if (mgr.HasComponent<Blob>(e)) {
                mgr.DestroyEntity(e);
                health++;
                changed = true;
            }
        }
        if (changed) {
            progress.fillAmount = (float)health/(float)totalHealth;
            if (health >= totalHealth) {
                onWin.Invoke();
            }
        }
    }

    private void OnDestroy()
    {
        hits.Dispose();
    }
}
