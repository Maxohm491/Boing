module GameCode.tilemapcomponents;

import GameCode.component;
import GameCode.gameobject;
import std.algorithm;
import bindbc.sdl;
import std.json;
import std.stdio;
import constants;

/// These components are just for the background and platform tiles of the tilemap
/// This could be done with ordinary colliders, but that's inefficient

class TilemapSprite : IComponent
{
    int[GRID_Y][GRID_X] tiles;

    SDL_Rect[] mFrames;
    SDL_Renderer* mRendererRef;
    TextureComponent mTextureRef;

    this(GameObject owner)
    {
        mOwner = owner;
        mTextureRef = cast(TextureComponent) mOwner.GetComponent(ComponentType.TEXTURE);
    }

    /// Load a tilemap from a file
    void LoadMetaData(string filename)
    {
        auto jsonString = File(filename, "r").byLine.joiner("\n");
        auto json = parseJSON(jsonString);

        // Fill mFrames:
        for (auto topBound = 0; topBound < json["height"].integer; topBound += json["tileHeight"]
            .integer)
        {
            for (auto leftBound = 0; leftBound < json["width"].integer; leftBound += json["tileWidth"]
                .integer)
            {
                SDL_Rect newFrame;
                newFrame.x = leftBound;
                newFrame.y = topBound;
                newFrame.w = cast(int) json["tileWidth"].integer;
                newFrame.h = cast(int) json["tileHeight"].integer;
                mFrames ~= newFrame;
            }
        }
    }

    void Render()
    {
        SDL_Rect square = SDL_Rect(0, 0, TILE_SIZE, TILE_SIZE);
        foreach (i; 0 .. GRID_Y)
        {
            foreach (j; 0 .. GRID_X)
            {
                RenderTile(tiles[j][i], &square);
                square.x += TILE_SIZE;
            }
            square.x = 0;
            square.y += TILE_SIZE;
        }
    }

    void RenderTile(int index, SDL_Rect* location)
    {
        // Do nothing if given -1
        if (index == -1)
            return;

        SDL_RenderCopy(mRendererRef, mTextureRef, &(mFrames[index]), location);
    }
}

class TilemapCollider : IComponent
{
    int[GRID_Y][GRID_X] tiles;

    this(GameObject owner)
    {
        mOwner = owner;
    }

    /// Returns rects of wall collisions
    SDL_Rect[] GetWallCollisions(SDL_Rect* rect) {
        SDL_Rect[] toReturn;
        SDL_Rect square = SDL_Rect(0, 0, TILE_SIZE, TILE_SIZE);
        foreach (i; 0 .. GRID_Y)
        {
            foreach (j; 0 .. GRID_X)
            {
                if(tiles[j][i] <= 15 && SDL_HasIntersection(rect, &square)) // If colliding with wall
                    toReturn ~= square;
                square.x += TILE_SIZE;
            }
            square.x = 0;
            square.y += TILE_SIZE;
        }
        return toReturn;
    }
}
