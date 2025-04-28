import std.random, std.json, std.file, std.string, std.stdio, std.algorithm, std.conv, std.array;

import resourceManager;
import component;
// Third-party libraries
import bindbc.sdl;

Random rnd;
shared static this(){
    auto rnd = Random(42);
}

struct Frame{
    SDL_Rect mRect;
    float mElapsedTime;
}

class Sprite{

public:
    SDL_Texture* mTexture;
    SDL_Rect     mRectangle;
    float angle = 0;
    float velocity_y = 0;
    float velocity_x = 0;
    int pos_x = 0;
    int pos_y = 0;
    
    IComponent[COMPONENTS] mComponents; 

    // Collection of all of the possible frames that are part of a sprite
    // At a minimum, these are just rectangles
    Frame[] mFrames;
    // Array of longs for the named sequence of an animation
    // i.e. this is a map, with a name (e.g. 'walkUp') followed by frame numbers (e.g. [0,1,2,3] )
    long[][string] mFrameNumbers;


    // Stateful information about the current animation
    // sequence that is playing
    private:
        string mCurrentAnimationName = "wiggle"; // Which animation is currently playing
        long mCurrentFramePlaying = 0;   // Current frame that is playing, an index into 'mFrames'
        long mLastFrameInSequence = 1;

public:
    this(SDL_Renderer* renderer, string bitmapFilePath, int _type, ResourceManager resourceManager){
        import std.string; // for toZString
                           // Create a texture
        mTexture = resourceManager.getTexture(bitmapFilePath);
        // Position the rectangle 
        mRectangle.w = 30;
        mRectangle.h = 30;
        type = _type;

        //parse the json file
        if (type == 1){
            resourceManager.parseJson("./assets/enemy.json", mFrames, mFrameNumbers);
        }
    }

    // Destroy anything 'heap' allocated.
    // Remember, SDL is a C library, thus heap allocated resources need
    // to be destroyed
    ~this(){
        SDL_DestroyTexture(mTexture);
    }


    void Input(){
        mComponents[COMPONENTS.SCRIPT].input();
    }

    void Update(){
        mComponents[COMPONENTS.SCRIPT].update();
    }


    auto mPrevious = 0;
    auto mCurrent = 0;
    auto mElapsed = 0;
    void Render(SDL_Renderer* renderer){
        
        // If the type is 1, then we are rendering the animation
        if (type == 1){

            mCurrent = SDL_GetTicks();
            mElapsed = mCurrent - mPrevious;
            if (mElapsed > 700){
                if (mCurrentFramePlaying < mLastFrameInSequence){
                    mCurrentFramePlaying++;
                } else {
                    mCurrentFramePlaying = mFrameNumbers[mCurrentAnimationName][0];
                }
                mPrevious = SDL_GetTicks();
            }


            SDL_Rect srcRect = mFrames[mCurrentFramePlaying].mRect;

            SDL_RenderCopy(renderer, mTexture, &srcRect, &mRectangle);
        } else {
            SDL_RenderCopyEx(renderer,mTexture, null, &mRectangle,
                   angle, null, SDL_FLIP_NONE);
        }
    }

    void SetPosition(int x, int y){
        mRectangle.x = x;
        mRectangle.y = y;
    }
}