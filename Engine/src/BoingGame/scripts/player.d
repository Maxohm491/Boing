module scripts.player;

import Engine.component;
import Engine.tilemapcomponents;
import Engine.gameobject;
import scripts.script;
import constants;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.algorithm;
import physics;

class Player : ScriptComponent {
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    Actor actor;
    SpriteComponent mSpriteRef;
    InputComponent mInputRef;
    TilemapCollider mTilemap;
    float runSpeed = 0.7;
    float minJumpSpeed = 0.7;
    float maxJumpSpeed = 1.7; // To make a nice fun jump set max when they hit space and min when they let go
    float maxVertSpeed = 2.2;
    float gravity = 0.075;
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right
    bool wasJumpPressed = false;
    bool grounded = false;

    this(GameObject owner) {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        mInputRef = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);
        actor = new Actor(mTransformRef, mColliderRef);

        mSpriteRef.SetAnimation("idle");
    }

    override void Update() {
        HandleCollisions();
        HandleGroundedAndJump();

        // Horizontal movement and jump
        vel_x = runSpeed * mInputRef.GetDir();
        if (vel_x != 0)
            mSpriteRef.flipped = vel_x < 0;

        if (!grounded)
            vel_y -= gravity;

        vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed);
        writeln(vel_y);
        actor.MoveX(vel_x, &OnSideCollision);
        actor.MoveY(-vel_y, &OnVerticalCollision);
        // MoveAndHandleWallCollisions();
    }

    void HandleGroundedAndJump() {
        if (grounded) {
            if (grounded && mInputRef.upPressed) {
                vel_y = maxJumpSpeed;
                grounded = false;
            } else if (!actor.IsOnGround) {
                // if we walk off a ledge this triggers
                grounded = false;
            } else {
                vel_y = 0; // Reset vertical velocity when grounded
            }
        }

        if (!mInputRef.upPressed // button now up
            && wasJumpPressed // but was down last frame
            && vel_y > minJumpSpeed // and going upward
            && !grounded) // and not grounded 
            {
            vel_y = minJumpSpeed; // then cap jump
        }
        wasJumpPressed = mInputRef.upPressed; // store for next frame
    }

    void OnVerticalCollision() {
        if (vel_y > 0) // going up
        {
            vel_y = 0;
        } else // going down
        {
            vel_y = 0;
            grounded = true;
        }
    }

    void OnSideCollision() {
        vel_x = 0;
        writeln("COLLISION");
    }

    void HandleCollisions() {
        // auto collidedWith = mColliderRef.GetCollisions();
        // foreach(obj; collidedWith)
        // {
        //     if(obj == "spike" || obj == "arrow")
        //         mOwner.alive = false;
        //     else if(obj.startsWith("apple"))
        //     {
        //         GameObject.GetGameObject(obj).alive = false;
        //     }
        // }
    }

    // void MoveAndHandleWallCollisions()
    // {
    //     // Calculate new pos, decide if it would go into a new rect, and adjust accordingly
    //     SDL_Rect newColliderPos = SDL_Rect(cast(int)(round(
    //             (mTransformRef.x + vel_x) / PIXEL_WIDTH) * PIXEL_WIDTH) + mColliderRef.offset.x,
    //         cast(int)(round((mTransformRef.y - vel_y) / PIXEL_WIDTH) * PIXEL_WIDTH) + mColliderRef.offset.y, mColliderRef
    //             .rect.w, mColliderRef.rect.h);

    //     auto colls = mTilemap.GetWallCollisions(&newColliderPos);

    //     if (colls.length == 0) // 0 — clear, just move
    //     {
    //         mTransformRef.Translate(vel_x, -vel_y);
    //         grounded = false;
    //         return;
    //     }

    //     // If two straight
    //     if (colls.length == 1 || (colls.length == 2 && (colls[0].x == colls[1].x || colls[0].y == colls[1].y)))
    //     {
    //         SDL_Rect bb = colls[0];
    //         foreach (c; colls[1 .. $])
    //         {
    //             int x1 = min(bb.x, c.x);
    //             int y1 = min(bb.y, c.y);
    //             int x2 = max(bb.x + bb.w, c.x + c.w);
    //             int y2 = max(bb.y + bb.h, c.y + c.h);
    //             bb = SDL_Rect(x1, y1, x2 - x1, y2 - y1);
    //         }

    //         SDL_Rect overlap;
    //         SDL_IntersectRect(&newColliderPos, &bb, &overlap);

    //         if (overlap.w < overlap.h) // wall
    //         {
    //             if (overlap.x > newColliderPos.x) // right wall
    //                 mTransformRef.x = bb.x - TILE_SIZE;
    //             else //left wall
    //                 mTransformRef.x = bb.x + TILE_SIZE;
    //             vel_x = 0;
    //         }
    //         else // floor/ceiling
    //         {
    //             if (overlap.y == newColliderPos.y) // ceiling
    //                 mTransformRef.y = bb.y + TILE_SIZE - mColliderRef.offset.y;
    //             else // floor
    //             {
    //                 mTransformRef.y = bb.y - TILE_SIZE;
    //                 grounded = true;
    //             }
    //             vel_y = 0;
    //         }
    //     }

    //     else // corner
    //     {
    //         // this is jank but make one big box and do math
    //         SDL_Rect bb = colls[0];
    //         foreach (c; colls[1 .. $])
    //         {
    //             int x1 = min(bb.x, c.x);
    //             int y1 = min(bb.y, c.y);
    //             int x2 = max(bb.x + bb.w, c.x + c.w);
    //             int y2 = max(bb.y + bb.h, c.y + c.h);
    //             bb = SDL_Rect(x1, y1, x2 - x1, y2 - y1);
    //         }

    //         // SDL_Rect overlap;
    //         // SDL_IntersectRect(&newColliderPos, &bb, &overlap);
    //         if (vel_x < 0) // left wall
    //             mTransformRef.x = bb.x + TILE_SIZE;
    //         else // right wall
    //             mTransformRef.x = bb.x;

    //         if (vel_y > 0) // ceiling
    //             mTransformRef.y = bb.y + TILE_SIZE - mColliderRef.offset.y;
    //         else // floor
    //         {
    //             mTransformRef.y = bb.y;
    //             grounded = true;
    //         }

    //         vel_x = 0;
    //         vel_y = 0;
    //     }

    //     mTransformRef.Translate(vel_x, -vel_y);
    //     if (vel_y != 0)
    //     {
    //         grounded = false;
    //     }
    // }
}
