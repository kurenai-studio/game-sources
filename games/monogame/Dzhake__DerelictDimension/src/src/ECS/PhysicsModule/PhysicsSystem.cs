using Box2D.NET;
using DerelictDimension.ECS.Ai;
using DerelictDimension.ECS.PhysicsModule.Components;
using DerelictDimension.Utils;
using DerelictDimension.Utils.Extensions;
using Friflo.Engine.ECS.Systems;
using Monod.ECS.DefaultComponents;
using Monod.Shared.Exceptions;
using Monod.TimeModule;
using Monod.Utils.Extensions;
using System.Runtime.CompilerServices;
using static Box2D.NET.B2Bodies;
using static Box2D.NET.B2Geometries;
using static Box2D.NET.B2MathFunction;
using static Box2D.NET.B2Shapes;
using static Box2D.NET.B2Types;
using static Box2D.NET.B2Worlds;

namespace DerelictDimension.ECS.PhysicsModule;

public sealed class PhysicsSystem : BaseSystem
{
    public ArchetypeQuery<PhysicsBodyComponent> PhysicsBodyQuery;
    public ArchetypeQuery<PhysicsShapeComponent> PhysicsShapeQuery;
    public ArchetypeQuery<HitboxComponent> HitboxQuery;
    public ArchetypeQuery<Transform2D> TransformQuery;

    public ComponentIndex<PhysicsShapeComponent, B2ShapeId> ShapesIndex;
    public ComponentIndex<PhysicsBodyComponent, B2BodyId> BodiesIndex;

    public CommandBuffer cb;

    protected override void OnAddStore(EntityStore store)
    {
        base.OnAddStore(store);

        PhysicsBodyQuery = store.Query<PhysicsBodyComponent>();
        PhysicsShapeQuery = store.Query<PhysicsShapeComponent>();
        TransformQuery = store.Query<Transform2D>();
        HitboxQuery = store.Query<HitboxComponent>();

        ShapesIndex = store.ComponentIndex<PhysicsShapeComponent, B2ShapeId>();
        BodiesIndex = store.ComponentIndex<PhysicsBodyComponent, B2BodyId>();

        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
    }

    protected override void OnRemoveStore(EntityStore store)
    {
        cb.ReturnBuffer();
        //TODO (perf: mid) probably should clear the world instead of fully destroying it, but i'm not sure how
        b2DestroyWorld(Physics.WorldId);
        base.OnRemoveStore(store);
    }

    protected override void OnUpdateGroup()
    {
        EnsureWorld();

        SynchronizeBox2d();
        cb.Playback();

        b2World_Step(Physics.WorldId, Time.DeltaTime, 4);

        SynchronizeEcs();
        cb.Playback();

        ResolveEvents();

        UnsetDirty();
    }

    private void EnsureWorld()
    {
        if (!b2World_IsValid(Physics.WorldId))
        {
            var b2WorldDef = b2DefaultWorldDef();
            b2WorldDef.gravity = new B2Vec2(0, 0);
            Physics.WorldId = b2CreateWorld(b2WorldDef);
        }
    }

    private void SynchronizeBox2d()
    {
        PhysicsBodyQuery.ForEachEntity(SynchronizeBodyToBox2d);
        PhysicsShapeQuery.ForEachEntity(SynchronizeShapeToBox2d);
    }


    private void SynchronizeBodyToBox2d(ref PhysicsBodyComponent physicsBody, Entity entity)
    {
        var data = entity.Data;
        ref var transform = ref data.Ensure<Transform2D>(cb);

        if (!b2Body_IsValid(physicsBody.BodyId))
        {
            physicsBody.SetIndexedValue(in entity, CreateBody(ref physicsBody, ref entity), in BodiesIndex);
            return;
        }

        bool setAwake = false;
        if (transform.PhysicsDirty)
        {
            b2Body_SetTransform(physicsBody.BodyId, entity.GetWorldPos(out float rotation).ToB2(), b2MakeRot(rotation));
            setAwake = true;
        }

        if (physicsBody.PhysicsDirty)
        {
            b2Body_SetLinearVelocity(physicsBody.BodyId, physicsBody.LinearVelocity.ToB2());
            b2Body_SetAngularVelocity(physicsBody.BodyId, physicsBody.AngularVelocity);
        }

        if (setAwake) b2Body_SetAwake(physicsBody.BodyId, true);
    }

    private static B2BodyId CreateBody(ref PhysicsBodyComponent physicsBody, ref Entity entity)
    {
        var bodyDef = b2DefaultBodyDef();
        bodyDef.type = physicsBody.Type;
        bodyDef.position = entity.GetWorldPos(out float rotation).ToB2();
        bodyDef.rotation = b2MakeRot(rotation);
        bodyDef.angularDamping = 4f;
        bodyDef.linearDamping = 3f;

        bodyDef.angularVelocity = physicsBody.AngularVelocity;
        bodyDef.linearVelocity = physicsBody.LinearVelocity.ToB2();
        if (physicsBody.FixedRotation) bodyDef.motionLocks = new B2MotionLocks { angularZ = true };

        return b2CreateBody(Physics.WorldId, in bodyDef);
    }

    private void SynchronizeShapeToBox2d(ref PhysicsShapeComponent physicsShape, Entity entity)
    {
        var data = entity.Data;
        ref var hitbox = ref data.Ensure<HitboxComponent>(cb);
        bool validShape = b2Shape_IsValid(physicsShape.ShapeId);
        if (validShape && physicsShape.PhysicsDirty)
        {
            b2DestroyShape(physicsShape.ShapeId, true);
            validShape = false;
        }

        bool hasTransform = data.Has<Transform2D>();
        ref var transform = ref (hasTransform ? ref data.Get<Transform2D>() : ref Unsafe.NullRef<Transform2D>());

        if (validShape && (!hasTransform || !transform.PhysicsDirty) && !hitbox.PhysicsDirty) return;
        var bodyEntity = entity.GetFirstEntityWithComp<PhysicsBodyComponent>();
        if (bodyEntity.IsNull) return;

        var bodyData = bodyEntity.Data;
        ref var physicsBody = ref bodyData.Get<PhysicsBodyComponent>();

        var bodyPos = bodyEntity.GetWorldPos(out float bodyRot);
        var position = entity.GetWorldPos(out float rotation);

        var relativePos = hitbox.Rect.Center + position - bodyPos;
        float relativeRot = rotation - bodyRot;
        relativePos.Rotate(rotation - bodyRot);

        switch (hitbox.Type)
        {
        case HitboxType.OrientedRect:
            ref var rect = ref hitbox.Rect;
            relativeRot += rect.Angle;
            var polygon = b2MakeOffsetBox(rect.Width / 2, rect.Height / 2, relativePos.ToB2(), b2MakeRot(relativeRot));

            if (validShape)
            {
                b2Shape_SetPolygon(physicsShape.ShapeId, ref polygon);
                UpdateExistingShape(ref physicsShape, ref hitbox);
            }
            else
            {
                var shapeDef = CreateShapeDef(ref physicsShape, ref hitbox);
                physicsShape.SetIndexedValue(in entity, b2CreatePolygonShape(physicsBody.BodyId, in shapeDef, in polygon), in ShapesIndex);
            }
            break;
        case HitboxType.Capsule:
            var capsule = hitbox.Capsule.ToB2();
            var rot = b2MakeRot(relativeRot);
            capsule.center1 = b2RotateVector(in rot, in capsule.center1);
            capsule.center2 = b2RotateVector(in rot, in capsule.center2);

            if (validShape)
            {
                b2Shape_SetCapsule(physicsShape.ShapeId, in capsule);
                UpdateExistingShape(ref physicsShape, ref hitbox);
            }
            else
            {
                var shapeDef = CreateShapeDef(ref physicsShape, ref hitbox);
                physicsShape.SetIndexedValue(in entity, b2CreateCapsuleShape(physicsBody.BodyId, in shapeDef, in capsule), in ShapesIndex);
            }
            break;
        default:
            Guard.Exception($"Hitbox component on entity with id {entity.Id} is not a valid type: {hitbox.Type}");
            break;
        }

        b2Body_SetAwake(physicsBody.BodyId, true);
    }

    private static void UpdateExistingShape(ref PhysicsShapeComponent physicsShape, ref HitboxComponent hitbox)
    {
        b2Shape_EnableSensorEvents(physicsShape.ShapeId, hitbox.Collidable);
    }

    private static B2ShapeDef CreateShapeDef(ref PhysicsShapeComponent physicsShape, ref HitboxComponent hitbox)
    {
        var shapeDef = b2DefaultShapeDef();
        physicsShape.ApplyTo(ref shapeDef);
        shapeDef.enableSensorEvents = hitbox.Collidable;
        return shapeDef;
    }

    private void SynchronizeEcs()
    {
        PhysicsBodyQuery.ForEachEntity(SynchronizeBodyToEcs);
    }

    private void SynchronizeBodyToEcs(ref PhysicsBodyComponent physicsBody, Entity entity)
    {
        var data = entity.Data;
        ref var transform = ref data.Ensure<Transform2D>(cb);

        var b2transform = b2Body_GetTransform(physicsBody.BodyId);
        transform.Position = b2transform.p.ToXNA() - entity.GetParentPos(out float parentRotation);
        transform.Rotation = b2Rot_GetAngle(b2transform.q) - parentRotation;

        physicsBody.LinearVelocity = b2Body_GetLinearVelocity(physicsBody.BodyId).ToXNA();
        physicsBody.AngularVelocity = b2Body_GetAngularVelocity(physicsBody.BodyId);


        //i think shapes are not modified by box2d?
    }

    private void UnsetDirty()
    {
        TransformQuery.ForEachEntity(UnsetTransformDirty);
        HitboxQuery.ForEachEntity(UnsetHitboxDirty);
        PhysicsBodyQuery.ForEachEntity(UnsetPhysicsBodyDirty);
        PhysicsShapeQuery.ForEachEntity(UnsetPhysicsShapeDirty);
    }

    private void UnsetTransformDirty(ref Transform2D transform, Entity entity) => transform.PhysicsDirty = false;
    private void UnsetHitboxDirty(ref HitboxComponent hitbox, Entity entity) => hitbox.PhysicsDirty = false;
    private void UnsetPhysicsBodyDirty(ref PhysicsBodyComponent physicsBody, Entity entity) => physicsBody.PhysicsDirty = false;
    private void UnsetPhysicsShapeDirty(ref PhysicsShapeComponent physicsShape, Entity entity) => physicsShape.PhysicsDirty = false;


    private void ResolveEvents()
    {
        var sensorEvents = b2World_GetSensorEvents(Physics.WorldId);

        for (int i = 0; i < sensorEvents.beginCount; i++)
        {
            var e = sensorEvents.beginEvents[i];
            var sensorEntities = ShapesIndex[e.sensorShapeId];
            if (sensorEntities.Count == 0) continue;
            var sensorEntity = sensorEntities[0];
            var visitorEntities = ShapesIndex[e.visitorShapeId];
            if (visitorEntities.Count == 0) continue;
            var visitorEntity = visitorEntities[0];

            HandleCollision(sensorEntity, visitorEntity);
        }

    }

    private void HandleCollision(Entity sensorEntity, Entity visitorEntity)
    {
        var sensorData = sensorEntity.Data;
        var visitorData = visitorEntity.Data;
        if (visitorData.Has<BodyComponent>() && sensorData.Has<DamagerComponent>())
        {
            visitorEntity.AddRelation(new DamageRelation(sensorEntity));
        }
    }
}
