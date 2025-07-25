module physics.solid;

import std.algorithm.searching;
import physics.actor;
import Engine.component;
import bindbc.sdl;
import std.math;

class Solid {
    float xRemainder = 0.0f;
    float yRemainder = 0.0f;
    TransformComponent transform;
    ColliderComponent collider;
    Actor[]* actors;

    this(TransformComponent transform, ColliderComponent collider) {
        this.transform = transform;
        this.collider = collider;
    }

    public void Move(float x, float y) {
        xRemainder += x;
        yRemainder += y;
        int moveX = cast(int) floor(xRemainder);
        int moveY = cast(int) floor(yRemainder);
        if (moveX != 0 || moveY != 0) {
            // Loop through every Actor in the Level, add it to
            // a list if actor.IsRiding(this) is true
            Actor[] riding = GetAllRidingActors();

            // Make this Solid non-collidable for Actors,
            // so that Actors moved by it do not get stuck on it
            collider.active = false;

            if (moveX != 0) {
                xRemainder -= moveX;
                transform.Translate(moveX, 0);
                if (moveX > 0) {
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {
                            // Push right
                            actor.MoveX(collider.rect.x + collider.rect.w - actor.collider.rect.x, &(actor.Squish));
                        } else if (riding.canFind(actor)) {
                            // Carry right
                            actor.MoveX(moveX, null);
                        }
                    }
                } else {
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {
                            // Push right
                            actor.MoveX(collider.rect.x - actor.collider.rect.x - actor.collider.rect.w, &(actor.Squish));
                        } else if (riding.canFind(actor)) {
                            // Carry right
                            actor.MoveX(moveX, null);
                        }
                    }
                }
            }

            // if (moveY != 0) {
            //     // Do y-axis movement
            //     …
            // }

            // Re-enable collisions for this Solid
            collider.active = true;
        }
    }

    private Actor[] GetAllRidingActors() {
        Actor[] ridingActors;
        foreach (Actor actor; *actors) {
            if (actor.IsRiding(this)) {
                ridingActors ~= actor;
            }
        }
        return ridingActors;
    }
}
