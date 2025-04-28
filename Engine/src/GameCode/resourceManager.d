module resourceManager;

import bindbc.sdl;
import std.string;
import std.exception;
import std.conv;
import std.traits;
import std.stdio;
import std.typecons;
import std.algorithm;
import std.container;
import std.json;
import std.file;
import std.array;


import sprite;

class ResourceManager {
private:
    static ResourceManager instance;
    SDL_Renderer* renderer;
    SDL_Texture*[string] textures;
    int jsonparsed = 0;
    Frame[] resourceManagerFrames;
    long[][string] resourceManagerFrameNumbers;

    this(SDL_Renderer* renderer) {
        this.renderer = renderer;
    }

public:
    static ResourceManager getInstance(SDL_Renderer* renderer) {
        if (instance is null) {
            instance = new ResourceManager(renderer);
        }
        return instance;
    }

    // Load or retrieve a texture
    SDL_Texture* getTexture(string filename) {
        if (filename in textures) {
            return textures[filename];
        }

        // Load texture
        SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
        SDL_FreeSurface(surface);

        textures[filename] = texture; 
        return texture;
    }

    void parseJson(string filename, ref Frame[] mFrames, ref long[][string] mFrameNumbers){
        if (jsonparsed == 1) {
            mFrames = resourceManagerFrames;
            mFrameNumbers = resourceManagerFrameNumbers;
            return;
        }

        auto myFile = File(filename);
        auto jsonFileContents = myFile.byLine.joiner("\n");
        auto j=parseJSON(jsonFileContents);

        auto width = j["format"]["width"].integer;
        auto height = j["format"]["height"].integer;
        auto tileWidth = j["format"]["tileWidth"].integer;
        auto tileHeight = j["format"]["tileHeight"].integer;

        int columns = width / tileWidth;
        int rows = height / tileHeight;

        //put each frame into the mFrames array
        for (int y = 0; y < rows; y++) {
            for (int x = 0; x < columns; x++) {
                Frame f;
                SDL_Rect rect;
                rect.x = cast(int)(x * tileWidth);
                rect.y = cast(int)(y * tileHeight);
                rect.w = cast(int)tileWidth;
                rect.h = cast(int)tileHeight;
                f.mRect = rect;
                f.mElapsedTime = 0;
                mFrames ~= f;
            }
        }
        //put the array of animation sequences into the mFrameNumbers array
        foreach (key, value; j["frames"].object) {
            mFrameNumbers[key] = value.array.map!(x => x.integer).array;
        }
        jsonparsed = 1;
        resourceManagerFrames = mFrames;
        resourceManagerFrameNumbers = mFrameNumbers;    
    }

    // Free all loaded resources
    void cleanUp() {
        foreach (filename, texture; textures) {
            SDL_DestroyTexture(texture);
        }
        textures.clear();
    }

    ~this() {
        cleanUp();
    }
}
