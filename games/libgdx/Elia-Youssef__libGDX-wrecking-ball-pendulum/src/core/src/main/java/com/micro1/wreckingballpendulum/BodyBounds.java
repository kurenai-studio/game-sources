package com.micro1.wreckingballpendulum;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.CircleShape;
import com.badlogic.gdx.physics.box2d.PolygonShape;
import com.badlogic.gdx.physics.box2d.Shape;

/** Geometry helpers for checking full-body screen exit conditions. */
final class BodyBounds {

    private BodyBounds() {
    }

    static boolean isFullyOffScreen(Body body, Vector2 outMin, Vector2 outMax) {
        computeWorldAabb(body, outMin, outMax);
        return outMax.x < 0f || outMin.x > WorldConstants.SCREEN_WIDTH_M
            || outMax.y < 0f || outMin.y > WorldConstants.SCREEN_HEIGHT_M;
    }

    private static void computeWorldAabb(Body body, Vector2 outMin, Vector2 outMax) {
        Shape shape = body.getFixtureList().first().getShape();
        if (shape.getType() == Shape.Type.Circle) {
            computeCircleAabb(body, (CircleShape) shape, outMin, outMax);
        } else {
            computePolygonAabb(body, (PolygonShape) shape, outMin, outMax);
        }
    }

    private static void computeCircleAabb(Body body, CircleShape circle, Vector2 outMin, Vector2 outMax) {
        Vector2 center = body.getWorldPoint(circle.getPosition());
        float radius = circle.getRadius();
        outMin.set(center.x - radius, center.y - radius);
        outMax.set(center.x + radius, center.y + radius);
    }

    private static void computePolygonAabb(Body body, PolygonShape polygon, Vector2 outMin, Vector2 outMax) {
        Vector2 local = new Vector2();
        polygon.getVertex(0, local);
        Vector2 firstWorld = body.getWorldPoint(local);
        outMin.set(firstWorld);
        outMax.set(firstWorld);

        for (int i = 1; i < polygon.getVertexCount(); i++) {
            polygon.getVertex(i, local);
            Vector2 worldPoint = body.getWorldPoint(local);
            outMin.x = Math.min(outMin.x, worldPoint.x);
            outMin.y = Math.min(outMin.y, worldPoint.y);
            outMax.x = Math.max(outMax.x, worldPoint.x);
            outMax.y = Math.max(outMax.y, worldPoint.y);
        }
    }
}
