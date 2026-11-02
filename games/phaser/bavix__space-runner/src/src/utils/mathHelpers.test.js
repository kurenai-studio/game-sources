import { describe, it, expect } from 'vitest';
import {
  getDistanceSq,
  getDistance,
  normalizeVector,
  normalizeVectorFromSq,
  isPointInCircleSq,
  clamp,
  lerp,
  smoothStep
} from './mathHelpers.js';

describe('mathHelpers', () => {
  describe('getDistanceSq', () => {
    it('should calculate squared distance correctly', () => {
      expect(getDistanceSq(0, 0, 3, 4)).toBe(25);
      expect(getDistanceSq(1, 1, 4, 5)).toBe(25);
      expect(getDistanceSq(0, 0, 0, 0)).toBe(0);
    });
  });

  describe('getDistance', () => {
    it('should calculate distance correctly', () => {
      expect(getDistance(0, 0, 3, 4)).toBe(5);
      expect(getDistance(0, 0, 0, 0)).toBe(0);
    });
  });

  describe('normalizeVector', () => {
    it('should normalize vector correctly', () => {
      const result = normalizeVector(3, 4, 5);
      expect(result.x).toBeCloseTo(0.6);
      expect(result.y).toBeCloseTo(0.8);
    });

    it('should return zero vector for zero distance', () => {
      const result = normalizeVector(0, 0, 0);
      expect(result.x).toBe(0);
      expect(result.y).toBe(0);
    });
  });

  describe('normalizeVectorFromSq', () => {
    it('should normalize vector from squared distance', () => {
      const result = normalizeVectorFromSq(3, 4, 25);
      expect(result.x).toBeCloseTo(0.6);
      expect(result.y).toBeCloseTo(0.8);
      expect(result.distance).toBeCloseTo(5);
    });

    it('should return zero vector for zero squared distance', () => {
      const result = normalizeVectorFromSq(0, 0, 0);
      expect(result.x).toBe(0);
      expect(result.y).toBe(0);
      expect(result.distance).toBe(0);
    });
  });

  describe('isPointInCircleSq', () => {
    it('should return true if point is inside circle', () => {
      expect(isPointInCircleSq(1, 1, 0, 0, 25)).toBe(true);
      expect(isPointInCircleSq(3, 4, 0, 0, 25)).toBe(true);
    });

    it('should return false if point is outside circle', () => {
      expect(isPointInCircleSq(10, 10, 0, 0, 25)).toBe(false);
    });

    it('should return true if point is on circle edge', () => {
      expect(isPointInCircleSq(5, 0, 0, 0, 25)).toBe(true);
    });
  });

  describe('clamp', () => {
    it('should clamp value to min', () => {
      expect(clamp(5, 10, 20)).toBe(10);
    });

    it('should clamp value to max', () => {
      expect(clamp(25, 10, 20)).toBe(20);
    });

    it('should return value if within range', () => {
      expect(clamp(15, 10, 20)).toBe(15);
    });
  });

  describe('lerp', () => {
    it('should interpolate correctly', () => {
      expect(lerp(0, 10, 0.5)).toBe(5);
      expect(lerp(0, 10, 0)).toBe(0);
      expect(lerp(0, 10, 1)).toBe(10);
    });
  });

  describe('smoothStep', () => {
    it('should return 0 for t=0', () => {
      expect(smoothStep(0)).toBe(0);
    });

    it('should return 1 for t=1', () => {
      expect(smoothStep(1)).toBe(1);
    });

    it('should return 0.5 for t=0.5', () => {
      expect(smoothStep(0.5)).toBe(0.5);
    });
  });
});

