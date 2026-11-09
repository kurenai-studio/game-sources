using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;
using Unity.Entities;
using Unity.Transforms;
using Unity.Burst;
using Unity.Jobs;
using Unity.Collections;
using Unity.Physics;
using Unity.Physics.Authoring;

[RequireComponent(typeof(VectorField))]
[RequireComponent(typeof(GameState))]
public class MouseManager : MonoBehaviour
{
    [Header("Gravity Well")]
    public float range = 1.5f;
    public float strength = 0.75f;
    public Renderer marker;
    public float gravityCost = 2f;
    public GameObject noWaterText;

    [Header("Mines")]
    public float blobRange = 1f;
    public int blobCost = 10;
    public PhysicsShape blobPhysicsShape;
    public GameObject factoryPrefab;
    public GameObject costText;
    public GameObject asteroidEmptyText;

    [Header("Fly")]
    public float flyCost = 25f;

    VectorField vectorField;
    Camera camera;
    EntityManager mgr;
    Entity ent;
    GravityWell gw;
    Entity fp;
    GameState state;
    AudioManager audio;

    void Start()
    {
        vectorField = GetComponent<VectorField>();
        state = GetComponent<GameState>();
        camera = Camera.main;
        mgr = World.Active.EntityManager;
        ent = mgr.CreateEntity(typeof(Translation), typeof(GravityWell));
        gw = new GravityWell(range, vectorField.spacing, false, strength);
        mgr.SetComponentData(ent, gw);
        marker.gameObject.SetActive(false);
        fp = GameObjectConversionUtility.ConvertGameObjectHierarchy(factoryPrefab, mgr.World);
        audio = FindObjectOfType<AudioManager>();
    }

    void LateUpdate()
    {
        // Gravity Well
        if (Input.GetMouseButton(0) && state.water > 0) {
            var pos = camera.ScreenToWorldPoint(Input.mousePosition);
            pos.z = 1f;
            marker.transform.position = pos;
            mgr.SetComponentData(ent, new Translation() { Value = pos });
            if (!gw.enabled) {
                marker.gameObject.SetActive(true);
                gw.enabled = true;
                mgr.SetComponentData(ent, gw);
            }
            state.water -= Time.deltaTime * gravityCost;
        } else {
            if (state.water < 0) {
                var pos = camera.ScreenToWorldPoint(Input.mousePosition);
                state.water = 0;
                pos.z = -1;
                noWaterText.transform.position = pos;
                noWaterText.SetActive(true);
            }
            if (gw.enabled && mgr.Exists(ent)) {
                gw = mgr.GetComponentData<GravityWell>(ent);
                gw.enabled = false;
                mgr.SetComponentData(ent, gw);
                marker.gameObject.SetActive(false);
            }
        }

        // Build mines and move ship
        if (Input.GetMouseButtonUp(1)) {
            var pos = camera.ScreenToWorldPoint(Input.mousePosition);
            var physicsWorldSystem = mgr.World.GetOrCreateSystem<Unity.Physics.Systems.BuildPhysicsWorld>();
            physicsWorldSystem.FinalJobHandle.Complete();
            var collisionWorld = physicsWorldSystem.PhysicsWorld.CollisionWorld;
            var hit = new Unity.Physics.RaycastHit();
            RaycastInput input = new RaycastInput()
            {
                Ray = new Unity.Physics.Ray() { Origin = pos, Direction = new float3(0, 0, 100) },
                Filter = new CollisionFilter() { CategoryBits = ~0u, MaskBits = ~0u, GroupIndex = 0 }
            };
            PhysicsCasting.SingleRayCast2(collisionWorld, input, out hit);
            if (hit.RigidBodyIndex >= 0) {
                var e = collisionWorld.Bodies[hit.RigidBodyIndex].Entity;
                // Build Mine
                if (mgr.HasComponent(e, typeof(Asteroid))) {
                    if (mgr.GetComponentData<Asteroid>(e).minerals <= 0) {
                        pos.z = -1f;
                        asteroidEmptyText.transform.position = pos;
                        asteroidEmptyText.SetActive(true);
                    } else {
                        bool build = false;
                        NativeList<ColliderCastHit> hits = new NativeList<ColliderCastHit>(Allocator.TempJob);
                        PhysicsCasting.SphereCastAll(collisionWorld, blobRange, (uint)blobPhysicsShape.BelongsTo, pos, new float3(0, 0, 100), hits);
                        if (hits.Length >= blobCost) {
                            NativeArray<Entity> torm = new NativeArray<Entity>(10, Allocator.TempJob);
                            int j = 0;
                            for (int i = 0; i < hits.Length && j < 10; i++)
                            {
                                var e2 = collisionWorld.Bodies[hits[i].RigidBodyIndex].Entity;
                                if (mgr.HasComponent(e2, typeof(Blob))) {
                                    torm[j++] = e2;
                                }
                            }
                            if (j == 10) { 
                                mgr.DestroyEntity(torm);
                                var f = mgr.Instantiate(fp);
                                var tr = mgr.GetComponentData<Translation>(e);
                                tr.Value.z -= 0.01f;
                                mgr.SetComponentData(f, tr);
                                var ast = mgr.GetComponentData<Asteroid>(e);
                                ast.mines++;
                                mgr.SetComponentData(e, ast);
                                build = true;
                                audio.Play(tr.Value, 2);
                            }
                            torm.Dispose();
                        }
                        hits.Dispose();
                        if (!build) {
                            pos.z =-1f;
                            costText.transform.position = pos;
                            costText.SetActive(false);
                            costText.SetActive(true);
                        }
                    }
                }
                // Move Ship 
                if (mgr.HasComponent(e, typeof(MotherShip))) {
                    MotherShip ms = mgr.GetComponentData<MotherShip>(e);
                    if (ms.lerp < 0) {
                        if (state.water > flyCost) {
                            state.water -= flyCost;
                            ms.lerp = 0;
                            mgr.SetComponentData(e, ms);
                        } else {
                            pos.z = -1;
                            noWaterText.transform.position = pos;
                            noWaterText.SetActive(true);
                        }
                    }
                }
            }
        }
    }

}
