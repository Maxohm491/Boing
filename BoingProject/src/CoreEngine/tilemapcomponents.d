module Engine.tilemapcomponents;

import Engine.component;
import Engine.gameobject;
import std.algorithm;
import bindbc.sdl;
import std.json;
import std.stdio;
import constants;
import std.math;

/// These components are just for the background and platform tiles of the tilemap.
/// This could be done with ordinary colliders, but that's inefficient for static environments.

/// A component that renders a static tilemap background using a texture atlas.
class TilemapSprite : IComponent {
    /// 2D array representing tile indices at each grid location.
    int[][] tiles;
    int width;
    int height;

    /// List of source rectangles (frames) for each tile in the texture.
    SDL_Rect[] mFrames;

    SDL_Renderer* mRendererRef;
    TextureComponent mTextureRef;
    TransformComponent mTransformRef;

    /// Constructs a TilemapSprite component attached to the given GameObject.
    this(GameObject owner) {
        mOwner = owner;
        mTextureRef = cast(TextureComponent) mOwner.GetComponent(ComponentType.TEXTURE);
        mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
    }

    void LoadTiles(int[][] tilemap) {
        tiles = tilemap; // not a copy but probably fine
        width = cast(int) tiles.length;
        height = cast(int) tiles[0].length;
    }

    /// Loads the metadata describing the tileset from a JSON file.
    ///
    /// Params:
    ///     filename = Path to the JSON file describing tile dimensions and layout.
    void LoadMetaData(string filename) {
        auto jsonString = File(filename, "r").byLine.joiner("\n");
        auto json = parseJSON(jsonString);

        for (auto topBound = 0; topBound < json["height"].integer; topBound += json["tileHeight"]
            .integer) {
            for (auto leftBound = 0; leftBound < json["width"].integer; leftBound += json["tileWidth"]
                .integer) {
                SDL_Rect newFrame;
                newFrame.x = leftBound;
                newFrame.y = topBound;
                newFrame.w = cast(int) json["tileWidth"].integer;
                newFrame.h = cast(int) json["tileHeight"].integer;
                mFrames ~= newFrame;
            }
        }
    }

    /// Renders the full tilemap to the screen.
    void Render() {
        SDL_Point screenPos = mTransformRef.GetScreenPos();

        SDL_Rect square = SDL_Rect(
            screenPos.x,
            screenPos.y,
            TILE_SIZE,
            TILE_SIZE);

        foreach (i; 0 .. height) {
            foreach (j; 0 .. width) {
                RenderTile(tiles[j][i], &square);
                square.x += TILE_SIZE;
            }
            square.x = screenPos.x;
            square.y += TILE_SIZE;
        }
    }

    /// Renders a single tile based on its index.
    ///
    /// Params:
    ///     index = The tile index into the frames array.
    ///     location = The destination rectangle where the tile will be drawn.
    void RenderTile(int index, SDL_Rect* location) {
        // Do nothing if given -1
        if (index == -1)
            return;

        SDL_RenderCopy(mRendererRef, mTextureRef, &(mFrames[index]), location);
    }
}

/// A component that handles collision detection against static tiles in the tilemap.
class TilemapCollider : IComponent {
    /// 2D array representing tile indices at each grid location.
    int[][] tiles;
    int width;
    int height;

    /// Constructs a TilemapCollider component attached to the given GameObject.
    this(GameObject owner) {
        mOwner = owner;
    }

    void LoadTiles(int[][] tilemap) {
        tiles = tilemap; // not a copy but probably fine
        width = cast(int) tiles.length;
        height = cast(int) tiles[0].length;
    }

    // Return true iff the given rectangle collides with any solid tile in the tilemap.
    bool CheckRect(SDL_Rect* rect) {
        SDL_Rect square = SDL_Rect(0, 0, PIXELS_PER_TILE, PIXELS_PER_TILE);

        foreach (i; 0 .. height) {
            foreach (j; 0 .. width) {
                if (tiles[j][i] <= 15 && SDL_HasIntersection(rect, &square)) // If colliding with wall
                {
                    return true; // Return true immediately if any wall is hit
                }

                square.x += PIXELS_PER_TILE;
            }
            square.x = 0;
            square.y += PIXELS_PER_TILE;
        }

        // Check side edges
        SDL_Rect leftSquare = SDL_Rect(-PIXELS_PER_TILE, 0, PIXELS_PER_TILE, PIXELS_PER_TILE);
        SDL_Rect rightSquare = SDL_Rect(width * PIXELS_PER_TILE, 0, PIXELS_PER_TILE, PIXELS_PER_TILE);
        foreach (i; 0 .. height) {
            if (SDL_HasIntersection(rect, &leftSquare))
                return true;
            if (SDL_HasIntersection(rect, &rightSquare))
                return true;
            leftSquare.y += PIXELS_PER_TILE;
            rightSquare.y += PIXELS_PER_TILE;
        }

        // Check top and bottom edges
        SDL_Rect topSquare = SDL_Rect(0, -PIXELS_PER_TILE, PIXELS_PER_TILE, PIXELS_PER_TILE);
        SDL_Rect bottomSquare = SDL_Rect(0, height * PIXELS_PER_TILE, PIXELS_PER_TILE, PIXELS_PER_TILE);
        foreach (i; 0 .. width) {
            if (SDL_HasIntersection(rect, &topSquare))
                return true;
            if (SDL_HasIntersection(rect, &bottomSquare))
                return true;
            topSquare.x += PIXELS_PER_TILE;
            bottomSquare.x += PIXELS_PER_TILE;
        }

        return false;
    }
}
