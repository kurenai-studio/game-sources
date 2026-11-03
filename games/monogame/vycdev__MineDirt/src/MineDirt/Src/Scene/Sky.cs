using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MineDirt.Src.Scene;

public sealed class Sky{

#if DEBUG

    public enum DebugDisplayMode{
        Default = 0,
        Position,
        X,
        Y,
        Z,
        AstroUV,
    }

    private DebugDisplayMode mode = DebugDisplayMode.Default;
    public DebugDisplayMode DisplayMode{
        get => mode;
        set{
            mode = value;
            _shader.Parameters["DisplayMode"].SetValue((int)mode);
        }
    }

#endif

    const float RADIUS = 1f;
    const int QUALITY = 4;
    
    private static readonly short[] _indices = new short[(QUALITY * 4) * (QUALITY * 4 * 2) * 6];
    private static readonly VertexPosition[] _vertex = new VertexPosition[((QUALITY * 4)+1) * ((QUALITY * 4 * 2)+1)];

    private Effect _shader;

    static Sky(){
        CreateSphere();
    }

    public Sky(Effect effect){
        _shader = effect;

            DayColor          = new Color(0.518f, 0.918f, 1f);
            DayBottomColor    = new Color(0.314f, 0.6f, 0.78f);
            SunsetColor       = new Color(1f, 0.753f, 0.365f);
            SunsetBottomColor = new Color(0.988f, 0.871f, 0.32f);
            NightColor        = new Color(0.149f, 0, 0.329f);
            NightBottomColor  = new Color(0.082f, 0f, 0.2f);

    }


    private Vector3 sundir = new(0.034f,-0.826f,0.563f);
    public Vector3 SunDirection{
        get => sundir;
        set{
            sundir = value;
            _shader.Parameters["SunDirection"]?.SetValue(sundir);
        }
    }

    #region  C O L O R S

    Color dc;
    public Color DayColor{ get => dc; 
        set {
            dc = value; 
            _shader.Parameters["DayColor"]?.SetValue(dc.ToVector3());
        }}
    
    Color dbc;
    public Color DayBottomColor{ get => dbc; 
        set {
            dbc = value; 
            _shader.Parameters["DayBottomColor"]?.SetValue(dbc.ToVector3());
        }}
    Color sc;
    public Color SunsetColor{ get => sc; 
        set {
            sc = value; 
            _shader.Parameters["SunsetColor"]?.SetValue(sc.ToVector3());
        }}
    Color sbc;
    public Color SunsetBottomColor{ get => sbc; 
        set {
            sbc = value; 
            _shader.Parameters["SunsetBottomColor"]?.SetValue(sbc.ToVector3());
        }}
    Color nc;
    public Color NightColor{ get => nc; 
        set {
            nc = value; 
            _shader.Parameters["NightColor"]?.SetValue(nc.ToVector3());
        }}
    Color nbc;
    public Color NightBottomColor{ get => nbc; 
        set {
            nbc = value; 
            _shader.Parameters["NightBottomColor"]?.SetValue(nbc.ToVector3());
        }}

    #endregion


    #region Draw function
    public void Draw(GraphicsDevice graphics, Effect effect, Camera camera){

        Matrix projection = Matrix.CreatePerspectiveFieldOfView(MathHelper.PiOver2, camera.AspectRatio, 0.1f, RADIUS * 10f);

        effect.Parameters["WorldViewProjection"].SetValue(
            Matrix.CreateLookAt(Vector3.Zero, camera.Forward, Vector3.Up) * projection
        );

        //Not an expert, but I don't see why the skybox should write to the depth buffer
        graphics.DepthStencilState = DepthStencilState.None; 

        foreach(var pass in effect.CurrentTechnique.Passes){
            pass.Apply();
            graphics.DrawUserIndexedPrimitives(
                PrimitiveType.TriangleList,
                _vertex,
                0,
                _vertex.Length,
                _indices,
                0,
                _indices.Length / 3
            );
        }

        graphics.DepthStencilState = DepthStencilState.Default;

    }

    #endregion

    #region Sphere
    private static void CreateSphere(){
        int vSize = 4 * QUALITY;
        int uSize = vSize * 2;

        for (int i = 0, v = 0; v <= vSize; v++) {
            for (int u = 0; u <= uSize; u++, i++) {

                float theta = 2f * MathF.PI * (float)u/uSize + MathF.PI;
                float phi = MathF.PI * (float)v/vSize;

                float x = MathF.Cos(theta) * MathF.Sin(phi) * RADIUS;
                float y = -MathF.Cos(phi) * RADIUS;
                float z = MathF.Sin(theta) * MathF.Sin(phi) * RADIUS;

                _vertex[i] = new(new Vector3(x, y, z));
            }
        }

        //Indexes with already flipped triangles, no need to change cull mode
        for (short ti = 0, vi = 0, y = 0; y < vSize; y++, vi++) {
            for (short x = 0; x < uSize; x++, ti += 6, vi++) {
                _indices[ti] = vi;
                _indices[ti + 3] = _indices[ti + 2] = (short)(vi + 1);
                _indices[ti + 4] = _indices[ti + 1] = (short)(vi + uSize + 1);
                _indices[ti + 5] = (short)(vi + uSize + 2);
            }
        }
    }

    #endregion

}