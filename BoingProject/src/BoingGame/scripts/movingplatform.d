module scripts.movingplatform;

import scripts.script;
import Engine.component;
import Engine.gameobject;
import std.math;
import bindbc.sdl;
import physics;

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
        if ((mTransformRef.x == dest.x && goingTo) || (mTransformRef.x == src.x && !goingTo)) {
            // Snap to the destination to avoid floating point issues
            if (goingTo) {
                mTransformRef.SetPos(dest.x, dest.y);
            } else {
                mTransformRef.SetPos(src.x, src.y);
            }
            goingTo = !goingTo;
        }

    }
}
