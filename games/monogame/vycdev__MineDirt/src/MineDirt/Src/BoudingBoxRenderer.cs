using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Net.NetworkInformation;

public static class BoundingBoxRenderer // Or place this method in your existing utility class
{
    // Pre-allocate arrays for indices to avoid new allocations each frame
    // Indices for the 12 triangles (6 faces * 2 triangles/face * 3 vertices/triangle)
    private static readonly short[] faceIndices = new short[]
    {
        // Front face (Z is MinZ)
        0, 1, 2, 0, 2, 3,
        // Back face (Z is MaxZ) - Winding order reversed for back viewing, or ensure culling is off/correct
        // For correct culling with CullCounterClockwise, these should be:
        4, 7, 6, 4, 6, 5, // If viewing from outside
        // Top face (Y is MaxY)
        3, 2, 6, 3, 6, 7,
        // Bottom face (Y is MinY)
        0, 4, 5, 0, 5, 1,
        // Right face (X is MaxX)
        1, 5, 6, 1, 6, 2,
        // Left face (X is MinX)
        0, 3, 7, 0, 7, 4
    };

    // Indices for the 12 lines
    private static readonly short[] lineIndices = new short[]
    {
        0, 1, 1, 2, 2, 3, 3, 0, // Bottom face
        4, 5, 5, 6, 6, 7, 7, 4, // Top face
        0, 4, 1, 5, 2, 6, 3, 7, // Vertical edges
    };

    private static VertexPositionColor[] boxVertices = new VertexPositionColor[8];

    private static Color FaceColor = new Color(255, 255, 255, 32); // For the transparent part
    private static Color LineColor = Color.Black;

    public static void DrawHighlightBox(
        BoundingBox box,
        GraphicsDevice graphicsDevice,
        BasicEffect effect,
        float offset = 0.005f // Slightly larger offset to ensure lines are visible over faces
    )
    {
        // --- Common Setup ---
        BoundingBox inflatedBox = box;
        inflatedBox.Min -= new Vector3(offset);
        inflatedBox.Max += new Vector3(offset);

        Vector3[] corners = inflatedBox.GetCorners();
        for (int i = 0; i < 8; i++)
        {
            boxVertices[i].Position = corners[i];
            // Color will be set per-draw call (faces vs lines)
        }

        // Store original states
        BlendState originalBlendState = graphicsDevice.BlendState;
        DepthStencilState originalDepthStencilState = graphicsDevice.DepthStencilState;
        RasterizerState originalRasterizerState = graphicsDevice.RasterizerState;

        effect.VertexColorEnabled = true;
        // World, View, Projection should be set on the effect externally before calling this

        // --- 1. Draw Transparent Faces ---
        for (int i = 0; i < 8; i++)
        {
            boxVertices[i].Color = FaceColor;
        }

        graphicsDevice.BlendState = BlendState.Additive; // For transparency
        graphicsDevice.DepthStencilState = DepthStencilState.Default; // Read depth but don't write, so lines can draw over
        graphicsDevice.RasterizerState = RasterizerState.CullCounterClockwise; // Standard culling

        effect.CurrentTechnique.Passes[0].Apply();
        graphicsDevice.DrawUserIndexedPrimitives(
            PrimitiveType.TriangleList,
            boxVertices,
            0,
            8, // Number of vertices in the vertex array
            faceIndices,
            0,
            faceIndices.Length / 3 // Number of primitives (triangles)
        );

        // --- 2. Draw Opaque Lines ---
        for (int i = 0; i < 8; i++)
        {
            boxVertices[i].Color = LineColor;
        }

        graphicsDevice.BlendState = BlendState.Opaque; // Lines are opaque
        graphicsDevice.DepthStencilState = DepthStencilState.Default; // Default depth testing for lines

        effect.CurrentTechnique.Passes[0].Apply();
        graphicsDevice.DrawUserIndexedPrimitives(
            PrimitiveType.LineList,
            boxVertices,
            0,
            8,  // Number of vertices
            lineIndices,
            0,
            lineIndices.Length / 2 // Number of primitives (lines)
        );

        // --- Restore original states ---
        graphicsDevice.BlendState = originalBlendState;
        graphicsDevice.DepthStencilState = originalDepthStencilState;
        graphicsDevice.RasterizerState = originalRasterizerState;
    }
}