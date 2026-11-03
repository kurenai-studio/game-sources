using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MCGame.Core;
using System;

namespace MCGame.Player
{
    /// <summary>
    /// 玩家类
    /// 实现第一人称视角和移动控制
    /// 简化实现：基础的移动和视角控制
    /// </summary>
    public class Player
    {
        // 位置和方向
        private Vector3 _position;
        private Vector3 _velocity;
        private float _yaw;
        private float _pitch;
        
        // 移动参数
        private float _moveSpeed = 10f;
        private float _lookSpeed = 0.1f;
        private float _jumpSpeed = 8f;
        private float _gravity = -20f;
        
        // 碰撞检测
        private float _height = 1.8f;
        private float _width = 0.6f;
        private bool _isGrounded;
        
        // 输入状态
        private KeyboardState _currentKeyboard;
        private KeyboardState _previousKeyboard;
        private MouseState _currentMouse;
        private MouseState _previousMouse;
        private bool _mouseLocked;
        
        // 相机矩阵
        private Matrix _viewMatrix;
        private Matrix _projectionMatrix;
        private bool _viewMatrixDirty;
        
        // 性能优化：避免频繁计算
        private Vector3 _forward;
        private Vector3 _right;
        private Vector3 _up;

        public Vector3 Position => _position;
        public Vector3 Velocity => _velocity;
        public float Yaw => _yaw;
        public float Pitch => _pitch;
        public bool IsGrounded => _isGrounded;
        public Matrix ViewMatrix => _viewMatrix;
        public Matrix ProjectionMatrix => _projectionMatrix;
        public Vector3 Forward => _forward;
        public Vector3 Right => _right;
        public Vector3 Up => _up;

        public Player(Vector3 initialPosition)
        {
            _position = initialPosition;
            _velocity = Vector3.Zero;
            _yaw = 0f;
            _pitch = 0f;
            _isGrounded = false;
            _mouseLocked = false;
            _viewMatrixDirty = true;
            
            // 初始化方向向量
            UpdateDirectionVectors();
        }

        /// <summary>
        /// 初始化投影矩阵
        /// </summary>
        public void InitializeProjection(GraphicsDevice graphicsDevice, float fieldOfView = MathHelper.PiOver4)
        {
            var aspectRatio = graphicsDevice.Viewport.AspectRatio;
            _projectionMatrix = Matrix.CreatePerspectiveFieldOfView(
                fieldOfView,
                aspectRatio,
                0.1f,
                1000f
            );
        }

        /// <summary>
        /// 更新输入状态
        /// </summary>
        public void UpdateInput()
        {
            _previousKeyboard = _currentKeyboard;
            _previousMouse = _currentMouse;
            
            _currentKeyboard = Keyboard.GetState();
            _currentMouse = Mouse.GetState();
            
            // 处理鼠标锁定
            HandleMouseLock();
        }

        /// <summary>
        /// 处理鼠标锁定
        /// </summary>
        private void HandleMouseLock()
        {
            // 按Tab键切换鼠标锁定
            if (IsKeyPressed(Keys.Tab))
            {
                _mouseLocked = !_mouseLocked;
                Mouse.SetPosition(400, 300); // 重置到屏幕中心
            }
            
            if (_mouseLocked)
            {
                // 锁定鼠标到屏幕中心
                Mouse.SetPosition(400, 300);
            }
        }

        /// <summary>
        /// 更新玩家状态
        /// </summary>
        public void Update(GameTime gameTime)
        {
            var deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
            
            // 处理输入
            HandleMovement(deltaTime);
            HandleMouseLook(deltaTime);
            HandleJump();
            
            // 应用物理
            ApplyPhysics(deltaTime);
            
            // 更新方向向量
            UpdateDirectionVectors();
            
            // 更新视图矩阵
            UpdateViewMatrix();
        }

        /// <summary>
        /// 处理移动输入
        /// </summary>
        private void HandleMovement(float deltaTime)
        {
            var moveDirection = Vector3.Zero;
            
            // 前后移动
            if (IsKeyDown(Keys.W))
                moveDirection += _forward;
            if (IsKeyDown(Keys.S))
                moveDirection -= _forward;
            
            // 左右移动
            if (IsKeyDown(Keys.A))
                moveDirection -= _right;
            if (IsKeyDown(Keys.D))
                moveDirection += _right;
            
            // 标准化移动方向
            if (moveDirection != Vector3.Zero)
            {
                moveDirection.Normalize();
                moveDirection.Y = 0; // 保持水平移动
                moveDirection.Normalize();
                
                // 应用移动速度
                _velocity.X = moveDirection.X * _moveSpeed;
                _velocity.Z = moveDirection.Z * _moveSpeed;
            }
            else
            {
                // 应用摩擦力
                _velocity.X *= 0.8f;
                _velocity.Z *= 0.8f;
            }
        }

        /// <summary>
        /// 处理鼠标视角
        /// </summary>
        private void HandleMouseLook(float deltaTime)
        {
            if (_mouseLocked)
            {
                var deltaX = _currentMouse.X - _previousMouse.X;
                var deltaY = _currentMouse.Y - _previousMouse.Y;
                
                // 更新视角
                _yaw += deltaX * _lookSpeed;
                _pitch -= deltaY * _lookSpeed;
                
                // 限制俯仰角度
                _pitch = MathHelper.Clamp(_pitch, -MathHelper.PiOver2 + 0.1f, MathHelper.PiOver2 - 0.1f);
                
                // 标准化偏航角
                _yaw = MathHelper.WrapAngle(_yaw);
                
                _viewMatrixDirty = true;
            }
        }

        /// <summary>
        /// 处理跳跃
        /// </summary>
        private void HandleJump()
        {
            if (IsKeyPressed(Keys.Space) && _isGrounded)
            {
                _velocity.Y = _jumpSpeed;
                _isGrounded = false;
            }
        }

        /// <summary>
        /// 应用物理
        /// </summary>
        private void ApplyPhysics(float deltaTime)
        {
            // 应用重力 - 临时禁用，让玩家可以自由移动
            // TODO: 实现与地形系统的碰撞检测
            // _velocity.Y += _gravity * deltaTime;
            
            // 更新位置
            _position += _velocity * deltaTime;
            
            // 简单的地面检测 - 临时禁用，让玩家可以自由移动
            // TODO: 实现与地形系统的碰撞检测
            // if (_position.Y <= 1.0f)
            // {
            //     _position.Y = 1.0f;
            //     _velocity.Y = 0f;
            //     _isGrounded = true;
            // }
            // else
            // {
            //     _isGrounded = false;
            // }
            
            _viewMatrixDirty = true;
        }

        /// <summary>
        /// 更新方向向量
        /// </summary>
        private void UpdateDirectionVectors()
        {
            // 计算前向向量（不包含俯仰）
            _forward = new Vector3(
                (float)Math.Sin(_yaw),
                0f,
                (float)Math.Cos(_yaw)
            );
            _forward.Normalize();
            
            // 计算右向向量
            _right = Vector3.Cross(_forward, Vector3.Up);
            _right.Normalize();
            
            // 计算上向向量
            _up = Vector3.Cross(_right, _forward);
            _up.Normalize();
        }

        /// <summary>
        /// 更新视图矩阵
        /// </summary>
        private void UpdateViewMatrix()
        {
            if (_viewMatrixDirty)
            {
                // 计算实际的前向向量（包含俯仰）
                var actualForward = new Vector3(
                    (float)Math.Sin(_yaw) * (float)Math.Cos(_pitch),
                    (float)Math.Sin(_pitch),
                    (float)Math.Cos(_yaw) * (float)Math.Cos(_pitch)
                );
                actualForward.Normalize();
                
                // 创建视图矩阵
                _viewMatrix = Matrix.CreateLookAt(
                    _position,
                    _position + actualForward,
                    Vector3.Up
                );
                
                _viewMatrixDirty = false;
            }
        }

        /// <summary>
        /// 设置位置
        /// </summary>
        public void SetPosition(Vector3 position)
        {
            _position = position;
            _viewMatrixDirty = true;
        }

        /// <summary>
        /// 设置视角
        /// </summary>
        public void SetRotation(float yaw, float pitch)
        {
            _yaw = yaw;
            _pitch = MathHelper.Clamp(pitch, -MathHelper.PiOver2 + 0.1f, MathHelper.PiOver2 - 0.1f);
            _viewMatrixDirty = true;
        }

        /// <summary>
        /// 设置移动速度
        /// </summary>
        public void SetMoveSpeed(float speed)
        {
            _moveSpeed = speed;
        }

        /// <summary>
        /// 设置视角速度
        /// </summary>
        public void SetLookSpeed(float speed)
        {
            _lookSpeed = speed;
        }

        /// <summary>
        /// 获取视线方向
        /// </summary>
        public Vector3 GetLookDirection()
        {
            return new Vector3(
                (float)Math.Sin(_yaw) * (float)Math.Cos(_pitch),
                (float)Math.Sin(_pitch),
                (float)Math.Cos(_yaw) * (float)Math.Cos(_pitch)
            );
        }

        /// <summary>
        /// 获取射线起点和方向
        /// </summary>
        public (Vector3 origin, Vector3 direction) GetRay()
        {
            return (_position, GetLookDirection());
        }

        /// <summary>
        /// 检查按键是否按下
        /// </summary>
        public bool IsKeyDown(Keys key)
        {
            return _currentKeyboard.IsKeyDown(key);
        }

        /// <summary>
        /// 检查按键是否刚刚按下
        /// </summary>
        public bool IsKeyPressed(Keys key)
        {
            return _currentKeyboard.IsKeyDown(key) && _previousKeyboard.IsKeyUp(key);
        }

        /// <summary>
        /// 检查按键是否刚刚释放
        /// </summary>
        public bool IsKeyReleased(Keys key)
        {
            return _currentKeyboard.IsKeyUp(key) && _previousKeyboard.IsKeyDown(key);
        }

        /// <summary>
        /// 检查鼠标按钮是否按下
        /// </summary>
        public bool IsMouseButtonDown(MouseButton button)
        {
            return button switch
            {
                MouseButton.Left => _currentMouse.LeftButton == ButtonState.Pressed,
                MouseButton.Right => _currentMouse.RightButton == ButtonState.Pressed,
                MouseButton.Middle => _currentMouse.MiddleButton == ButtonState.Pressed,
                _ => false
            };
        }

        /// <summary>
        /// 检查鼠标按钮是否刚刚按下
        /// </summary>
        public bool IsMouseButtonPressed(MouseButton button)
        {
            var current = button switch
            {
                MouseButton.Left => _currentMouse.LeftButton,
                MouseButton.Right => _currentMouse.RightButton,
                MouseButton.Middle => _currentMouse.MiddleButton,
                _ => ButtonState.Released
            };
            
            var previous = button switch
            {
                MouseButton.Left => _previousMouse.LeftButton,
                MouseButton.Right => _previousMouse.RightButton,
                MouseButton.Middle => _previousMouse.MiddleButton,
                _ => ButtonState.Released
            };
            
            return current == ButtonState.Pressed && previous == ButtonState.Released;
        }

        /// <summary>
        /// 获取鼠标移动增量
        /// </summary>
        public Vector2 GetMouseDelta()
        {
            return new Vector2(
                _currentMouse.X - _previousMouse.X,
                _currentMouse.Y - _previousMouse.Y
            );
        }

        /// <summary>
        /// 获取鼠标滚轮增量
        /// </summary>
        public int GetMouseScrollDelta()
        {
            return _currentMouse.ScrollWheelValue - _previousMouse.ScrollWheelValue;
        }
    }

    /// <summary>
    /// 鼠标按钮枚举
    /// </summary>
    public enum MouseButton
    {
        Left,
        Right,
        Middle
    }

    /// <summary>
    /// 玩家控制器
    /// 管理玩家和相机的统一接口
    /// </summary>
    public class PlayerController
    {
        private readonly Player _player;
        private readonly GraphicsDevice _graphicsDevice;
        
        // 控制选项
        private bool _enableFlying;
        private float _flySpeed;
        
        // 交互状态
        private float _reachDistance = 5f;
        private BlockType _selectedBlockType = BlockType.Stone;

        public Player Player => _player;
        public bool EnableFlying
        {
            get => _enableFlying;
            set => _enableFlying = value;
        }

        public PlayerController(GraphicsDevice graphicsDevice, Vector3 initialPosition)
        {
            _graphicsDevice = graphicsDevice;
            _player = new Player(initialPosition);
            _enableFlying = false;
            _flySpeed = 20f;
            
            _player.InitializeProjection(graphicsDevice);
        }

        /// <summary>
        /// 更新控制器
        /// </summary>
        public void Update(GameTime gameTime)
        {
            _player.UpdateInput();
            
            // 处理飞行模式
            if (_enableFlying)
            {
                HandleFlying();
            }
            
            _player.Update(gameTime);
            
            // 处理交互
            HandleInteraction();
        }

        /// <summary>
        /// 处理飞行模式
        /// </summary>
        private void HandleFlying()
        {
            if (_player.IsKeyDown(Keys.LeftShift))
            {
                _player.SetPosition(_player.Position + Vector3.Down * _flySpeed * 0.016f);
            }
            if (_player.IsKeyDown(Keys.Space))
            {
                _player.SetPosition(_player.Position + Vector3.Up * _flySpeed * 0.016f);
            }
        }

        /// <summary>
        /// 处理交互
        /// </summary>
        private void HandleInteraction()
        {
            // 左键破坏方块
            if (_player.IsMouseButtonPressed(MouseButton.Left))
            {
                BreakBlock();
            }
            
            // 右键放置方块
            if (_player.IsMouseButtonPressed(MouseButton.Right))
            {
                PlaceBlock();
            }
            
            // 滚轮切换方块类型
            var scrollDelta = _player.GetMouseScrollDelta();
            if (scrollDelta != 0)
            {
                CycleBlockType(scrollDelta > 0);
            }
        }

        /// <summary>
        /// 破坏方块
        /// </summary>
        private void BreakBlock()
        {
            // 这里需要实现射线检测和方块破坏逻辑
            // 简化实现：预留接口
        }

        /// <summary>
        /// 放置方块
        /// </summary>
        private void PlaceBlock()
        {
            // 这里需要实现射线检测和方块放置逻辑
            // 简化实现：预留接口
        }

        /// <summary>
        /// 切换方块类型
        /// </summary>
        private void CycleBlockType(bool next)
        {
            // 简化实现：循环几种基础方块
            if (next)
            {
                _selectedBlockType = _selectedBlockType switch
                {
                    BlockType.Stone => BlockType.Grass,
                    BlockType.Grass => BlockType.Dirt,
                    BlockType.Dirt => BlockType.Wood,
                    BlockType.Wood => BlockType.Glass,
                    BlockType.Glass => BlockType.Stone,
                    _ => BlockType.Stone
                };
            }
            else
            {
                _selectedBlockType = _selectedBlockType switch
                {
                    BlockType.Stone => BlockType.Glass,
                    BlockType.Glass => BlockType.Wood,
                    BlockType.Wood => BlockType.Dirt,
                    BlockType.Dirt => BlockType.Grass,
                    BlockType.Grass => BlockType.Stone,
                    _ => BlockType.Stone
                };
            }
        }
    }
}