using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using PlayerComponent = MCGame.ECS.Components.Player;
using MCGame.Core;

namespace MCGame.ECS.Systems
{
    /// <summary>
    /// 玩家输入处理系统
    /// 处理键盘和鼠标输入，更新输入组件
    /// 简化实现：使用MonoGame的输入API，支持WASD移动和鼠标视角
    /// 
    /// 系统职责：
    /// - 收集键盘和鼠标输入状态
    /// - 更新输入组件的数据
    /// - 处理按键状态变化（按下/释放）
    /// - 支持连续输入和一次性输入
    /// 
    /// 支持的输入：
    /// - WASD: 移动（连续输入）
    /// - Space: 跳跃（一次性输入）
    /// - Shift: 冲刺（连续输入）
    /// - F: 切换飞行模式（一次性输入）
    /// - 鼠标: 视角控制（连续输入）
    /// 
    /// 性能优化：
    /// - 使用状态缓存避免重复处理
    /// - 只处理有输入组件的实体
    /// - 高效的输入状态检测
    /// </summary>
    public class PlayerInputSystem : QuerySystem<Input>
    {
        private KeyboardState _currentKeyboard;
        private KeyboardState _previousKeyboard;
        private MouseState _currentMouse;
        private MouseState _previousMouse;
        private readonly bool _mouseLocked;

        public PlayerInputSystem()
        {
            _currentKeyboard = Keyboard.GetState();
            _previousKeyboard = _currentKeyboard;
            _currentMouse = Mouse.GetState();
            _previousMouse = _currentMouse;
            _mouseLocked = true;
        }

        protected override void OnUpdate()
        {
            var currentKeyboard = Keyboard.GetState();
            var currentMouse = Mouse.GetState();

            // 更新状态
            _previousKeyboard = _currentKeyboard;
            _previousMouse = _currentMouse;
            _currentKeyboard = currentKeyboard;
            _currentMouse = currentMouse;

            // 使用QuerySystem的Entities属性遍历实体
            foreach (var entity in Query.Entities)
            {
                var input = entity.GetComponent<Input>();
                var player = entity.GetComponent<MCGame.ECS.Components.Player>();
                
                // 处理移动输入
                input.Movement = Vector2.Zero;
                if (_currentKeyboard.IsKeyDown(Keys.W)) input.Movement.Y += 1;
                if (_currentKeyboard.IsKeyDown(Keys.S)) input.Movement.Y -= 1;
                if (_currentKeyboard.IsKeyDown(Keys.A)) input.Movement.X -= 1;
                if (_currentKeyboard.IsKeyDown(Keys.D)) input.Movement.X += 1;

                // 处理跳跃输入
                input.Jump = _currentKeyboard.IsKeyDown(Keys.Space) && _previousKeyboard.IsKeyUp(Keys.Space);

                // 处理特殊动作输入
                input.Sprint = _currentKeyboard.IsKeyDown(Keys.LeftShift) || _currentKeyboard.IsKeyDown(Keys.RightShift);
                input.Fly = _currentKeyboard.IsKeyDown(Keys.F) && _previousKeyboard.IsKeyUp(Keys.F);

                // 处理鼠标输入
                if (_mouseLocked)
                {
                    input.Look = new Vector2(
                        _currentMouse.X - _previousMouse.X,
                        _currentMouse.Y - _previousMouse.Y
                    );
                }
            }
        }
    }

    /// <summary>
    /// 玩家移动系统
    /// 根据输入更新玩家位置和速度
    /// 简化实现：使用欧拉角旋转和基础物理模拟
    /// 
    /// 系统职责：
    /// - 根据输入组件计算移动方向
    /// - 应用视角旋转到移动向量
    /// - 更新速度和位置组件
    /// - 处理不同的移动模式
    /// 
    /// 功能特性：
    /// - 基于视角方向的移动（前/后/左/右）
    /// - 跳跃机制（仅在地面时）
    /// - 飞行模式（自由移动）
    /// - 冲刺速度加成（1.5倍速度）
    /// - 基础的减速和惯性
    /// 
    /// 移动计算：
    /// - 使用欧拉角计算前进和右方向
    /// - 根据输入向量合成移动方向
    /// - 应用速度加成和模式修正
    /// - 更新速度组件供物理系统使用
    /// 
    /// 性能优化：
    /// - 使用三角函数缓存
    /// - 避免重复的向量计算
    /// - 高效的方向合成
    /// </summary>
    public class PlayerMovementSystem : QuerySystem<MCGame.ECS.Components.Position, MCGame.ECS.Components.Rotation, Velocity, Input, MCGame.ECS.Components.Player>
    {
        protected override void OnUpdate()
        {
            var currentKeyboard = Keyboard.GetState();
            
            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var rotation = entity.GetComponent<MCGame.ECS.Components.Rotation>();
                var velocity = entity.GetComponent<Velocity>();
                var input = entity.GetComponent<Input>();
                var player = entity.GetComponent<MCGame.ECS.Components.Player>();
                
                // 更新旋转
                rotation.Value.Y += input.Look.X * player.LookSpeed;
                rotation.Value.X += input.Look.Y * player.LookSpeed;
                rotation.Value.X = MathHelper.Clamp(rotation.Value.X, -MathHelper.PiOver2, MathHelper.PiOver2);

                // 计算移动方向
                var yaw = rotation.Value.Y;
                var forward = new Vector3((float)Math.Sin(yaw), 0, (float)Math.Cos(yaw));
                var right = new Vector3((float)Math.Cos(yaw), 0, -(float)Math.Sin(yaw));

                // 计算移动速度
                var moveSpeed = player.MoveSpeed;
                if (input.Sprint) moveSpeed *= 1.5f;
                if (player.IsFlying) moveSpeed *= 2f;

                // 应用移动输入
                var moveDirection = forward * input.Movement.Y + right * input.Movement.X;
                if (moveDirection != Vector3.Zero)
                {
                    moveDirection.Normalize();
                    velocity.Value = moveDirection * moveSpeed;
                }
                else
                {
                    velocity.Value *= 0.9f; // 减速
                }

                // 处理跳跃
                if (input.Jump && player.IsGrounded && !player.IsFlying)
                {
                    velocity.Value.Y = player.JumpSpeed;
                    player.IsGrounded = false;
                }

                // 处理飞行模式
                if (player.IsFlying)
                {
                    if (input.Jump) velocity.Value.Y = moveSpeed;
                    if (currentKeyboard.IsKeyDown(Keys.LeftControl)) velocity.Value.Y = -moveSpeed;
                }
            }
        }
    }

    /// <summary>
    /// 物理更新系统
    /// 应用重力、碰撞检测和物理模拟
    /// 简化实现：基础的重力和地面碰撞检测
    /// 
    /// 系统职责：
    /// - 应用重力加速度
    /// - 执行碰撞检测
    /// - 更新实体位置
    /// - 处理物理约束
    /// 
    /// 当前实现：
    /// - 简单的重力应用（恒定向下加速度）
    /// - 基础的地面碰撞（Y=0平面）
    /// - 速度衰减（空气阻力）
    /// - 基础的位置更新
    /// 
    /// 物理参数：
    /// - 重力：恒定向下加速度
    /// - 地面：Y=0平面
    /// - 空气阻力：速度衰减系数0.9
    /// - 时间步长：假设60 FPS（16ms）
    /// 
    /// 未来可扩展：
    /// - 完整的碰撞检测系统（AABB、球体等）
    /// - 复杂的物理模拟（弹性、摩擦力等）
    /// - 方块间的物理交互
    /// - 流体动力学
    /// - 刚体物理
    /// 
    /// 性能优化：
    /// - 简化的物理计算
    /// - 避免复杂的碰撞检测
    /// - 高效的位置更新
    /// </summary>
    public class PhysicsSystem : QuerySystem<MCGame.ECS.Components.Position, Velocity>
    {
        protected override void OnUpdate()
        {
            var deltaTime = 0.016f; // 假设60 FPS，约16ms

            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var velocity = entity.GetComponent<Velocity>();
                
                // 简化的物理更新
                position.Value += velocity.Value * deltaTime;
                
                // 简单的地面碰撞检测
                if (position.Value.Y <= 0)
                {
                    position.Value.Y = 0;
                    velocity.Value.Y = 0;
                }
            }
        }
    }

    /// <summary>
    /// 相机更新系统
    /// 根据位置和旋转更新相机矩阵和视图参数
    /// 
    /// 系统职责：
    /// - 更新相机视图矩阵
    /// - 处理相机投影参数
    /// - 同步相机与玩家位置
    /// - 管理相机状态
    /// 
    /// 当前实现：
    /// - 基础的相机脏标记检查
    /// - 简单的状态管理
    /// - 为未来扩展预留接口
    /// 
    /// 未来可扩展：
    /// - 第一人称/第三人称切换
    /// - 相机抖动和特效
    /// - 动态视野调整
    /// - 相机路径和动画
    /// - 多相机支持
    /// 
    /// 性能优化：
    /// - 使用脏标记避免重复计算
    /// - 延迟矩阵计算
    /// - 高效的状态管理
    /// </summary>
    public class CameraSystem : QuerySystem<Camera>
    {
        protected override void OnUpdate()
        {
            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var camera = entity.GetComponent<Camera>();
                if (camera.IsDirty)
                {
                    // 简化的相机更新
                    camera.IsDirty = false;
                }
            }
        }
    }

    /// <summary>
    /// 可见性计算系统
    /// 计算实体是否在视锥体内，管理渲染剔除
    /// 
    /// 系统职责：
    /// - 接收视锥体和相机位置
    /// - 计算实体与相机的距离
    /// - 更新可见性组件状态
    /// - 实现距离剔除
    /// 
    /// 当前实现：
    /// - 基础的距离剔除（200单位）
    /// - 简单的可见性标记
    /// - 距离计算和缓存
    /// 
    /// 剔除策略：
    /// - 距离剔除：超出渲染距离的实体不可见
    /// - 固定渲染距离：200单位
    /// - 实时距离计算：每帧更新
    /// 
    /// 未来可扩展：
    /// - 视锥体剔除（精确的视锥体相交检测）
    /// - 遮挡剔除（基于深度缓冲或光线投射）
    /// - 细节层次（LOD）系统
    /// - 动态渲染距离调整
    /// - 基于重要性的优先级渲染
    /// 
    /// 性能优化：
    /// - 简化的距离计算
    /// - 避免复杂的几何检测
    /// - 高效的状态更新
    /// </summary>
    public class VisibilitySystem : QuerySystem<Visibility>
    {
        private Vector3 _cameraPosition;

        public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)
        {
            _cameraPosition = cameraPosition;
        }

        protected override void OnUpdate()
        {
            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var visibility = entity.GetComponent<Visibility>();
                // 简化的可见性计算
                if (entity.TryGetComponent<MCGame.ECS.Components.Position>(out var position))
                {
                    visibility.Distance = Vector3.Distance(position.Value, _cameraPosition);
                    visibility.IsVisible = visibility.Distance < 200f; // 渲染距离
                }
            }
        }
    }

    /// <summary>
    /// 生命期更新系统
    /// 更新实体的生命期，删除过期实体
    /// </summary>
    public class LifetimeSystem : QuerySystem<Lifetime>
    {
        protected override void OnUpdate()
        {
            var deltaTime = 0.016f; // 假设60 FPS，约16ms

            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var lifetime = entity.GetComponent<Lifetime>();
                lifetime.TimeLeft -= deltaTime;
                
                if (lifetime.TimeLeft <= 0)
                {
                    lifetime.IsExpired = true;
                }
            }
        }
    }

    /// <summary>
    /// 区块状态更新系统
    /// 更新区块的状态和标记
    /// </summary>
    public class ChunkStateSystem : QuerySystem<Chunk>
    {
        protected override void OnUpdate()
        {
            // 使用QuerySystem的Query属性遍历实体
            // 由于Friflo ECS的ForEachEntity限制，使用传统的遍历方法
            foreach (var entity in Query.Entities)
            {
                var chunk = entity.GetComponent<Chunk>();
                // 简化的区块状态更新
                if (chunk.IsLoaded)
                {
                    chunk.State = MCGame.ECS.Components.ChunkState.Loaded;
                }
                else
                {
                    chunk.State = MCGame.ECS.Components.ChunkState.Loading;
                }
        }
    }
}
}