module scripts.movingplatform;

import scripts.script;
import Engine.component;
import Engine.gameobject;
import std.math;
import bindbc.sdl;
import physics;
import std.stdio;

class MovingPlatform : ScriptComponent {
    float speed;
    float xDir, yDir;
    bool goingTo = true;
    SDL_Point src, dest;
    TransformComponent mTransformRef;
    Solid solid;

    this(GameObject owner, float time, SDL_Point src, SDL_Point dest) {
        this.mOwner = owner;
        this.speed = 1 / time;
        this.src = src;
        this.dest = dest;
        mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);

        xDir = dest.x - src.x;
        yDir = dest.y - src.y;

        mTransformRef.SetPos(src.x, src.y);

        solid = new Solid(mTransformRef, cast(ColliderComponent) mOwner.GetComponent(
                ComponentType.COLLIDER));
    }

    override void Update() {
        // Move the platform
        int dir = goingTo ? 1 : -1;
        float x = speed * dir * xDir;
        float y = speed * dir * yDir;

        solid.Move(x, y);

        // Check if the platform has moved far enough to reverse direction
        if (
            (goingTo && 
                (sgn(mTransformRef.x - dest.x) == sgn(dest.x - src.x)) && 
                (sgn(mTransformRef.y - dest.y) == sgn(dest.y - src.y))) || 
            (!goingTo && 
                (sgn(mTransformRef.x - src.x) == sgn(src.x - dest.x)) && 
                (sgn(mTransformRef.y - src.y) == sgn(src.y - dest.y)))) {
            // Snap to the destination to avoid rounding issues
            if (goingTo) {
                solid.Move(dest.x - mTransformRef.x, dest.y - mTransformRef.y);
            } else {
                solid.Move(src.x - mTransformRef.x, src.y - mTransformRef.y);
            }
            goingTo = !goingTo;
        }

    }
}
