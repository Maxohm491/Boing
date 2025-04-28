module LevelEditor.tilemap;

import bindbc.sdl;
import std.json;
import std.stdio;
import std.algorithm;
import std.string;

class Texture
{
    SDL_Texture* mTexture;
    SDL_Renderer* mRendererRef;
    alias mTexture this;

    void LoadTexture(string filename, SDL_Renderer* r)
    {
        mRendererRef = r;
        SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
        SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGB(surface.format, 0, 0, 0)); // Black is clear
        mTexture = SDL_CreateTextureFromSurface(r, surface);
        SDL_FreeSurface(surface);
    }

    void Render(SDL_Rect* location)
    {
        SDL_RenderCopy(mRendererRef, mTexture, null, location);
    }
}

// Similar to an animated sprite
class Tilemap
{

    SDL_Rect[] mFrames;

    // Helpers for references to data
    SDL_Renderer* mRendererRef;
    Texture mTextureRef;

    // Hold a copy of the texture that is referenced
    this(string filename, SDL_Renderer* r, Texture textureRef)
    {
        mRendererRef = r;
        mTextureRef = textureRef;
        this.LoadMetaData(filename);
    }

    /// Load a data file that describes meta-data about animations stored in a single file.
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

    void RenderTile(int index, SDL_Rect* location)
    {
        // Do nothing if given -1
        if(index == -1) return;

        SDL_RenderCopy(mRendererRef, mTextureRef, &(mFrames[index]), location);
    }
}
