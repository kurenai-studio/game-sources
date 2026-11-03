using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MineDirt.Src.Scene;

//It's self explanatory what it manages, in this tech demo it only stores different
//presets but in a full game it could even smoothly transition between them to simulate
//weather/time changes
public class EnvironmentSystem{

    public Sky Sky {get; private set;}

    #region FOG
    private Color _fog_c;
    public Color FogColor{
        get => _fog_c;
        set{
            _fog_c = value;
            _shader.Parameters["FogColor"].SetValue(_fog_c.ToVector4());
        }
    }

    private float _fog_den = 0.004f;
    public float FogDensity{
        get => _fog_den;
        set{
            _fog_den = value;
            _shader.Parameters["FogDensity"].SetValue(_fog_den);
        }
    }

    #endregion

    #region SKY
        private Vector3 _sun_dir = Vector3.Down;
        public Vector3 SunDirection{
            get => _sun_dir;
            set{
                _sun_dir = value;
                _shader.Parameters["SunDirection"].SetValue(_sun_dir);
                Sky.SunDirection = _sun_dir;
            }
        }

        private Color _sl_c;
        public Color SkyLightColor{
            get => _sl_c;
            set{
                _sl_c = value;
                _shader.Parameters["SkyLightColor"]?.SetValue(_sl_c.ToVector4());
            }
        }


    #endregion

    private Effect _shader; //It would be better to do this with a struct/constant buffer
    public EnvironmentSystem(Effect effect, Sky sky){
        _shader = effect;
        Sky = sky;

        FogColor = Color.CornflowerBlue;
        FogDensity = 0.004f;
        SunDirection = new(0.034f,-0.826f,0.563f);
        SkyLightColor = Color.White;

    }

}