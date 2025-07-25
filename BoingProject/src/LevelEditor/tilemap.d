module LevelEditor.tilemap;

import bindbc.sdl;
import std.json;
import std.stdio;
import std.algorithm;
import std.string;

/// A wrapper around SDL texture loading and rendering.
/// Used to load BMPs and support transparent backgrounds via colorkeying.
class Texture {
    SDL_Texture* mTexture;
    SDL_Renderer* mRendererRef;
    alias mTexture this; /// Allows implicit access to mTexture when passed to SDL functions.

    /* Loads a BMP texture from file and sets black (0,0,0) as transparent.
     Params:
         filename = Path to the BMP file.
         r = SDL renderer that will render this texture.
    */
    void LoadTexture(string filename, SDL_Renderer* r) {
        mRendererRef = r;
        SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
        assert(surface !is null, "Failed to load tilemap");
        SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGB(surface.format, 0, 0, 0)); // Black is clear
        mTexture = SDL_CreateTextureFromSurface(r, surface);
        SDL_FreeSurface(surface);
    }

    /*
         Renders this texture at the given location.
    
         Params:
             location = Destination rectangle on the screen.
    */
    void Render(SDL_Rect* location) {
        SDL_RenderCopy(mRendererRef, mTexture, null, location);
    }
}

/// Handles rendering of individual tile frames from a single tilemap texture.
/// Tile metadata (frame size, grid layout) is loaded from a JSON metadata file.
class Tilemap {

    SDL_Rect[] mFrames;

    // Helpers for references to data
    SDL_Renderer* mRendererRef;
    Texture mTextureRef;

    // Hold a copy of the texture that is referenced
    this(string filename, SDL_Renderer* r, Texture textureRef) {
        mRendererRef = r;
        mTextureRef = textureRef;
        this.LoadMetaData(filename);
    }

    /// Load a data file that describes meta-data about animations stored in a single file.
    void LoadMetaData(string filename) {
        auto jsonString = File(filename, "r").byLine.joiner("\n");
        auto json = parseJSON(jsonString);

        // Fill mFrames:
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

    void RenderTile(int index, SDL_Rect* location) {
        // Do nothing if given -1
        if (index == -1)
            return;

        SDL_RenderCopy(mRendererRef, mTextureRef, &(mFrames[index]), location);
    }

    void RenderTilePartial(int index, SDL_Rect* src, SDL_Rect* dst) {
    if (index == -1)
        return;

    // Offset src by the tile's frame in the atlas
    SDL_Rect frame = mFrames[index];
    SDL_Rect realSrc = SDL_Rect(
        frame.x + src.x,
        frame.y + src.y,
        src.w,
        src.h
    );

    SDL_RenderCopy(mRendererRef, mTextureRef, &realSrc, dst);
}
}
