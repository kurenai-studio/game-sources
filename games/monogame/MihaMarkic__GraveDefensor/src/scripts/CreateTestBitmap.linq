<Query Kind="Statements">
  <NuGetReference>NUnit</NuGetReference>
  <NuGetReference>System.Collections.Immutable</NuGetReference>
  <Namespace>System.Collections.Immutable</Namespace>
  <Namespace>NUnit.Framework</Namespace>
  <Namespace>System.Drawing</Namespace>
  <Namespace>System.Drawing.Imaging</Namespace>
</Query>

var bmp = new Bitmap(600, 800, PixelFormat.Format24bppRgb);
Graphics g = Graphics.FromImage(bmp);
g.FillRectangle(new SolidBrush(Color.White), new Rectangle(0, 0, bmp.Width, bmp.Height));
g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.None;
g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.Default;
Pen pen = new Pen(Color.Black);
pen.Width = 1;
for (int i=0; i < (bmp.Width / 100); i++)
{
	g.DrawLine(pen, i * 100, 0, i * 100, bmp.Height-1);
}
g.DrawLine(pen, bmp.Width-1, 0, bmp.Width-1, bmp.Height-1);
for (int i = 0; i < (bmp.Height / 100); i++)
{
	g.DrawLine(pen, 0, i * 100, bmp.Width-1, i * 100);
}
g.DrawLine(pen, 0, bmp.Height-1, bmp.Width-1, bmp.Height-1);
bmp.Dump();
var path = Path.Combine(Path.GetDirectoryName(Util.CurrentQueryPath),@"..\src\GraveDefensor\Content\Scenes\Battle1.png");
bmp.Save(path, ImageFormat.Png);