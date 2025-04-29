// Sourced with modifications from 08_gameobject/singleton.d
module GameCode.resourcemanager;

import bindbc.sdl;
import std.string;
import std.stdio;

struct ResourceManager
{

    static ResourceManager* GetInstance()
    {
        if (mInstance is null)
        {
            mInstance = new ResourceManager();
        }
        return mInstance;
    }

    static SDL_Texture* LoadImageResource(string filename, SDL_Renderer* r)
    {
        if (filename in mImageResourceMap)
        {
            return mImageResourceMap[filename];
        }
        else
        {
            SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
            SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGB(surface.format, 0, 0, 0)); // black is clear
            SDL_Texture* texture = SDL_CreateTextureFromSurface(r, surface);
            SDL_FreeSurface(surface);
            mImageResourceMap[filename] = texture;
            
            return texture;
        }
    }

private:
    static ResourceManager* mInstance;
    static SDL_Texture*[string] mImageResourceMap;
}
