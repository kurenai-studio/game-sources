using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// C# Wrapper for high-performance C++ NativeRoguelikeCore.dll.
    /// Provides spatial hash partitioning and multi-agent boids steering.
    /// Automatically detects native DLL availability and seamlessly falls back to pure C# managed logic.
    /// </summary>
    public static class NativeRoguelikeCore
    {
        private const string DllName = "NativeRoguelikeCore";

        public static bool IsNativeAvailable { get; private set; }

        static NativeRoguelikeCore()
        {
            try
            {
                int ver = Native_GetVersion();
                IsNativeAvailable = (ver >= 100);
                Debug.Log($"[NativeRoguelikeCore] Native C++ Plugin loaded successfully! (v{ver})");
            }
            catch (Exception ex)
            {
                IsNativeAvailable = false;
                Debug.Log($"[NativeRoguelikeCore] Native plugin not active ({ex.GetType().Name}). Running high-performance C# managed fallback.");
            }
        }

        // ── P/Invoke Bindings ────────────────────────────────────────────────
        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int Native_GetVersion();

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern void Native_SpatialGrid_Init(float minX, float minY, float maxX, float maxY, float cellSize);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern void Native_SpatialGrid_Clear();

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern void Native_SpatialGrid_Insert(int id, float x, float y, float radius, int typeTag);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int Native_SpatialGrid_QueryRadius(float x, float y, float radius, [Out] int[] outIds, [Out] float[] outDistSq, int maxCount);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int Native_SpatialGrid_FindNearest(float x, float y, float maxRadius, int filterTag, out int outId, out float outDist);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        private static extern void Native_Steering_ComputeSwarm(
            float[] inPositionsX,
            float[] inPositionsY,
            float[] inVelocitiesX,
            float[] inVelocitiesY,
            int count,
            float targetX,
            float targetY,
            float targetSpeed,
            float separationRadius,
            float separationWeight,
            [Out] float[] outVelocitiesX,
            [Out] float[] outVelocitiesY
        );

        // ── Managed Fallback Implementation ──────────────────────────────────
        private struct ManagedEntity
        {
            public int id;
            public float x, y, radius;
            public int typeTag;
        }

        private static readonly List<ManagedEntity> _managedEntities = new List<ManagedEntity>(256);

        public static void InitGrid(float minX, float minY, float maxX, float maxY, float cellSize = 2f)
        {
            if (IsNativeAvailable)
            {
                try { Native_SpatialGrid_Init(minX, minY, maxX, maxY, cellSize); return; }
                catch { IsNativeAvailable = false; }
            }
            _managedEntities.Clear();
        }

        public static void ClearGrid()
        {
            if (IsNativeAvailable)
            {
                try { Native_SpatialGrid_Clear(); return; }
                catch { IsNativeAvailable = false; }
            }
            _managedEntities.Clear();
        }

        public static void InsertGrid(int id, float x, float y, float radius, int typeTag = 0)
        {
            if (IsNativeAvailable)
            {
                try { Native_SpatialGrid_Insert(id, x, y, radius, typeTag); return; }
                catch { IsNativeAvailable = false; }
            }
            _managedEntities.Add(new ManagedEntity { id = id, x = x, y = y, radius = radius, typeTag = typeTag });
        }

        public static int QueryRadius(float x, float y, float radius, int[] outIds, float[] outDistSq, int maxCount)
        {
            if (outIds == null || maxCount <= 0) return 0;

            if (IsNativeAvailable)
            {
                try { return Native_SpatialGrid_QueryRadius(x, y, radius, outIds, outDistSq, maxCount); }
                catch { IsNativeAvailable = false; }
            }

            int found = 0;
            float radSq = radius * radius;
            for (int i = 0; i < _managedEntities.Count && found < maxCount; i++)
            {
                var e = _managedEntities[i];
                float dx = e.x - x;
                float dy = e.y - y;
                float totR = radius + e.radius;
                float dSq = dx * dx + dy * dy;
                if (dSq <= totR * totR)
                {
                    outIds[found] = e.id;
                    if (outDistSq != null) outDistSq[found] = dSq;
                    found++;
                }
            }
            return found;
        }

        public static bool FindNearest(float x, float y, float maxRadius, int filterTag, out int outId, out float outDist)
        {
            outId = -1;
            outDist = maxRadius;

            if (IsNativeAvailable)
            {
                try
                {
                    int res = Native_SpatialGrid_FindNearest(x, y, maxRadius, filterTag, out outId, out outDist);
                    return res == 1;
                }
                catch { IsNativeAvailable = false; }
            }

            float bestDistSq = maxRadius * maxRadius;
            bool found = false;

            for (int i = 0; i < _managedEntities.Count; i++)
            {
                var e = _managedEntities[i];
                if (filterTag >= 0 && e.typeTag != filterTag) continue;

                float dx = e.x - x;
                float dy = e.y - y;
                float dSq = dx * dx + dy * dy;

                if (dSq < bestDistSq)
                {
                    bestDistSq = dSq;
                    outId = e.id;
                    found = true;
                }
            }

            if (found)
            {
                outDist = Mathf.Sqrt(bestDistSq);
            }
            return found;
        }

        public static void ComputeSwarm(
            float[] posX, float[] posY,
            float[] velX, float[] velY,
            int count,
            float targetX, float targetY,
            float targetSpeed,
            float sepRadius, float sepWeight,
            float[] outVx, float[] outVy)
        {
            if (count <= 0 || posX == null || posY == null || outVx == null || outVy == null) return;

            if (IsNativeAvailable)
            {
                try
                {
                    Native_Steering_ComputeSwarm(posX, posY, velX, velY, count, targetX, targetY, targetSpeed, sepRadius, sepWeight, outVx, outVy);
                    return;
                }
                catch { IsNativeAvailable = false; }
            }

            // High-performance managed fallback loop
            float sepRadSq = sepRadius * sepRadius;
            float invSepRad = (sepRadius > 0.001f) ? (1f / sepRadius) : 1f;

            for (int i = 0; i < count; i++)
            {
                float px = posX[i];
                float py = posY[i];

                float dx = targetX - px;
                float dy = targetY - py;
                float dist = Mathf.Sqrt(dx * dx + dy * dy);

                float desVx = 0f, desVy = 0f;
                if (dist > 0.001f)
                {
                    desVx = (dx / dist) * targetSpeed;
                    desVy = (dy / dist) * targetSpeed;
                }

                float sepX = 0f, sepY = 0f;
                int neighbors = 0;
                for (int j = 0; j < count; j++)
                {
                    if (i == j) continue;
                    float nx = px - posX[j];
                    float ny = py - posY[j];
                    float dSq = nx * nx + ny * ny;
                    if (dSq > 0.0001f && dSq < sepRadSq)
                    {
                        float d = Mathf.Sqrt(dSq);
                        float s = 1f - d * invSepRad;
                        sepX += (nx / d) * s;
                        sepY += (ny / d) * s;
                        neighbors++;
                    }
                }

                if (neighbors > 0)
                {
                    sepX *= sepWeight;
                    sepY *= sepWeight;
                }

                float fVx = desVx + sepX;
                float fVy = desVy + sepY;
                float fSpeedSq = fVx * fVx + fVy * fVy;
                float maxSpeed = targetSpeed * 1.35f;
                if (fSpeedSq > maxSpeed * maxSpeed)
                {
                    float fSpeed = Mathf.Sqrt(fSpeedSq);
                    fVx = (fVx / fSpeed) * maxSpeed;
                    fVy = (fVy / fSpeed) * maxSpeed;
                }

                outVx[i] = fVx;
                outVy[i] = fVy;
            }
        }
    }
}
