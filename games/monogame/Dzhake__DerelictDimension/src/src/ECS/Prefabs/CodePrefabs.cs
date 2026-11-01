using Box2D.NET;
using DerelictDimension.ECS.Ai;
using DerelictDimension.ECS.Drawing;
using DerelictDimension.ECS.Links;
using DerelictDimension.ECS.PhysicsModule;
using DerelictDimension.ECS.PhysicsModule.Components;
using Monod.ECS.DefaultComponents;

namespace DerelictDimension.ECS.Prefabs;

public static class CodePrefabs
{
    public static Entity CreateHuman(Vector2 position, float rotation, string baseTexturePath, out Entity body, out Entity head, out Entity leftLeg, out Entity rightLeg)
    {
        var store = TheGame.Store;

        body = store.CreateEntity(new EntityName("Body"), new AnimatedSpriteComponent($"{baseTexturePath}body", [0, 1]), new RenderDepth(0.2f), new HitboxComponent(new Capsule(new(-.25f, 0), new(.25f, 0), 0.1f)), new PhysicsShapeComponent(categories: CollisionLayer.Enemy, mask: CollisionLayer.Walls | CollisionLayer.PlayerAttacks), new BodyComponent());

        head = store.CreateEntity(new EntityName("Head"), new AnimatedSpriteComponent($"{baseTexturePath}head", [0, 1]), new RenderDepth(0.1f));

        leftLeg = store.CreateEntity(new EntityName("Left leg"), new AnimatedSpriteComponent($"{baseTexturePath}left_leg", [0, 1, 2, 1, 0, 3, 4, 3], 0.1f), new RenderDepth(0.3f), Tags.Get<ParentVelocityDirTag, LegsTag>());

        rightLeg = store.CreateEntity(new EntityName("Right leg"), new AnimatedSpriteComponent($"{baseTexturePath}right_leg", [0, 1, 2, 1, 0, 3, 4, 3], 0.1f), new RenderDepth(0.3f), Tags.Get<ParentVelocityDirTag, LegsTag>());


        var entity = store.CreateEntity(new EntityName("Human base"), new Transform2D(position, rotation: rotation), new MortalComponent(), new PhysicsBodyComponent(B2BodyType.b2_dynamicBody, fixedRotation: true), new HumanBody(body), new HumanHead(head), new HumanLeftLeg(leftLeg), new HumanRightLeg(rightLeg));


        entity.AddChild(body);
        body.AddChild(head);
        entity.AddChild(leftLeg);
        entity.AddChild(rightLeg);

        return entity;
    }
}
