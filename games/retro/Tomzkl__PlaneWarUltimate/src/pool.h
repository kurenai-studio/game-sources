#pragma once

namespace pwu {

template<typename T, int N>
struct Pool
{
    T items[N];

    void Init()
    {
        for (int i = 0; i < N; i++)
        {
            items[i].active = false;
        }
        acquireHint = 0;
    }

    // O(1) amortized via circular scan - each Acquire picks up where
    // the last one left off, avoiding repeated scans over dead slots.
    T* Acquire()
    {
        for (int count = 0; count < N; count++)
        {
            int i = (acquireHint + count) % N;
            if (!items[i].active)
            {
                items[i] = {};
                items[i].active = true;
                acquireHint = (i + 1) % N;
                return &items[i];
            }
        }
        return nullptr;
    }

    void Clear()
    {
        for (int i = 0; i < N; i++)
        {
            items[i].active = false;
        }
        acquireHint = 0;
    }

private:
    int acquireHint = 0;
};

} // namespace pwu
