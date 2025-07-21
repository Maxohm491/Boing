module Engine.scene;

import Engine.component;
import Engine.tilemapcomponents;
import std.algorithm;
import Engine.gameobject;
import Engine.gameapplication;
import scripts;
import constants;
import bindbc.sdl;
import std.json;
import std.format;
import std.conv;
import std.file;
import std.random;
import std.math;
import linear;

import std.stdio;

/// Stores simple key-value integer game state.
struct GameState {
    /// Maps a string key to an integer value.
    int[string] mIntMap;
}

class Camera {
    SDL_Point pos;
    alias pos this;

    void PositionCamera(int x, int y) {
        pos.x = x;
        pos.y = y;
    }
}

/// Represents a scene containing game objects, a tilemap, and associated state.
class Scene {
    GameObject[] gameObjects; // Don't use a scene tree bc that's complicated
    ColliderComponent[] solids; // For collision detection
    GameObject player;
    GameState mGameState;
    Camera camera;

    int freezeFrames = 0; // freeze the whole game for this many frames

    SDL_Renderer* mRendererRef;
    SDL_Point mSpawnPoint;
    GameObject tilemap;
    void delegate() mOnComplete;

    this(SDL_Renderer* r, int sceneIndex, void delegate() onComplete) {
        mRendererRef = r;
        mOnComplete = onComplete;
        LoadSceneFromJson("./assets/scenes/scene" ~ to!string(sceneIndex) ~ ".json");
    }

    GameObject MakePlayer() {
        player = null;
        player = MakeSprite("player");
        TransformComponent transform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) player.GetComponent(
            ComponentType.TEXTURE);
        SpriteComponent sprite = cast(SpriteComponent) player.GetComponent(ComponentType.SPRITE);
        ColliderComponent collider = cast(ColliderComponent) player.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(mSpawnPoint.x, mSpawnPoint.y);

        texture.LoadTexture("./assets/images/character.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/character.json");


        sprite.mRendererRef = mRendererRef;

        collider.rect.w = PIXELS_PER_TILE;
        collider.rect.h = (PIXELS_PER_TILE * 5) / 8;
        collider.offset.x = 0;
        collider.offset.y = (PIXELS_PER_TILE * 3) / 8;
        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        auto input = new InputComponent(player);
        player.AddComponent!(ComponentType.INPUT)(input);

        auto playScript = new JumpPlayer(player);
        // playScript.mScene = this;
        playScript.mTilemap = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);
        player.AddComponent!(ComponentType.SCRIPT)(playScript);

        return player;
    }

    GameObject MakeApple(SDL_Point location) {
        GameObject apple = MakeCollider("apple" ~ to!string(GameObject.sGameObjectCount + 1));
        TransformComponent transform = cast(TransformComponent) apple.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) apple.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(location.x, location.y);

        collider.rect.w = PIXELS_PER_TILE;
        collider.rect.h = PIXELS_PER_TILE; // be generous
        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        return apple;
    }

    GameObject MakeSpike(SDL_Point location, bool up) {
        GameObject spike = MakeCollider("spike");
        TransformComponent transform = cast(TransformComponent) spike.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) spike.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(location.x, location.y);

        collider.rect.w = PIXELS_PER_TILE;
        collider.rect.h = PIXELS_PER_TILE / 2; // be generous
        if (up) {
            collider.offset.y = PIXELS_PER_TILE / 2;
        }
        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        return spike;
    }

    GameObject MakeShooter(SDL_Point location, bool right) {
        GameObject shooter = MakeTransform("shooter");
        TransformComponent transform = cast(TransformComponent) shooter.GetComponent(
            ComponentType.TRANSFORM);

        transform.SetPos(location.x, location.y);

        Shooter script = new Shooter(shooter);
        script.mTilemap = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);
        script.right = right;
        script.mRendererRef = mRendererRef;
        script.spawnFunction = &AddGameObject;
        shooter.AddComponent!(ComponentType.SCRIPT)(script);

        return shooter;
    }

    /// Loads a scene from a JSON file, creating GameObjects based on tile definitions.
    ///
    /// Params:
    ///     filename = Path to the scene JSON file.
    void LoadSceneFromJson(string filename) {
        camera = new Camera();
        camera.PositionCamera(0, 0);

        tilemap = GameObjectFactory!(ComponentType.TRANSFORM, ComponentType.TEXTURE,
            ComponentType.TILEMAP_COLLIDER, ComponentType.TILEMAP_SPRITE)("tilemap");

        auto textIn = readText(filename);
        auto root = parseJSON(textIn);
        auto obj = root.object;

        int[][] buf;

        auto tilesArray = obj["tiles"].array;
        buf.length = tilesArray.length;
        foreach (i, ref row; buf)
            row.length = tilesArray[i].array.length;

        size_t y = 0;
        foreach (rowVal; tilesArray) {
            size_t x = 0;
            foreach (cell; rowVal.array) {
                int value = cell.get!int;
                if (value == 19) // Start tile
                {
                    mSpawnPoint = SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(PIXELS_PER_TILE * x));
                    value = 16;
                } else if (value == 20) // End tile
                {
                    value = 28; // apple
                    AddGameObject(MakeApple(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x))));
                } else if (value == 17) // up spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), true));
                else if (value == 23) // down spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), false));
                else if (value == 18) // left shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), false));
                else if (value == 26) // right shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), true));
                buf[y][x++] = value;
            }
            y++;
        }

        TransformComponent transform = cast(TransformComponent) tilemap.GetComponent(
            ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) tilemap.GetComponent(
            ComponentType.TEXTURE);
        TilemapSprite sprite = cast(TilemapSprite) tilemap.GetComponent(
            ComponentType.TILEMAP_SPRITE);
        TilemapCollider collider = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);

        transform.SetPos(0, 0); // Always 0, 0 but needs to be here for camera purposes

        texture.LoadTexture("./assets/images/tilemap.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/tilemap.json");

        sprite.mRendererRef = mRendererRef;
        sprite.LoadTiles(buf);
        collider.LoadTiles(buf);

        AddGameObject(tilemap);
        AddGameObject(MakePlayer());
    }

    void Input(SDL_Event e) {
        foreach (obj; gameObjects) {
            obj.Input(e);
        }
    }

    void Update() {
        if (freezeFrames > 0) {
            freezeFrames -= 1;
            return; 
        }

        foreach (obj; gameObjects) {
            obj.Update();
        }

        auto collider = cast(ColliderComponent) player.GetComponent(
            ComponentType.COLLIDER);

        if (collider !is null)
            collider.CheckCollisions(gameObjects);

        // Check deaths
        for (auto i = gameObjects.length; i > 0; i -= 1) {
            if (!gameObjects[i - 1].alive) {
                if (gameObjects[i - 1].GetName() == "player")
                    AddGameObject(MakePlayer()); // respawn player
                if (gameObjects[i - 1].GetName().startsWith("apple"))
                    mOnComplete();
                gameObjects = gameObjects.remove(i - 1);
            }
        }

    }

    void Render() {
        auto playerTransform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);
        // camera.PositionCamera(-xy.x + (SCREEN_X / 2) - TILE_SIZE, -xy.y + (SCREEN_Y / 2) - TILE_SIZE); // center on player

        // Set each objects local pos based on camera
        foreach (obj; gameObjects) {
            auto transform = cast(TransformComponent) obj.GetComponent(
                ComponentType.TRANSFORM);
            if (transform !is null) {
                transform.UpdateScreenPos(camera.pos);
            }
        }
        foreach (obj; gameObjects) {
            obj.Render();
        }
    }

    void AddGameObject(GameObject go) {
        gameObjects ~= go;
    }

    void SetFreezeFrames(int frames) {
        freezeFrames = frames;
    }
}
