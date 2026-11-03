using System;
using System.Collections.Generic;
using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.Domain.Client.Entities.Interpolation;

internal abstract class InterpolatorBase<T> : IUpdateAware
{
    private const double TimeCatchUpSpeed = 1.0;

    private readonly LinkedList<TimePoint> _buffer = [];
    private bool _firstUpdate = true;

    private double _clientTime;
    private double _serverTime;

    public void Tick(T value, double tickTime)
    {
        _serverTime += tickTime;

        T processedValue = PreprocessValue(value);

        if (_buffer.Count == 0)
        {
            for (int i = 0; i < 4; i++)
            {
                double previousTime = _serverTime - (i * tickTime);
                _buffer.AddLast(new TimePoint(processedValue, previousTime));
            }
            return;
        }

        _buffer.AddFirst(new TimePoint(processedValue, _serverTime));
        _buffer.RemoveLast();
    }

    public void Update(double deltaTime)
    {
        _clientTime += deltaTime;

        if (_buffer.Count > 0)
        {
            double timeSum = 0.0;
            foreach (var tp in _buffer)
            {
                timeSum += tp.Time;
            }

            double targetClientTime = timeSum / _buffer.Count;
            if (_firstUpdate)
            {
                _clientTime = targetClientTime;
                _firstUpdate = false;
            }
            else
            {
                double diff = targetClientTime - _clientTime;
                _clientTime += diff * deltaTime * TimeCatchUpSpeed;
            }
        }
    }

    public T Interpolate()
    {
        if (_buffer.Count < 4)
            throw new InvalidOperationException("Cannot interpolate before filling buffer");

        LinkedListNode<TimePoint> n3 = _buffer.First!;
        LinkedListNode<TimePoint> n2 = n3.Next!;
        LinkedListNode<TimePoint> n1 = n2.Next!;
        LinkedListNode<TimePoint> n0 = n1.Next!;

        double denominator = n2.Value.Time - n1.Value.Time;
        double t = denominator > 0.0 ? (_clientTime - n1.Value.Time) / denominator : 1.0;

        t = Math.Clamp(t, 0.0, 1.0);

        double t2 = t * t;
        double t3 = t2 * t;

        return InterpolateCore(
            n0.Value.Contents,
            n1.Value.Contents,
            n2.Value.Contents,
            n3.Value.Contents,
            t, t2, t3
        );
    }

    protected virtual T PreprocessValue(T value) => value;

    protected abstract T InterpolateCore(T p0, T p1, T p2, T p3, double t, double t2, double t3);

    protected static double CatmullRom(double p0, double p1, double p2, double p3, double t, double t2, double t3)
    {
        return 0.5 * ((2.0 * p1) +
               (-p0 + p2) * t +
               (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
               (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3);
    }

    private protected record struct TimePoint(T Contents, double Time);
}
