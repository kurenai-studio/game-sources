using System;

namespace TowerProtect.Domain.Client.Entities.Interpolation;

internal class RotationInterpolator : InterpolatorBase<double>
{
    private double _lastUnwrappedAngle;
    private bool _initialized;

    protected override double PreprocessValue(double value)
    {
        if (!_initialized)
        {
            _lastUnwrappedAngle = value;
            _initialized = true;
            return value;
        }

        double delta = (value - _lastUnwrappedAngle) % (2.0 * Math.PI);
        if (delta > Math.PI) delta -= 2.0 * Math.PI;
        if (delta < -Math.PI) delta += 2.0 * Math.PI;

        _lastUnwrappedAngle += delta;
        
        return _lastUnwrappedAngle;
    }

    protected override double InterpolateCore(double p0, double p1, double p2, double p3, double t, double t2, double t3)
    {
        double result = CatmullRom(p0, p1, p2, p3, t, t2, t3);

        double normalized = result % (2.0 * Math.PI);
        if (normalized < 0.0) normalized += 2.0 * Math.PI;

        return normalized;
    }
}
