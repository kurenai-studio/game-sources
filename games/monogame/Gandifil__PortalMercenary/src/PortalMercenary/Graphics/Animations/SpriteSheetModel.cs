using System.Collections.Generic;

namespace PortalMercenary.Graphics.Animations;

public class SpriteSheetModel
{
    public string Atlas { get; set; }
    public List<AnimationModel> Animations { get; set; }

    public class AnimationModel
    {
        public string Name { get; set; }
        public bool IsLooping { get; set; }
        public FrameModel[] Frames { get; set; }

        public class FrameModel
        {
            public string Name { get; set; }
            public float Duration { get; set; }
        }
    }
}