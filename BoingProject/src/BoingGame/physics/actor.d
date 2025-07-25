module physics.actor;

import std.math;
import Engine.component;
import physics.solid;
import bindbc.sdl;
import std.conv;
import std.stdio;

class Actor {
    float xRemainder = 0.0f;
    float yRemainder = 0.0f;
    TransformComponent transform;
    ColliderComponent collider;

    this(TransformComponent transform, ColliderComponent collider) {
        this.transform = transform;
        this.collider = collider;
    }

    public bool IsRiding(Solid solid) {
        assert(0, "IsRiding not implemented");
    }

    public void Squish() {
        assert(0, "Squish not implemented");
    }

    void MoveX(float amount, void delegate() onCollide) {
        xRemainder += amount;
        int move = cast(int) floor(xRemainder);
        if (move != 0) {

            xRemainder -= move;
            int sign = sgn(move);
            while (move != 0) {

                transform.x += sign;
                collider.rect.x += sign; // Adjust the collider  too
                if (collider.CollidesWithSolid()) {
                    // Hit a solid!
                    // Undo the move
                    transform.x -= sign;
                    collider.rect.x -= sign;
                    xRemainder = 0.0f;

                    if (onCollide != null)
                        onCollide();
                    break;
                }
                move -= sign;
            }
        }
    }

    void MoveY(float amount, void delegate() onCollide) {
        yRemainder += amount;
        int move = cast(int) floor(yRemainder);
        if (move != 0) {
            yRemainder -= move;
            int sign = sgn(move);
            while (move != 0) {
                transform.y += sign;
                collider.rect.y += sign; // Adjust the collider  too
                if (collider.CollidesWithSolid()) {
                    // Hit a solid!
                    // Undo the move
                    transform.y -= sign;
                    collider.rect.y -= sign;
                    yRemainder = 0.0f;

                    if (onCollide != null)
                        onCollide();

                    break;
                }
                move -= sign;
            }
        }
    }
}
