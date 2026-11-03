package com.justy41.handdrawn.systems;

import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.justy41.handdrawn.components.RigidBody;
import com.justy41.handdrawn.components.TransformComponent;
import com.justy41.handdrawn.core.Ecs;

import java.util.Objects;

public class UpdateSystems {
    public static void updatePosition(Ecs ecs, float deltaTime) {
        // Syncing box collider positions with the actual transform positions
        ecs.boxColliders.forEach((entity, collider) -> {
            if(collider != null && ecs.transforms.get(entity) != null) {
                TransformComponent transform = ecs.transforms.get(entity);

                collider.rect.x = transform.position.x+collider.relativePosition.x;
                collider.rect.y = transform.position.y+collider.relativePosition.y;
            }
        });

        // Resolving collisions between entities
        ecs.boxColliders.forEach((entity, collider) -> {
            if(collider != null && ecs.transforms.get(entity) != null && ecs.rigidbodies.get(entity) != null) {
                TransformComponent transform = ecs.transforms.get(entity);
                RigidBody rb = ecs.rigidbodies.get(entity);

                Vector2 swept_pos = new Vector2(transform.position);
                Rectangle swept_rect = new Rectangle(collider.rect);

                collider.touching.replace("right", false);
                collider.touching.replace("left", false);
                collider.touching.replace("up", false);
                collider.touching.replace("down", false);

                // RESOLUTION ON X AXIS
                swept_pos.x += rb.velocity.x * deltaTime;
                swept_rect.x = swept_pos.x+collider.relativePosition.x;
                ecs.boxColliders.forEach((e, c) -> {
                    if(c != null && ecs.transforms.get(e) != null && !Objects.equals(e, entity)) {
                        if(swept_rect.overlaps(c.rect) && !collider.isTrigger && !c.isTrigger) {
                            if(rb.velocity.x > 0) {
                                swept_rect.x = c.rect.x-swept_rect.width;
                                collider.touching.replace("right", true);
                            }
                            if(rb.velocity.x < 0) {
                                swept_rect.x = c.rect.x+c.rect.width;
                                collider.touching.replace("left", true);
                            }
                            rb.velocity.x = 0;
                        }

                        swept_pos.x = swept_rect.x-collider.relativePosition.x;
                        transform.position.x = swept_pos.x;
                        collider.rect = new Rectangle(swept_rect);
                    }
                });

                // RESOLUTION ON Y AXIS
                rb.velocity.y -= rb.gravity * deltaTime;
                swept_pos.y += rb.velocity.y * deltaTime;
                swept_rect.y = swept_pos.y+collider.relativePosition.y;
                ecs.boxColliders.forEach((e, c) -> {
                    if(c != null && ecs.transforms.get(e) != null && !Objects.equals(e, entity)) {
                        if(swept_rect.overlaps(c.rect) && !collider.isTrigger && !c.isTrigger) {
                            if(rb.velocity.y > 0) {
                                swept_rect.y = c.rect.y-swept_rect.height;
                                collider.touching.replace("up", true);
                            }
                            if(rb.velocity.y < 0) {
                                swept_rect.y = c.rect.y+c.rect.height;
                                collider.touching.replace("down", true);
                            }
                            rb.velocity.y = 0;
                        }

                        swept_pos.y = swept_rect.y-collider.relativePosition.y;
                        transform.position.y = swept_pos.y;
                        collider.rect = new Rectangle(swept_rect);
                    }
                });
            }
        });
    }
}
