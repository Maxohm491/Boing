module physics.solid;

import std.algorithm.searching;
import physics.actor;
import Engine.component;
import bindbc.sdl;
import std.math;
import std.stdio;

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
                collider.rect.x += moveX; // Adjust the collider too

                if (moveX > 0) {
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {

                            // Push right
                            actor.MoveX(collider.rect.x + collider.rect.w - actor.collider.rect.x, &(
                                    actor.Squish));
                        } else if (riding.canFind(actor)) {

                            // Carry right
                            actor.MoveX(moveX, null);
                        }
                    }
                } else if (moveX < 0) {
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {
                            // Push left
                            actor.MoveX(collider.rect.x - actor.collider.rect.x - actor.collider.rect.w, &(
                                    actor.Squish));
                        } else if (riding.canFind(actor)) {
                            // Carry left
                            actor.MoveX(moveX, null);
                        }
                    }
                }
            }

            if (moveY != 0) {
                yRemainder -= moveY;
                transform.Translate(0, moveY);
                collider.rect.y += moveY; // Adjust the collider too

                if (moveY > 0) {
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {

                            // Push down
                            actor.MoveY(collider.rect.y + collider.rect.h - actor.collider.rect.y, &(
                                    actor.Squish));
                        } else if (riding.canFind(actor)) {

                            // Carry down
                            actor.MoveY(moveY, null);
                        }
                    }
                } else if (moveY < 0){
                    foreach (Actor actor; *actors) {
                        if (actor.collider.overlaps(collider)) {
                            // Push up
                            actor.MoveY(collider.rect.y - actor.collider.rect.y - actor.collider.rect.h, &(
                                    actor.Squish));
                        } else if (riding.canFind(actor)) {
                            // Carry up
                            actor.MoveY(moveY, null);
                        }
                    }
                }
            }

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
