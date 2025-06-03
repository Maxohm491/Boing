module scripts.shooter;

import scripts.script;
import Engine.gameobject;
import Engine.component;
import Engine.tilemapcomponents;
import constants;
import bindbc.sdl;
import constants;
import std.math;

class Shooter : ScriptComponent
{
    TransformComponent mTransformRef;
    SDL_Renderer* mRendererRef;
    void delegate(GameObject) spawnFunction;
    TilemapCollider mTilemap;
    immutable int cooldown = 60; // in frames
    int timeToArrow = 60;
    bool right;

    this(GameObject owner)
    {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
    }

    override void Update()
    {
        timeToArrow--;
        if(timeToArrow <= 0)
        {
            timeToArrow = cooldown;
            // spawnFunction(MakeArrow());
        }
    }


    // GameObject MakeArrow()
    // {
    //     GameObject obj = MakeSprite("arrow");
    //     auto transform = cast(TransformComponent) obj.GetComponent(ComponentType.TRANSFORM);
    //     auto texture = cast(TextureComponent) obj.GetComponent(ComponentType.TEXTURE);
    //     auto sprite = cast(SpriteComponent) obj.GetComponent(ComponentType.SPRITE);
    //     auto collider = cast(ColliderComponent) obj.GetComponent(ComponentType.COLLIDER);

    //     transform.Translate(mTransformRef.x, mTransformRef.y);
    //     texture.LoadTexture("assets/images/arrow.bmp", mRendererRef);

    //     sprite.mRendererRef = mRendererRef;
    //     sprite.mRect.w = TILE_SIZE;
    //     sprite.mRect.h = TILE_SIZE;
    //     sprite.flipped = !right;

    //     collider.rect.w = TILE_SIZE;
    //     collider.rect.h = TILE_SIZE / 4;
    //     collider.offset.y = TILE_SIZE / 2;

    //     auto script = new Arrow(obj);
    //     script.right = right;
    //     script.mTilemap = mTilemap;
    //     obj.AddComponent!(ComponentType.SCRIPT)(script);
    //     return obj;
    // }
}

// class Arrow : ScriptComponent
// {
//     TransformComponent mTransformRef;
//     ColliderComponent mColliderRef;
//     immutable float speed = 13;
//     bool right;
//     TilemapCollider mTilemap;


//     this(GameObject owner)
//     {
//         mOwner = owner;

//         mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
//         mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
//     }

//     override void Update()
//     {
//         SDL_Rect newColliderPos = SDL_Rect(cast(int)(round(
//                 (mTransformRef.x + (right ? speed : -speed)) / PIXEL_WIDTH) * PIXEL_WIDTH) + mColliderRef.offset.x,
//             cast(int)(round((mTransformRef.y) / PIXEL_WIDTH) * PIXEL_WIDTH) + mColliderRef.offset.y, mColliderRef
//                 .rect.w, mColliderRef.rect.h);
//         auto colls = mTilemap.GetWallCollisions(&newColliderPos);
//         if(colls.length > 0) mOwner.alive = false;

//         mTransformRef.Translate(right ? speed : -speed, 0);
//     }
// }