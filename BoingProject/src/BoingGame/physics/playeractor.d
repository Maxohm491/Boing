module physics.playeractor;

import physics.actor;
import physics.solid;
import Engine.component;
import std.stdio;
import bindbc.sdl;

class PlayerActor : Actor {
    void delegate() Squished; // Delegate for squish behavior

    // Player-specific actor behavior
    this(TransformComponent transform, ColliderComponent collider) {
        super(transform, collider);
    }

    override bool IsRiding(Solid solid) {
        SDL_Rect solidRect = solid.collider.rect;
        SDL_Rect intersection;

        // Check directly below
        collider.rect.y += 1;
        if (SDL_IntersectRect(&collider.rect, &solidRect, &intersection) != 0) {
            collider.rect.y -= 1;
            return true;
        }
        collider.rect.y -= 1;

        // Check directly to the right
        collider.rect.x += 1;
        if (SDL_IntersectRect(&collider.rect, &solidRect, &intersection) != 0) {
            collider.rect.x -= 1;
            return true;
        }
        collider.rect.x -= 1;

        // Check directly to the left
        collider.rect.x -= 1;
        if (SDL_IntersectRect(&collider.rect, &solidRect, &intersection) != 0) {
            collider.rect.x += 1;
            return true;
        }
        collider.rect.x += 1;

        return false;
    }

    override void Squish() {
        assert(Squished !is null, "Squished delegate is not set");
        Squished();
    }

    // Returns whether the plaer is one pixel above a solid
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
