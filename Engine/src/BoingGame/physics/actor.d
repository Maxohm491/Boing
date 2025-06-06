module physics.actor;

import std.math;
import Engine.component;
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

    // Returns whether the actor is one pixel above a solid
    bool IsOnGround() {
        transform.y += 1;
        collider.rect.y += 1; // Adjust the collider too
        bool result = collider.CollidesWithSolid();

        // Undo the move
        transform.y -= 1;
        collider.rect.y -= 1;

        return result;
    }

    // [left, right, up, down]
    bool[4] SolidsAround() {
        bool[4] result = [false, false, false, false];

        transform.y += 1;
        collider.rect.y += 1; // Adjust the collider too
        if (collider.CollidesWithSolid())
            result[3] = true;

        transform.y -= 2;
        collider.rect.y -= 2;
        if (collider.CollidesWithSolid())
            result[2] = true;

        transform.y += 1;
        collider.rect.y += 1;
        transform.x += 1;
        collider.rect.x += 1;
        if (collider.CollidesWithSolid())
            result[1] = true;

        transform.x -= 2;
        collider.rect.x -= 2;
        if (collider.CollidesWithSolid())
            result[0] = true;

        // Undo the move
        transform.x += 1;
        collider.rect.x += 1;

        return result;
    }

    // [UL, UR, DL, DR]
    bool[4] SolidCornersAround() {
        bool[4] result = [false, false, false, false];

        transform.y += 1;
        collider.rect.y += 1;
        transform.x += 1;
        collider.rect.x += 1;
        if (collider.CollidesWithSolid())
            result[3] = true;

        transform.y -= 2;
        collider.rect.y -= 2;
        if (collider.CollidesWithSolid())
            result[1] = true;

        transform.x -= 2;
        collider.rect.x -= 2;
        if (collider.CollidesWithSolid())
            result[0] = true;

        transform.y += 2;
        collider.rect.y += 2;
        if (collider.CollidesWithSolid())
            result[2] = true;

        // Undo the move
        transform.x += 1;
        collider.rect.x += 1;
        transform.y -= 1;
        collider.rect.y -= 1;

        return result;
    }
}
