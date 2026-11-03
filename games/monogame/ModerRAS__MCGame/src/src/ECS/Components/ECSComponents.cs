using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using MCGame.Core;

namespace MCGame.ECS.Components
{
    /// <summary>
    /// 位置组件
    /// 存储实体的3D世界坐标
    /// </summary>
    public struct Position : IComponent
    {
        public Vector3 Value;
        
        public Position(Vector3 value) => Value = value;
        public Position(float x, float y, float z) => Value = new Vector3(x, y, z);
    }

    /// <summary>
    /// 旋转组件
    /// 存储实体的旋转角度（欧拉角）
    /// </summary>
    public struct Rotation : IComponent
    {
        public Vector3 Value; // Yaw, Pitch, Roll
        
        public Rotation(Vector3 value) => Value = value;
        public Rotation(float yaw, float pitch, float roll) => Value = new Vector3(yaw, pitch, roll);
    }

    /// <summary>
    /// 速度组件
    /// 存储实体的移动速度
    /// </summary>
    public struct Velocity : IComponent
    {
        public Vector3 Value;
        
        public Velocity(Vector3 value) => Value = value;
        public Velocity(float x, float y, float z) => Value = new Vector3(x, y, z);
    }

    /// <summary>
    /// 方块组件
    /// 存储方块实体的类型和属性
    /// </summary>
    public struct Block : IComponent
    {
        public BlockType Type;
        public BlockData Data;
        
        public Block(BlockType type) => (Type, Data) = (type, new BlockData(type));
    }

    /// <summary>
    /// 区块状态枚举
    /// </summary>
    public enum ChunkState
    {
        Unloaded,
        Loading,
        Loaded,
        Generating,
        Meshing,
        Unloading
    }

    /// <summary>
    /// 区块组件
    /// 存储区块的位置和状态信息
    /// </summary>
    public struct Chunk : IComponent
    {
        public ChunkPosition Position;
        public ChunkState State;
        public bool IsDirty;
        public bool IsLoaded;
        public bool IsMeshGenerated;
        
        public Chunk(ChunkPosition position) => Position = position;
    }

    /// <summary>
    /// 网格组件
    /// 存储实体的网格渲染数据
    /// </summary>
    public struct Mesh : IComponent
    {
        public bool IsDirty;
        public int VertexCount;
        public int IndexCount;
        public BoundingBox Bounds;
        
        public Mesh(BoundingBox bounds) => Bounds = bounds;
    }

    /// <summary>
    /// 玩家组件
    /// 标记实体为玩家
    /// </summary>
    public struct Player : IComponent
    {
        public float MoveSpeed;
        public float LookSpeed;
        public float JumpSpeed;
        public bool IsGrounded;
        public bool IsFlying;
        
        public Player(float moveSpeed = 10f, float lookSpeed = 0.1f, float jumpSpeed = 8f)
        {
            MoveSpeed = moveSpeed;
            LookSpeed = lookSpeed;
            JumpSpeed = jumpSpeed;
            IsGrounded = false;
            IsFlying = false;
        }
    }

    /// <summary>
    /// 相机组件
    /// 存储相机的投影和视图矩阵
    /// </summary>
    public struct Camera : IComponent
    {
        public Matrix ViewMatrix;
        public Matrix ProjectionMatrix;
        public float FieldOfView;
        public float AspectRatio;
        public float NearPlane;
        public float FarPlane;
        public bool IsDirty;
        
        public Camera(float fieldOfView = 75f, float aspectRatio = 16f/9f, float nearPlane = 0.1f, float farPlane = 1000f)
        {
            FieldOfView = fieldOfView;
            AspectRatio = aspectRatio;
            NearPlane = nearPlane;
            FarPlane = farPlane;
            IsDirty = true;
            ViewMatrix = Matrix.Identity;
            ProjectionMatrix = Matrix.Identity;
        }
    }

    /// <summary>
    /// 可见性组件
    /// 存储实体的可见性状态
    /// </summary>
    public struct Visibility : IComponent
    {
        public bool IsVisible;
        public float Distance;
        public bool InFrustum;
        
        public Visibility(bool isVisible = true) => IsVisible = isVisible;
    }

    /// <summary>
    /// 光照组件
    /// 存储实体的光照信息
    /// </summary>
    public struct Lighting : IComponent
    {
        public byte Brightness;
        public byte Sunlight;
        public byte Torchlight;
        public Color TintColor;
        
        public Lighting(byte brightness = 15) => Brightness = brightness;
    }

    /// <summary>
    /// 碰撞体组件
    /// 存储实体的碰撞检测信息
    /// </summary>
    public struct Collider : IComponent
    {
        public BoundingBox Bounds;
        public bool IsSolid;
        public bool IsTrigger;
        
        public Collider(BoundingBox bounds, bool isSolid = true)
        {
            Bounds = bounds;
            IsSolid = isSolid;
            IsTrigger = false;
        }
    }

    /// <summary>
    /// 输入组件
    /// 存储实体的输入状态
    /// </summary>
    public struct Input : IComponent
    {
        public Vector2 Movement;
        public Vector2 Look;
        public bool Jump;
        public bool Sprint;
        public bool Fly;
        
        public Input()
        {
            Movement = Vector2.Zero;
            Look = Vector2.Zero;
            Jump = false;
            Sprint = false;
            Fly = false;
        }
    }

    /// <summary>
    /// 生命期组件
    /// 存储实体的生命期信息
    /// </summary>
    public struct Lifetime : IComponent
    {
        public float TimeLeft;
        public bool IsExpired;
        
        public Lifetime(float timeLeft)
        {
            TimeLeft = timeLeft;
            IsExpired = false;
        }
    }

    /// <summary>
    /// 物理组件
    /// 存储实体的物理属性
    /// </summary>
    public struct Physics : IComponent
    {
        public float Mass;
        public float Drag;
        public float Bounciness;
        public Vector3 Gravity;
        
        public Physics(float mass = 1f, float drag = 0.1f)
        {
            Mass = mass;
            Drag = drag;
            Bounciness = 0f;
            Gravity = new Vector3(0, -9.81f, 0);
        }
    }
}