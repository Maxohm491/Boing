module GameCode.scene;

import GameCode.component;
import GameCode.tilemapcomponents;
import std.algorithm;
import GameCode.gameobject;
import GameCode.gameapplication;
import GameCode.scripts.player;
import GameCode.scripts.shooter;
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
    mat3 positionMat;
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    float posX = 0.0f;
    float posY = 0.0f;

    void PositionCamera(float x, float y) {
        posX = x;
        posY = y;
        updateMatrix();
    }

    void ScaleCamera(float x, float y) {
        scaleX = x;
        scaleY = y;
        updateMatrix();
    }

    void updateMatrix() {
        // Scale, then translate
        positionMat = MakeScale(scaleX, scaleY) * MakeTranslate(posX, posY);
    }
}

/// Represents a scene containing game objects, a tilemap, and associated state.
class Scene {
    GameObject[] gameObjects; // Don't use a scene tree bc that's complicated
    GameObject player;
    GameState mGameState;
    Camera camera;

    SDL_Renderer* mRendererRef;
    SDL_Point mSpawnPoint;
    GameObject tilemap;
    void delegate() mOnComplete;

    // Create scene /// Constructs a Scene and loads it from a JSON file.
    ///
    /// Params:
    ///     r = The SDL_Renderer used for rendering.
    ///     sceneIndex = Index used to select which scene JSON to load.
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
        sprite.mRect.w = TILE_SIZE;
        sprite.mRect.h = TILE_SIZE;

        collider.rect.w = TILE_SIZE;
        collider.rect.h = (TILE_SIZE * 5) / 8;
        collider.offset.x = 0;
        collider.offset.y = (TILE_SIZE * 3) / 8;

        auto input = new InputComponent(player);
        player.AddComponent!(ComponentType.INPUT)(input);

        auto playScript = new Player(player);
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

        collider.rect.w = TILE_SIZE;
        collider.rect.h = TILE_SIZE; // be generous

        return apple;
    }

    GameObject MakeSpike(SDL_Point location, bool up) {
        GameObject spike = MakeCollider("spike");
        TransformComponent transform = cast(TransformComponent) spike.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) spike.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(location.x, location.y);

        collider.rect.w = TILE_SIZE;
        collider.rect.h = TILE_SIZE / 2; // be generous
        if (up) {
            collider.offset.y = TILE_SIZE / 2;
        }

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
        camera.ScaleCamera(1,1); // TODO: scaling does not quite work with pixel aligment. put pixel size in scenedata.

        tilemap = GameObjectFactory!(ComponentType.TRANSFORM, ComponentType.TEXTURE,
            ComponentType.TILEMAP_COLLIDER, ComponentType.TILEMAP_SPRITE)("tilemap");

        auto textIn = readText(filename);
        auto root = parseJSON(textIn);
        auto obj = root.object;

        int[GRID_Y][GRID_X] buf;

        size_t y = 0;
        foreach (rowVal; obj["tiles"].array) {
            size_t x = 0;
            foreach (cell; rowVal.array) {
                int value = cell.get!int;
                if (value == 19) // Start tile
                {
                    mSpawnPoint = SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(TILE_SIZE * x));
                    value = 16;
                } else if (value == 20) // End tile
                {
                    value = 28; // apple
                    AddGameObject(MakeApple(SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(
                            TILE_SIZE * x))));
                } else if (value == 17) // up spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(
                            TILE_SIZE * x)), true));
                else if (value == 23) // down spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(
                            TILE_SIZE * x)), false));
                else if (value == 18) // left shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(
                            TILE_SIZE * x)), false));
                else if (value == 26) // right shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(TILE_SIZE * y), cast(int)(
                            TILE_SIZE * x)), true));
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
        sprite.tiles = buf;
        collider.tiles = buf;

        AddGameObject(tilemap);
        AddGameObject(MakePlayer());
    }

    void Input(SDL_Event e) {
        foreach (obj; gameObjects) {
            obj.Input(e);
        }
    }

    void Update() {
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
        Vec2f xy = playerTransform.mWorldMatrix.Frommat3GetTranslation();
        // camera.PositionCamera(-xy.x + (SCREEN_X / 2) - TILE_SIZE, -xy.y + (SCREEN_Y / 2) - TILE_SIZE); // center on player

        // Set each objects local pos based on camera
        foreach (obj; gameObjects) {
            auto transform = cast(TransformComponent) obj.GetComponent(
                ComponentType.TRANSFORM);
            if (transform !is null) {
                transform.mScreenMatrix = camera.positionMat * transform.mWorldMatrix;
            }
        }
        foreach (obj; gameObjects) {
            obj.Render();
        }
    }

    void AddGameObject(GameObject go) {
        gameObjects ~= go;
    }
}
