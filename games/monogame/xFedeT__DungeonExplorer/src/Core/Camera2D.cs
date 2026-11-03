using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace DungeonExplorer.Core
{
    /// <summary>
    /// Camera 2D con funzionalità di follow, zoom e smooth movement
    /// </summary>
    public class Camera2D
    {
        private Vector2 _position;
        private Vector2 _targetPosition;
        private float _zoom;
        private float _rotation;
        private Matrix _transform;
        private bool _transformNeedsUpdate;

        public Vector2 Position
        {
            get => _position;
            set
            {
                _position = value;
                _transformNeedsUpdate = true;
            }
        }

        public float Zoom
        {
            get => _zoom;
            set
            {
                _zoom = MathHelper.Clamp(value, MinZoom, MaxZoom);
                _transformNeedsUpdate = true;
            }
        }

        public float Rotation
        {
            get => _rotation;
            set
            {
                _rotation = value;
                _transformNeedsUpdate = true;
            }
        }

        public Matrix Transform
        {
            get
            {
                if (_transformNeedsUpdate)
                {
                    UpdateTransform();
                    _transformNeedsUpdate = false;
                }
                return _transform;
            }
        }

        public Viewport Viewport { get; private set; }
        public Vector2 Origin { get; private set; }
        public Vector2 Center => Position + Origin;

        // Proprietà per il movimento fluido
        public float FollowSpeed { get; set; } = 5.0f;
        public bool SmoothFollow { get; set; } = true;

        // Limiti zoom
        public float MinZoom { get; set; } = 0.5f;
        public float MaxZoom { get; set; } = 3.0f;

        // Limiti di movimento (opzionali)
        public Rectangle? MovementBounds { get; set; }

        public Camera2D(Viewport viewport)
        {
            Viewport = viewport;
            Origin = new Vector2(viewport.Width * 0.5f, viewport.Height * 0.5f);
            _position = Vector2.Zero;
            _targetPosition = Vector2.Zero;
            _zoom = 1.0f;
            _rotation = 0.0f;
            _transformNeedsUpdate = true;
        }

        /// <summary>
        /// Aggiorna la camera
        /// </summary>
        public void Update(GameTime gameTime = null)
        {
            if (SmoothFollow && gameTime != null)
            {
                float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
                Vector2 difference = _targetPosition - _position;
                
                if (difference.LengthSquared() > 0.01f) // Evita micro-movimenti
                {
                    _position = Vector2.Lerp(_position, _targetPosition, FollowSpeed * deltaTime);
                    _transformNeedsUpdate = true;
                }
            }

            ApplyMovementBounds();
        }

        /// <summary>
        /// Imposta la camera per seguire una posizione
        /// </summary>
        public void Follow(Vector2 targetPosition)
        {
            _targetPosition = targetPosition;
            
            if (!SmoothFollow)
            {
                Position = targetPosition;
            }
        }

        /// <summary>
        /// Centra immediatamente la camera su una posizione
        /// </summary>
        public void CenterOn(Vector2 position)
        {
            _targetPosition = position;
            Position = position;
        }

        /// <summary>
        /// Muove la camera di un offset
        /// </summary>
        public void Move(Vector2 offset)
        {
            _targetPosition += offset;
            if (!SmoothFollow)
            {
                Position += offset;
            }
        }

        /// <summary>
        /// Imposta lo zoom con animazione fluida
        /// </summary>
        public void SetZoom(float targetZoom, float lerpSpeed = 0.1f)
        {
            targetZoom = MathHelper.Clamp(targetZoom, MinZoom, MaxZoom);
            Zoom = MathHelper.Lerp(Zoom, targetZoom, lerpSpeed);
        }

        /// <summary>
        /// Ruota la camera
        /// </summary>
        public void Rotate(float deltaRotation)
        {
            Rotation += deltaRotation;
        }

        /// <summary>
        /// Converte coordinate schermo in coordinate mondo
        /// </summary>
        public Vector2 ScreenToWorld(Vector2 screenPosition)
        {
            Matrix invertedTransform = Matrix.Invert(Transform);
            return Vector2.Transform(screenPosition, invertedTransform);
        }

        /// <summary>
        /// Converte coordinate mondo in coordinate schermo
        /// </summary>
        public Vector2 WorldToScreen(Vector2 worldPosition)
        {
            return Vector2.Transform(worldPosition, Transform);
        }

        /// <summary>
        /// Controlla se un punto del mondo è visibile nella camera
        /// </summary>
        public bool IsInView(Vector2 worldPosition, float margin = 0)
        {
            var screenPos = WorldToScreen(worldPosition);
            return screenPos.X >= -margin && screenPos.X <= Viewport.Width + margin &&
                   screenPos.Y >= -margin && screenPos.Y <= Viewport.Height + margin;
        }

        /// <summary>
        /// Controlla se un rettangolo del mondo è visibile nella camera
        /// </summary>
        public bool IsInView(Rectangle worldBounds, float margin = 0)
        {
            var topLeft = WorldToScreen(new Vector2(worldBounds.Left, worldBounds.Top));
            var bottomRight = WorldToScreen(new Vector2(worldBounds.Right, worldBounds.Bottom));

            return topLeft.X <= Viewport.Width + margin && bottomRight.X >= -margin &&
                   topLeft.Y <= Viewport.Height + margin && bottomRight.Y >= -margin;
        }

        /// <summary>
        /// Ottiene i bounds del mondo visibili dalla camera
        /// </summary>
        public Rectangle GetVisibleArea()
        {
            var topLeft = ScreenToWorld(Vector2.Zero);
            var bottomRight = ScreenToWorld(new Vector2(Viewport.Width, Viewport.Height));

            return new Rectangle(
                (int)topLeft.X,
                (int)topLeft.Y,
                (int)(bottomRight.X - topLeft.X),
                (int)(bottomRight.Y - topLeft.Y)
            );
        }

        /// <summary>
        /// Scuote la camera per effetti di impatto
        /// </summary>
        public void Shake(float intensity, float duration)
        {
            // Implementazione base per camera shake
            var random = new Random();
            var offset = new Vector2(
                (float)(random.NextDouble() - 0.5) * intensity,
                (float)(random.NextDouble() - 0.5) * intensity
            );
            
            Position += offset;
        }

        /// <summary>
        /// Aggiorna la matrice di trasformazione
        /// </summary>
        private void UpdateTransform()
        {
            _transform = Matrix.CreateTranslation(-_position.X, -_position.Y, 0) *
                        Matrix.CreateRotationZ(_rotation) *
                        Matrix.CreateScale(_zoom) *
                        Matrix.CreateTranslation(Origin.X, Origin.Y, 0);
        }

        /// <summary>
        /// Applica i limiti di movimento se impostati
        /// </summary>
        private void ApplyMovementBounds()
        {
            if (MovementBounds.HasValue)
            {
                var bounds = MovementBounds.Value;
                var visibleArea = GetVisibleArea();

                // Calcola i limiti considerando le dimensioni dell'area visibile
                float leftLimit = bounds.Left + visibleArea.Width * 0.5f;
                float rightLimit = bounds.Right - visibleArea.Width * 0.5f;
                float topLimit = bounds.Top + visibleArea.Height * 0.5f;
                float bottomLimit = bounds.Bottom - visibleArea.Height * 0.5f;

                // Applica i limiti alla posizione target e attuale
                _targetPosition.X = MathHelper.Clamp(_targetPosition.X, leftLimit, rightLimit);
                _targetPosition.Y = MathHelper.Clamp(_targetPosition.Y, topLimit, bottomLimit);
                
                _position.X = MathHelper.Clamp(_position.X, leftLimit, rightLimit);
                _position.Y = MathHelper.Clamp(_position.Y, topLimit, bottomLimit);
                
                _transformNeedsUpdate = true;
            }
        }

        /// <summary>
        /// Aggiorna il viewport (da chiamare quando la finestra viene ridimensionata)
        /// </summary>
        public void UpdateViewport(Viewport newViewport)
        {
            Viewport = newViewport;
            Origin = new Vector2(newViewport.Width * 0.5f, newViewport.Height * 0.5f);
            _transformNeedsUpdate = true;
        }
    }
}