module GameCode.scene;

import GameCode.component;
import std.algorithm;
import GameCode.gameobject;
import GameCode.gameapplication;
import constants;
import bindbc.sdl;
import std.format;
import std.conv;
import std.random;
import std.math;

import std.stdio;

struct GameState
{
    int[string] mIntMap;
}

class Scene
{
    GameObject[] gameObjects; // Don't use a scene tree bc that's complicated
    GameState mGameState;
    SDL_Renderer* mRendererRef;
    bool mActive = true;

    // Create scene 
    this(SDL_Renderer* r)
    {
        mRendererRef = r;
        AddGameObject(MakePlayer());
    }

    GameObject MakePlayer() {
        GameObject player = MakeSprite("player");
        TransformComponent transform = cast(TransformComponent) player.GetComponent(ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) player.GetComponent(ComponentType.TEXTURE);
        SpriteComponent sprite = cast(SpriteComponent) player.GetComponent(ComponentType.SPRITE);
        ColliderComponent collider = cast(ColliderComponent) player.GetComponent(ComponentType.COLLIDER);

        // // move to start
        transform.x = 0;
        transform.y = 0;

        texture.LoadTexture("./assets/images/character.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/character.json");

        sprite.mRendererRef = mRendererRef;
        sprite.mRect.x = cast(int) transform.x;
        sprite.mRect.y = cast(int) transform.y;
        sprite.mRect.w = TILE_SIZE;
        sprite.mRect.h = TILE_SIZE;

        collider.mRect.x = cast(int) transform.x;
        collider.mRect.y = cast(int) transform.y;
        collider.mRect.w = TILE_SIZE;
        collider.mRect.h = (TILE_SIZE * 5) / 8; // be generous

        auto input = new InputComponent(player);
        player.AddComponent!(ComponentType.INPUT)(input);

        return player;
    }

    void LoadSceneFromJson(string filename)
    {
    }

    void Input(SDL_Event e)
    {
        foreach (obj; gameObjects)
        {
            obj.Input(e);
        }
    }

    void Update()
    {
        // Update Transforms
        foreach (obj; gameObjects)
        {
            obj.Update();
        }

        // Update Collisios
        foreach (ref objComponent; gameObjects[1 .. $])
        {
            auto collider = cast(ColliderComponent) objComponent.GetComponent(
                ComponentType.COLLIDER);

            if (collider !is null)
            {
                collider.CheckCollisions(gameObjects[1 .. $]);
            }
        }

        // Check deaths
        for (auto i = gameObjects.length; i > 0; i -= 1)
        {
            if (!gameObjects[i - 1].alive)
                gameObjects = gameObjects.remove(i - 1);
        }
    }

    void Render()
    {
        foreach (obj; gameObjects)
        {
            obj.Render();
        }
    }

    void AddGameObject(GameObject go)
    {
        gameObjects ~= go;
    }
}
