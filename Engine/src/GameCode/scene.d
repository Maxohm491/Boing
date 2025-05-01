module GameCode.scene;

import GameCode.component;
import GameCode.tilemapcomponents;
import std.algorithm;
import GameCode.gameobject;
import GameCode.gameapplication;
import GameCode.scripts.player;
import constants;
import bindbc.sdl;
import std.json;
import std.format;
import std.conv;
import std.file;
import std.random;
import std.math;

import std.stdio;

/// Stores simple key-value integer game state.
struct GameState
{
    /// Maps a string key to an integer value.
    int[string] mIntMap;
}

/// Represents a scene containing game objects, a tilemap, and associated state.
class Scene
{
<<<<<<< HEAD
    GameObject[] gameObjects; // Don't use a scene tree bc that's complicated
    GameObject player;
=======
    /// List of all active GameObjects in the scene.
    GameObject[] gameObjects;
    /// Global state information for the scene.
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
    GameState mGameState;
    /// Reference to the SDL_Renderer for drawing operations.
    SDL_Renderer* mRendererRef;
    SDL_Point mSpawnPoint;
    GameObject tilemap;
    void delegate() mOnComplete;

    // Create scene /// Constructs a Scene and loads it from a JSON file.
    ///
    /// Params:
    ///     r = The SDL_Renderer used for rendering.
    ///     sceneIndex = Index used to select which scene JSON to load.
    this(SDL_Renderer* r, int sceneIndex, void delegate() onComplete)
    {
        mRendererRef = r;
        mOnComplete = onComplete;
        LoadSceneFromJson("./assets/scenes/scene" ~ to!string(sceneIndex) ~ ".json");
    }

    /// Creates and returns a player GameObject at a specified location.
    ///
    /// Params:
    ///     location = The initial SDL_Point position for the player.
    ///
    /// Returns:
    ///     A fully initialized player GameObject.
    GameObject MakePlayer(SDL_Point location)
    {
        player = null;
        player = MakeSprite("player");
        TransformComponent transform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) player.GetComponent(
            ComponentType.TEXTURE);
        SpriteComponent sprite = cast(SpriteComponent) player.GetComponent(ComponentType.SPRITE);
        ColliderComponent collider = cast(ColliderComponent) player.GetComponent(
            ComponentType.COLLIDER);

        transform.x = mSpawnPoint.x;
        transform.y = mSpawnPoint.y;

        texture.LoadTexture("./assets/images/character.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/character.json");

        sprite.mRendererRef = mRendererRef;
        sprite.mRect.w = TILE_SIZE;
        sprite.mRect.h = TILE_SIZE;

        collider.rect.w = TILE_SIZE;
        collider.rect.h = (TILE_SIZE * 5) / 8; 
        collider.offset.x = 0;
        collider.offset.y = (TILE_SIZE * 3) / 8;

        auto input = new InputComponent(player);
        player.AddComponent!(ComponentType.INPUT)(input);

        auto playScript = new Player(player);
        playScript.mTilemap = cast(TilemapCollider) tilemap.GetComponent(ComponentType.TILEMAP_COLLIDER);
        player.AddComponent!(ComponentType.SCRIPT)(playScript);

        return player;
    }

<<<<<<< HEAD
    GameObject MakeApple(SDL_Point location)
    {
        GameObject apple = MakeCollider("apple");
        TransformComponent transform = cast(TransformComponent) apple.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) apple.GetComponent(
            ComponentType.COLLIDER);

        transform.x = location.x;
        transform.y = location.y;

        collider.rect.w = TILE_SIZE;
        collider.rect.h = TILE_SIZE; // be generous

        return apple;
    }

    GameObject MakeSpike(SDL_Point location, bool up)
    {
        GameObject spike = MakeCollider("spike");
        TransformComponent transform = cast(TransformComponent) spike.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) spike.GetComponent(
            ComponentType.COLLIDER);

        transform.x = location.x;
        transform.y = location.y;

        collider.rect.w = TILE_SIZE;
        collider.rect.h = TILE_SIZE / 2; // be generous
        if(up) 
        {
            collider.offset.y = TILE_SIZE / 2;
        }

        return spike;
    }

    /// Spawns player, end, spikes, arrows, and walls
=======
    /// Loads a scene from a JSON file, creating GameObjects based on tile definitions.
    ///
    /// Params:
    ///     filename = Path to the scene JSON file.
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
    void LoadSceneFromJson(string filename)
    {

        auto textIn = readText(filename);
        auto root = parseJSON(textIn);
        auto obj = root.object;

        int[GRID_Y][GRID_X] buf;

        size_t y = 0;
        foreach (rowVal; obj["tiles"].array)
        {
            size_t x = 0;
            foreach (cell; rowVal.array)
            {
                int value = cell.get!int;
                if (value == 19) // Start tile
                {
                    mSpawnPoint = SDL_Point(cast(int) (TILE_SIZE * y), cast(int) (TILE_SIZE * x));
                    value = 16;
                } 
                else if (value == 20) // End tile
                {
<<<<<<< HEAD
                    value = 28; // apple
                    AddGameObject(MakeApple(SDL_Point(cast(int) (TILE_SIZE * y), cast(int) (TILE_SIZE * x))));
=======
                    value = 28; 
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
                }
                else if (value == 17) // up spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int) (TILE_SIZE * y), cast(int) (TILE_SIZE * x)), true));
                else if (value == 23) // down spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int) (TILE_SIZE * y), cast(int) (TILE_SIZE * x)), false));

                buf[y][x++] = value;
            }
            y++;
        }

<<<<<<< HEAD
        tilemap = GameObjectFactory!(ComponentType.TEXTURE,
            ComponentType.TILEMAP_COLLIDER, ComponentType.TILEMAP_SPRITE)("tilemap");

=======
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
        TextureComponent texture = cast(TextureComponent) tilemap.GetComponent(
            ComponentType.TEXTURE);
        TilemapSprite sprite = cast(TilemapSprite) tilemap.GetComponent(
            ComponentType.TILEMAP_SPRITE);
        TilemapCollider collider = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);

        texture.LoadTexture("./assets/images/tilemap.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/tilemap.json");

        sprite.mRendererRef = mRendererRef;
        sprite.tiles = buf;
        collider.tiles = buf;

<<<<<<< HEAD
        AddGameObject(MakePlayer());
=======
        AddGameObject(tilemap);
        AddGameObject(player);
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
    }

    /// Passes an SDL input event to all GameObjects in the scene.
    ///
    /// Params:
    ///     e = The SDL_Event to process.
    void Input(SDL_Event e)
    {
        foreach (obj; gameObjects)
        {
            obj.Input(e);
        }
    }

    /// Updates all GameObjects and performs collision detection and cleanup.
    void Update()
    {
        // Update Transforms
        foreach (obj; gameObjects)
        {
            obj.Update();
        }

<<<<<<< HEAD
        // Update collisions of player
        auto collider = cast(ColliderComponent) player.GetComponent(
=======
        // Update Collisions
        foreach (ref objComponent; gameObjects[1 .. $])
        {
            auto collider = cast(ColliderComponent) objComponent.GetComponent(
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
                ComponentType.COLLIDER);

        if (collider !is null)
            collider.CheckCollisions(gameObjects);

        // foreach (ref objComponent; gameObjects[1 .. $])
        // {
        //     auto collider = cast(ColliderComponent) objComponent.GetComponent(
        //         ComponentType.COLLIDER);

        //     if (collider !is null)
        //     {
        //         collider.CheckCollisions(gameObjects[1 .. $]);
        //     }
        // }

<<<<<<< HEAD
        // Check deaths
        bool respawn = false;
=======
        // Remove dead GameObjects
>>>>>>> a54fd3c4c84af0386bfe1ce011aa219845d671ca
        for (auto i = gameObjects.length; i > 0; i -= 1)
        {
            if (!gameObjects[i - 1].alive)
            {
                // if(gameObjects[i - 1].GetName() == "player")
                //     AddGameObject(MakePlayer()); // respawn player
                // if(gameObjects[i - 1].GetName() == "apple")
                //     mOnComplete();
                respawn = respawn || gameObjects[i - 1].GetName() == "player";
                gameObjects = gameObjects.remove(i - 1);
            }
        }

        if(respawn) 
        {
            writeln("spawing");
            AddGameObject(MakePlayer());
        }
    }

    /// Renders all GameObjects in the scene.
    void Render()
    {
        foreach (obj; gameObjects)
        {
            obj.Render();
        }
    }

    /// Adds a GameObject to the scene.
    ///
    /// Params:
    ///     go = The GameObject to add.
    void AddGameObject(GameObject go)
    {
        gameObjects ~= go;
    }
}
