using Stride.Core.Mathematics;
using Stride.Engine;
using Stride.UI;
using Stride.UI.Controls;
using Stride.UI.Panels;

namespace AstroDrift
{
	// Stride UI overlay — builds a TextBlock for the controls strip and a
	// second one for score, attached to a UIComponent so it renders over
	// the 3D scene. Wire this script onto an Entity that has a UIComponent
	// in the Stride GameStudio asset editor.
	public class ControlsUi : StartupScript
	{
		public override void Start()
		{
			var ui = Entity.Get<UIComponent>();
			if (ui == null) return;

			var controls = new TextBlock
			{
				Text = "← → rotate   |   ↑ thrust   |   ↓ brake   |   Del fire   |   Esc quit",
				TextColor = new Color(158, 178, 217),
				TextSize = 18,
				HorizontalAlignment = HorizontalAlignment.Center,
				VerticalAlignment = VerticalAlignment.Bottom,
				Margin = new Thickness(0, 0, 0, 18),
			};

			var score = new TextBlock
			{
				Text = "Score 0   Wave 1   Lives 3",
				TextColor = new Color(235, 245, 255),
				TextSize = 22,
				HorizontalAlignment = HorizontalAlignment.Left,
				VerticalAlignment = VerticalAlignment.Top,
				Margin = new Thickness(16, 14, 0, 0),
			};

			var canvas = new Canvas();
			canvas.Children.Add(controls);
			canvas.Children.Add(score);
			ui.Page = new UIPage { RootElement = canvas };
		}
	}
}
