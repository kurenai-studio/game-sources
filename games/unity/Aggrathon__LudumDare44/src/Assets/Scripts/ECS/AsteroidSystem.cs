using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Transforms;
using UnityEngine;
using TMPro;

public class AsteroidSystem : JobComponentSystem
{
    float timeout = 0f;
    NativeQueue<int2> changes;
    NativeQueue<int> launches;
    TextMeshPro[] texts;
    Entity[] entities;
    string[] cache;
    AsteroidSettings settings;
    GameState state;
    Entity shipPrefab;
    Entity target;

    void CreateTexts() {
        changes = new NativeQueue<int2>(Allocator.Persistent);
        launches = new NativeQueue<int>(Allocator.Persistent);
        cache = new string[101];
        for (int i = 1; i < 100; i++)
        {
            cache[i + 1] = i.ToString();
        }
        cache[0] = "E";
        cache[1] = "";
        texts = null;
        settings = GameObject.FindObjectOfType<AsteroidSettings>();
        state = GameObject.FindObjectOfType<GameState>();
        shipPrefab = GameObjectConversionUtility.ConvertGameObjectHierarchy(settings.shipPrefab, World);
        var mgr = EntityManager;
        var q = mgr.CreateEntityQuery(typeof(Translation), typeof(Asteroid));
        JobHandle jh;
        var ents = q.ToEntityArray(Allocator.TempJob, out jh);
        jh.Complete();
        texts = new TextMeshPro[ents.Length];
        for (int i = 0; i < ents.Length; i++)
        {
            var pos = mgr.GetComponentData<Translation>(ents[i]).Value;
            var go = GameObject.Instantiate(settings.textPrefab, pos, Quaternion.identity, settings.transform);
            texts[i] = go.GetComponent<TextMeshPro>();
            var ast = mgr.GetComponentData<Asteroid>(ents[i]);
            ast.index = i;
            mgr.SetComponentData(ents[i], ast);
        }
        entities = ents.ToArray();
        ents.Dispose();
        q = mgr.CreateEntityQuery(typeof(MotherShip));
        ents = q.ToEntityArray(Allocator.TempJob, out jh);
        jh.Complete();
        target = ents[0];
        ents.Dispose();
    }

    [BurstCompile]
    struct AsteroidSystemJob : IJobForEach<Asteroid>
    {
        public NativeQueue<int2>.Concurrent changes;
        public NativeQueue<int>.Concurrent launches;

        public int shipCost;
        public int minShip;

        public void Execute(ref Asteroid ast)
        {
            if (ast.mines > 0) {
                if (ast.minerals > 0) {
                    if (ast.stock < 99) {
                        ast.minerals -= ast.mines;
                        ast.stock = math.min(99, ast.stock + ast.mines);
                        changes.Enqueue(new int2(ast.index, ast.stock));
                    }
                    ast.shipTicks--;
                    if (ast.stock > minShip && ast.shipTicks < 0)
                        launches.Enqueue(ast.index);
                } else if (ast.stock >= 0) {
                    if (ast.stock > 0) {
                        launches.Enqueue(ast.index);
                    } else {
                        ast.stock = -1;
                        changes.Enqueue(new int2(ast.index, ast.stock));
                    }
                }
            }
        }
    }
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        timeout -= Time.deltaTime;
        if (timeout < 0) {
            if (!settings) CreateTexts();
            timeout += settings.tickTime;
            var job = new AsteroidSystemJob() {
                changes = changes.ToConcurrent(),
                launches = launches.ToConcurrent(),
                minShip = settings.minShipStock,
                shipCost = settings.shipCost
            };
            int2 todo;
            while(changes.TryDequeue(out todo)) {
                texts[todo.x].text = cache[todo.y + 1];
            }
            int l;
            while(launches.TryDequeue(out l)) {
                SpawnShip(l);
            }
            return job.Schedule(this, inputDependencies);
        } else 
            return inputDependencies;
    }

    void SpawnShip(int index) {
        var mgr = EntityManager;
        var ast = mgr.GetComponentData<Asteroid>(entities[index]);
        if (state.aluminium > settings.shipCost)
            state.aluminium -= settings.shipCost;
        else if (ast.resource == Asteroid.Resource.Aluminium && ast.stock > settings.shipCost)
            ast.stock -= settings.shipCost;
        else
            return;
        var ent = mgr.Instantiate(shipPrefab);
        float3 pos = texts[index].transform.position;
        var tar = mgr.GetComponentData<Translation>(target).Value;
        var dir = tar - pos;
        dir *= settings.spawnDist / math.length(dir);
        mgr.SetComponentData(ent, new Translation() { Value = pos + dir });
        mgr.SetComponentData(ent, new Rotation() { Value = quaternion.RotateZ(math.atan2(dir.y, dir.x))});
        var ship = mgr.GetComponentData<TransportShip>(ent);
        ship.target = target;
        ship.inventory = ast.stock;
        ship.resource = ast.resource;
        mgr.SetComponentData(ent, ship);
        ast.stock = 0;
        ast.shipTicks = ast.minShipTicks;
        texts[index].text = cache[1];
        mgr.SetComponentData(entities[index], ast);
    }

    override protected void OnDestroyManager() {
        changes.Dispose();
        launches.Dispose();
    }
}