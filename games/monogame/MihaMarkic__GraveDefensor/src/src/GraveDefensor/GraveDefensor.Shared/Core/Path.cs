using Microsoft.Xna.Framework;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Core
{
    public class Path
    {
        public Settings.Path Settings { get; private set; }
        public double[] SegmentsLengths { get; private set; }
        public double[] Angles { get; private set; }
        public Settings.Point LastPoint => Settings.Points[Settings.Points.Length - 1];
        public void Init(Settings.Path settings)
        {
            Settings = settings;
            SegmentsLengths = CalculateSegmentsLengths(settings.Points);
            Angles = CalculateSegmentsAngles(settings.Points);
        }

        internal static double[] CalculateSegmentsLengths(Settings.Point[] points)
        {
            var result = new double[points.Length - 1];
            for (int i = 0; i < points.Length-1; i++)
            {
                result[i] = DistanceBetweenPoints(points[i], points[i + 1]);
            }
            return result;
        }

        internal static double[] CalculateSegmentsAngles(Settings.Point[] points)
        {
            var result = new double[points.Length - 1];
            for (int i = 0; i < points.Length - 1; i++)
            {
                result[i] = GetAngleBetweenPoints(points[i], points[i + 1]);
            }
            return result;
        }

        internal static double DistanceBetweenPoints(Settings.Point a, Settings.Point b)
        {
            return Math.Abs(Vector2.Distance(new Vector2(a.X, a.Y), new Vector2(b.X, b.Y)));
        }
        public static double GetAngleBetweenPoints(Settings.Point a, Settings.Point b)
        {
            return Math.Atan2(b.Y - a.Y, b.X - a.X);
        }
        public static double GetAngleBetweenVectors(Vector2 a, Vector2 b)
        {
            return Math.Atan2(b.Y - a.Y, b.X - a.X);
        }
        public double CalculateLengthFromSegment(int startSegment)
        {
            double length = 0;
            for (int i = startSegment; i < SegmentsLengths.Length; i++)
            {
                length += SegmentsLengths[i];
            }
            return length;
        }
    }
}
