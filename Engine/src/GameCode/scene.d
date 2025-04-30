module GameCode.scene;

import GameCode.component;
import std.algorithm;
import GameCode.gameobject;
import GameCode.gameapplication;
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
        foreach (ref objComponent; gameObjects)
        {
            auto transform = cast(TransformComponent) objComponent.GetComponent(
                ComponentType.TRANSFORM);
        }

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
