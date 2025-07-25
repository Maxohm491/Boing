// Sourced with modifications from 08_gameobject/singleton.d
module Engine.resourcemanager;

import bindbc.sdl;
import std.string;
import std.stdio;
import Engine.colors;

struct ResourceManager {
    static ResourceManager* GetInstance() {
        if (mInstance is null) {
            mInstance = new ResourceManager();
        }
        return mInstance;
    }

    static SDL_Texture* LoadImageResource(string filename, SDL_Renderer* r) {
        if (filename in mImageResourceMap) {
            return mImageResourceMap[filename];
        } else {
            SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
            if (surface is null) {
                writeln("Failed to load BMP: ", SDL_GetError());
                assert(0);
            }

            SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGB(surface.format, 0, 0, 255)); // blue is clear
            SDL_Surface* converted = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_ARGB8888, 0);
            SDL_FreeSurface(surface);
            surface = converted;

            // Apply all color replacements from the map
            foreach (srcRGB, dstRGB; colorReplacementMap) {
                Uint32 fromColor = SDL_MapRGB(surface.format, srcRGB.r, srcRGB.g, srcRGB.b);
                Uint32 toColor = SDL_MapRGB(surface.format, dstRGB[0], dstRGB[1], dstRGB[2]);
                replaceColor(surface, fromColor, toColor);
            }

            SDL_Texture* texture = SDL_CreateTextureFromSurface(r, surface);
            SDL_FreeSurface(surface);

            if (texture is null)
                writeln("Failed to create texture: ", SDL_GetError());

            mImageResourceMap[filename] = texture;

            return texture;
        }
    }

    static void FreeAllTextures() {
        foreach (texture; mImageResourceMap) {
            if (texture !is null)
                SDL_DestroyTexture(texture);
        }
        mImageResourceMap.clear();
    }

    static void replaceColor(SDL_Surface* surface, Uint32 srcColor, Uint32 dstColor) {
        SDL_LockSurface(surface);

        auto pixels = cast(Uint32*) surface.pixels;
        int totalPixels = surface.w * surface.h;

        foreach (i; 0 .. totalPixels) {
            if (pixels[i] == srcColor)
                pixels[i] = dstColor;
        }

        SDL_UnlockSurface(surface);
    }

private:
    static ResourceManager* mInstance;
    static SDL_Texture*[string] mImageResourceMap;
}
