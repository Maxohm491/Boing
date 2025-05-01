module GameCode.scripts.player;

import GameCode.component;
import GameCode.tilemapcomponents;
import GameCode.gameobject;
import GameCode.scripts.script;
import constants;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.algorithm;

class Player : ScriptComponent
{
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    SpriteComponent mSpriteRef;
    InputComponent mInputRef;
    TilemapCollider mTilemap;
    float runSpeed = 7;
    float minJumpSpeed = 7;
    float maxJumpSpeed = 17; // To make a nice fun jump set max when they hit space ad min when they let go
    float maxVertSpeed = 22;
    float gravity = 0.55;
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right
    bool wasJumpPressed = false;
    immutable float pixelWidth = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f;
    bool grounded = false;

    this(GameObject owner)
    {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        mInputRef = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);

        mTilemap = cast(TilemapCollider) GameObject.GetGameObject("tilemap")
            .GetComponent(ComponentType.TILEMAP_COLLIDER);

        mSpriteRef.SetAnimation("idle");
    }

    override void Update()
    {
        vel_x = runSpeed * mInputRef.GetDir();
        if (grounded)
        {
            if (grounded && mInputRef.upPressed)
            {
                vel_y = maxJumpSpeed;
                grounded = false;
            }
        }

        if (!mInputRef.upPressed // button now up
            && wasJumpPressed // but was down last frame
            && vel_y > minJumpSpeed) // and still going upward
            {
            vel_y = minJumpSpeed;
        }
        wasJumpPressed = mInputRef.upPressed; // store for next frame

        vel_y -= gravity;
        vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed);
        MoveAndHandleWallCollisions();
    }

    void MoveAndHandleWallCollisions()
    {
        // Calculate new pos, decide if it would go into a new rect, and adjust accordingly
        SDL_Rect newColliderPos = SDL_Rect(cast(int)(round(
                (mTransformRef.x + vel_x) / pixelWidth) * pixelWidth) + mColliderRef.offset.x,
            cast(int)(round((mTransformRef.y - vel_y) / pixelWidth) * pixelWidth) + mColliderRef.offset.y, mColliderRef
                .rect.w, mColliderRef.rect.h);

        auto colls = mTilemap.GetWallCollisions(&newColliderPos);
        if (colls.length == 0) // 0 — clear, just move
        {
            mTransformRef.Translate(vel_x, -vel_y);
            grounded = false;
            return;
        }

        /* 2. Fuse 2 colliding tiles into one bounding box ----------------- */
        if (colls.length <= 2)
        {
            SDL_Rect bb = colls[0];
            foreach (c; colls[1 .. $])
            {
                int x1 = min(bb.x, c.x);
                int y1 = min(bb.y, c.y);
                int x2 = max(bb.x + bb.w, c.x + c.w);
                int y2 = max(bb.y + bb.h, c.y + c.h);
                bb = SDL_Rect(x1, y1, x2 - x1, y2 - y1);
            }

            SDL_Rect overlap;
            SDL_IntersectRect(&newColliderPos, &bb, &overlap);

            if (overlap.w < overlap.h) // wall
            {
                if (overlap.x > newColliderPos.x) // right wall
                    mTransformRef.x = bb.x - TILE_SIZE;
                else //left wall
                    mTransformRef.x = bb.x + TILE_SIZE;
                vel_x = 0;
            }
            else // floor/ceiling
            {
                if (overlap.y == newColliderPos.y) // ceiling
                    mTransformRef.y = bb.y + TILE_SIZE - mColliderRef.offset.y;
                else // floor
                {
                    mTransformRef.y = bb.y - TILE_SIZE;
                    grounded = true;
                }
                vel_y = 0;
            }
        }

        else // corner
        {
            // this is jank but make one big box and do math
            SDL_Rect bb = colls[0];
            foreach (c; colls[1 .. $])
            {
                int x1 = min(bb.x, c.x);
                int y1 = min(bb.y, c.y);
                int x2 = max(bb.x + bb.w, c.x + c.w);
                int y2 = max(bb.y + bb.h, c.y + c.h);
                bb = SDL_Rect(x1, y1, x2 - x1, y2 - y1);
            }

            // SDL_Rect overlap;
            // SDL_IntersectRect(&newColliderPos, &bb, &overlap);
            if (vel_x < 0) // left wall
                mTransformRef.x = bb.x + TILE_SIZE;
            else // right wall
                mTransformRef.x = bb.x;

            if (vel_y > 0) // ceiling
                mTransformRef.y = bb.y + TILE_SIZE - mColliderRef.offset.y;
            else // floor
            {
                mTransformRef.y = bb.y;
                grounded = true;
            }

            vel_x = 0;
            vel_y = 0;
        }

        mTransformRef.Translate(vel_x, -vel_y);
        if (vel_y != 0)
        {
            grounded = false;
        }
    }
}
