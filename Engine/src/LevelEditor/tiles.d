module LevelEditor.tiles;

import LevelEditor.UI;
import LevelEditor.tilemap;
import bindbc.sdl;

// A type of button with a tile texture and such, for selecting on the left
class TileSelector : Button
{
    int mIndex; // an index into tilemap
    Tilemap mTilemap;
    int* mCurrTileRef;
    SDL_Renderer* mRendererRef;
    SDL_Rect background1, background2; // For bordering. Two of them to make a 2px thick border

    this(int index, Tilemap tilemap, SDL_Rect location, SDL_Renderer* r, int* currTileRef)
    {
        rect = location;
        mIndex = index;
        mTilemap = tilemap;
        onClick = &Clicked;
        onDragOver = &Dragged;
        mCurrTileRef = currTileRef;
        mRendererRef = r;
        background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
        background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
    }

    void Clicked()
    {
        *mCurrTileRef = mIndex;
    }

    void Dragged() { }

    override void Render()
    {
        // If selected, draw a red border
        if(*mCurrTileRef == mIndex) {
            SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
            SDL_RenderDrawRect(mRendererRef, &background1);
            SDL_RenderDrawRect(mRendererRef, &background2);
            SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        }

        mTilemap.RenderTile(mIndex, &rect);
    }
}

// Grid square that can have a tile on two layers, or be empty
class GridSquare : Button
{
    int mBottomIndex, mTopIndex; // an index into tilemap
    Tilemap mTilemap;
    SDL_Renderer* mRendererRef;
    int* mCurrTileRef;
    bool* mBottomLayer;

    this(Tilemap tilemap, SDL_Rect location, SDL_Renderer* r, int* currTileRef, bool* isBottomLayer)
    {
        rect = location;
        mCurrTileRef = currTileRef;
        mRendererRef = r;
        mTilemap = tilemap;
        onClick = &Clicked;
        onDragOver = &Clicked;
        mBottomLayer = isBottomLayer;
        mBottomIndex = -1;
        mTopIndex = -1;
    }

    void Clicked()
    {
        if (*mBottomLayer)
            mBottomIndex = *mCurrTileRef;
        else
            mTopIndex = *mCurrTileRef;
    }

    override void Render()
    {
        // Start blank by default
        SDL_RenderFillRect(mRendererRef, &rect);

        // Always draw grid lines
        // This could be just done with drawing lines in main but I like this
        SDL_SetRenderDrawColor(mRendererRef, 175, 175, 175, SDL_ALPHA_OPAQUE);
        SDL_RenderDrawRect(mRendererRef, &rect);
        SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);

        mTilemap.RenderTile(mBottomIndex, &rect);
        mTilemap.RenderTile(mTopIndex, &rect);

    }
}
