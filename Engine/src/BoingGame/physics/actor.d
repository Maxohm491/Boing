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

    // 1 = left, 2 = right, 4 = up, 8 = down
    int SolidsAround() {
        int result = 0;

        transform.y += 1;
        collider.rect.y += 1; // Adjust the collider too
        if (collider.CollidesWithSolid())
            result += 8;

        transform.y -= 2;
        collider.rect.y -= 2;
        if (collider.CollidesWithSolid())
            result += 4;

        transform.y += 1;
        collider.rect.y += 1;
        transform.x += 1;
        collider.rect.x += 1;
        if (collider.CollidesWithSolid())
            result += 2;

        transform.x -= 2;
        collider.rect.x -= 2;
        if (collider.CollidesWithSolid())
            result += 1;

        // Undo the move
        transform.x += 1;
        collider.rect.x += 1;

        // If our corner is solid but nothing else, count walls differently
        // UL = -1, UR = -2, DL = -4, DR = -8
        if (result == 0) {
            transform.y += 1;
            collider.rect.y += 1;
            transform.x += 1;
            collider.rect.x += 1;
            if (collider.CollidesWithSolid())
                result += -8;

            transform.y -= 2;
            collider.rect.y -= 2;
            if (collider.CollidesWithSolid())
                result += -2;

            transform.x -= 2;
            collider.rect.x -= 2;
            if (collider.CollidesWithSolid())
                result += -1;

            transform.y += 2;
            collider.rect.y += 2;
            if (collider.CollidesWithSolid())
                result += -4;

            // Undo the move
            transform.x += 1;
            collider.rect.x += 1;
            transform.y -= 1;
            collider.rect.y -= 1;
        }

        return result;
    }
}
