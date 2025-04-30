module LevelEditor.tiles;

import LevelEditor.UI;
import LevelEditor.tilemap;
import bindbc.sdl;
import constants;
import std.stdio;
import std.algorithm.comparison;

// The drawn tilemap
class Grid : Button
{
    int x, square_size, num_y, num_x; // x is coord of start of gird
    int* brush;
    int start_x, start_y = -1;
    int end_x, end_y = -1;
    Tilemap mTilemap;
    int[GRID_Y][GRID_X] tiles;
    SDL_Renderer* mRendererRef;

    this(SDL_Renderer* r, int x, Tilemap tilemap, int* brush)
    {
        mRendererRef = r;
        this.x = x;
        this.mTilemap = tilemap;
        this.brush = brush;
        this.square_size = (SCREEN_X - x) / GRID_X;
        onClick = &Clicked;
        onDragOver = &Clicked;
        rect = SDL_Rect(x, 0, SCREEN_X - x, square_size * GRID_Y);

        foreach (i; 0 .. GRID_Y)
        {
            foreach (j; 0 .. GRID_X)
            {
                tiles[j][i] = 16;
            }
        }
    }

    void Clicked(SDL_Point point)
    {
        // Find which box was clicked and update index
        int x_idx = (point.x - x) / square_size;
        int y_idx = point.y / square_size;

        // Just make sure
        x_idx = clamp(x_idx, 0, GRID_X - 1);
        y_idx = clamp(y_idx, 0, GRID_Y - 1);

        int newTile = BrushToIndex(x_idx, y_idx);
        if(newTile > -1) // If failure just do nothin
        {
            tiles[x_idx][y_idx] = newTile;
        }
    }

    void RecalculateTile(int x_idx, int y_idx) {
        // Make sure we're not checking off the edge
        if(x_idx < 0 || x_idx >= GRID_X || y_idx < 0 || y_idx >= GRID_Y) return;
         
        // binary fancy
        int value = 0;
        if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15)
            value += 1;
        if (y_idx == GRID_Y - 1 || tiles[x_idx][y_idx + 1] <= 15)
            value += 8;
        if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15)
            value += 2;
        if (y_idx == GRID_X - 1 || tiles[x_idx + 1][y_idx] <= 15)
            value += 4;
        
        tiles[x_idx][y_idx] = value;
    }

    int BrushToIndex(int x_idx, int y_idx) // 0 background, 1 platform, 2 spike, 3 arrow, 4 start, 5 end
    {
        switch (*brush)
        {
        case 0:
            return 16;
        case 1:
            // DO binary fancy count around
            int value = 0;
            if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15) {
                RecalculateTile(x_idx, y_idx - 1);
                value += 1;
            }
            if (y_idx == GRID_Y - 1 || tiles[x_idx][y_idx + 1] <= 15) {
                RecalculateTile(x_idx, y_idx + 1);
                value += 8;
            }
            if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15) {
                RecalculateTile(x_idx - 1, y_idx);
                value += 2;
            }
            if (y_idx == GRID_X - 1 || tiles[x_idx + 1][y_idx] <= 15) {
                RecalculateTile(x_idx + 1, y_idx);
                value += 4;
            }
            return value;
        case 2:
            // If on bottom of level or block below, rightsideup spike. else upsidedown
            if (y_idx == GRID_Y - 1)
            {
                return 17;
            }
            else if (tiles[x_idx][y_idx + 1] <= 15)
            {
                return 17;
            }
            else if (y_idx == 0)
            {
                return 23;
            }
            else if (tiles[x_idx][y_idx - 1] <= 15)
            {
                return 23;
            }
            return -1; // else error

        case 3:
            // If on left or right, flip accordingly
            if (x_idx == GRID_X - 1)
            {
                return 18;
            }
            else if (tiles[x_idx + 1][y_idx] <= 15)
            {
                return 18;
            }
            else if (x_idx == 0)
            {
                return 26;
            }
            else if (tiles[x_idx - 1][y_idx] <= 15)
            {
                return 26;
            }
            return -1; // else error
        case 4:
            // Clear old start/end so only one per level
            if (hasStartAndEnd())
                tiles[start_x][start_y] = 16;
            start_x = x_idx;
            start_y = y_idx;
            return 19;
        case 5:
            if (hasStartAndEnd())
                tiles[start_x][start_y] = 16;
            end_x = x_idx;
            end_y = y_idx;
            return 20;
        default:
            assert(0, "invalid brush number");
        }
    }

    bool hasStartAndEnd()
    {
        return start_x > -1 && end_x > -1;
    }

    override void Render()
    {
        SDL_Rect square = SDL_Rect(x, 0, square_size, square_size);
        foreach (i; 0 .. GRID_Y)
        {
            foreach (j; 0 .. GRID_X)
            {
                mTilemap.RenderTile(tiles[j][i], &square);
                square.x += square_size;
            }
            square.x = x;
            square.y += square_size;
        }
    }
}

// // A type of button with a tile texture and such, for selecting on the left
// class TileSelector : Button
// {
//     int mIndex; // an index into tilemap
//     Tilemap mTilemap;
//     int* mCurrTileRef;
//     SDL_Renderer* mRendererRef;
//     SDL_Rect background1, background2; // For bordering. Two of them to make a 2px thick border

//     this(int index, Tilemap tilemap, SDL_Rect location, SDL_Renderer* r, int* currTileRef)
//     {
//         rect = location;
//         mIndex = index;
//         mTilemap = tilemap;
//         onClick = &Clicked;
//         onDragOver = &Dragged;
//         mCurrTileRef = currTileRef;
//         mRendererRef = r;
//         background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
//         background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
//     }

//     void Clicked()
//     {
//         *mCurrTileRef = mIndex;
//     }

//     void Dragged()
//     {
//     }

//     override void Render()
//     {
//         // If selected, draw a red border
//         if (*mCurrTileRef == mIndex)
//         {
//             SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
//             SDL_RenderDrawRect(mRendererRef, &background1);
//             SDL_RenderDrawRect(mRendererRef, &background2);
//             SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
//         }

//         mTilemap.RenderTile(mIndex, &rect);
//     }
// }

// Grid square that has a tile
// class GridSquare : Button
// {
//     int index; // an index into mTilemap
//     Tilemap mTilemap;
//     SDL_Renderer* mRendererRef;
//     int* mCurrTileRef;

//     this(Tilemap tilemap, SDL_Rect location, SDL_Renderer* r, int* currTileRef, bool* isBottomLayer)
//     {
//         rect = location;
//         mCurrTileRef = currTileRef;
//         mRendererRef = r;
//         mTilemap = tilemap;
//         onClick = &Clicked;
//         onDragOver = &Clicked;
//         mTopIndex = -1;
//     }

//     void Clicked()
//     {
//         if (*mBottomLayer)
//             mBottomIndex = *mCurrTileRef;
//         else
//             mTopIndex = *mCurrTileRef;
//     }

//     override void Render()
//     {
//         mTilemap.RenderTile(index, &rect);

//         // This could be just done with drawing lines in main but I like this
//         SDL_SetRenderDrawColor(mRendererRef, 175, 175, 175, SDL_ALPHA_OPAQUE);
//         SDL_RenderDrawRect(mRendererRef, &rect);
//         SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
//     }
// }
