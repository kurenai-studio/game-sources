package com.bossfight.boss;

import java.util.OptionalDouble;

final class PendingTelegraphs {
    private final PendingTelegraph[] telegraphs;
    private int size;

    PendingTelegraphs(int capacity) {
        telegraphs = new PendingTelegraph[capacity];
        for (int index = 0; index < capacity; index++) {
            telegraphs[index] = new PendingTelegraph();
        }
    }

    void clear() {
        size = 0;
    }

    void update(float delta) {
        for (int index = 0; index < size; index++) {
            telegraphs[index].remainingTime -= delta;
        }
    }

    void add(float position, float duration) {
        if (isFull()) {
            throw new IllegalStateException("Não há espaço para outro aviso pendente");
        }

        PendingTelegraph telegraph = telegraphs[size];
        telegraph.position = position;
        telegraph.remainingTime = duration;
        size++;
    }

    boolean isEmpty() {
        return size == 0;
    }

    boolean isFull() {
        return size == telegraphs.length;
    }

    OptionalDouble pollExpiredPosition() {
        for (int index = size - 1; index >= 0; index--) {
            if (telegraphs[index].remainingTime <= 0f) {
                return OptionalDouble.of(remove(index));
            }
        }
        return OptionalDouble.empty();
    }

    boolean hasPositionWithin(float position, float distance) {
        for (int index = 0; index < size; index++) {
            if (Math.abs(position - telegraphs[index].position) < distance) {
                return true;
            }
        }
        return false;
    }

    private float remove(int index) {
        PendingTelegraph expired = telegraphs[index];
        size--;
        telegraphs[index] = telegraphs[size];
        telegraphs[size] = expired;
        return expired.position;
    }

    private static final class PendingTelegraph {
        private float position;
        private float remainingTime;
    }
}
