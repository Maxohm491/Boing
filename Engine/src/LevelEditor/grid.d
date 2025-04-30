module LevelEditor.grid;

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
    int start_x = -1, start_y = -1;
    int end_x = -1, end_y = -1;
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
        if (newTile > -1) // If failure just do nothin
        {
            tiles[x_idx][y_idx] = newTile;
            // DO binary fancy count around
            int platValue = RecalculateSurroundings(x_idx, y_idx);
            if (newTile <= 15)
            {
                tiles[x_idx][y_idx] = platValue;
            }
        }
    }

    void RecalculateTile(int x_idx, int y_idx)
    {
        // Make sure we're not checking off the edge
        if (x_idx < 0 || x_idx >= GRID_X || y_idx < 0 || y_idx >= GRID_Y)
            return;

        // binary fancy
        int value = 0;
        if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15)
            value += 1;
        if (y_idx == GRID_Y - 1 || tiles[x_idx][y_idx + 1] <= 15)
            value += 8;
        if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15)
            value += 2;
        if (x_idx == GRID_X - 1 || tiles[x_idx + 1][y_idx] <= 15)
            value += 4;

        tiles[x_idx][y_idx] = value;
    }

    int RecalculateSurroundings(int x_idx, int y_idx) // return the binary representation of what was recalculated
    {
        int value = 0;
        if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15)
        {
            RecalculateTile(x_idx, y_idx - 1);
            value += 1;
        }
        if (y_idx == GRID_Y - 1 || tiles[x_idx][y_idx + 1] <= 15)
        {
            RecalculateTile(x_idx, y_idx + 1);
            value += 8;
        }
        if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15)
        {
            RecalculateTile(x_idx - 1, y_idx);
            value += 2;
        }
        if (x_idx == GRID_X - 1 || tiles[x_idx + 1][y_idx] <= 15)
        {
            RecalculateTile(x_idx + 1, y_idx);
            value += 4;
        }
        return value;
    }

    int BrushToIndex(int x_idx, int y_idx) // 0 background, 1 platform, 2 spike, 3 arrow, 4 start, 5 end
    {
        int newValue = -1;

        switch (*brush)
        {
        case 0:
            newValue = 16;
            break;
        case 1:
            newValue =  0;
            break;
        case 2:
            // If on bottom of level or block below, rightsideup spike. else upsidedown
            if (y_idx == GRID_Y - 1)
            {
                newValue = 17;
                break;
            }
            else if (tiles[x_idx][y_idx + 1] <= 15)
            {
                newValue = 17;
                break;
            }
            else if (y_idx == 0)
            {
                newValue = 23;
                break;
            }
            else if (tiles[x_idx][y_idx - 1] <= 15)
            {
                newValue = 23;
                break;
            }
            newValue = -1;
            break;
        case 3:
            // If on left or right, flip accordingly
            if (x_idx == GRID_X - 1)
            {
                newValue = 18;
                break;
            }
            else if (tiles[x_idx + 1][y_idx] <= 15)
            {
                newValue = 18;
                break;
            }
            else if (x_idx == 0)
            {
                newValue = 26;
                break;
            }
            else if (tiles[x_idx - 1][y_idx] <= 15)
            {
                newValue = 26;
                break;
            }
            newValue = -1;
            break;
        case 4:
            // Clear old start/end so only one per level
            if (start_x > -1)
                tiles[start_x][start_y] = 16;
            start_x = x_idx;
            start_y = y_idx;
            newValue = 19;
            break;
        case 5:
            if (end_x > -1)
                tiles[end_x][end_y] = 16;
            end_x = x_idx;
            end_y = y_idx;
            newValue = 20;
            break;
        default:
            assert(0, "invalid brush number");
        }

        // Check if start or end got overwritten
        if (start_x == x_idx && start_y == y_idx && *brush < 4 && newValue > -1)
        {
            start_x = -1;
            start_y = -1;
        }
        if (end_x == x_idx && end_y == y_idx && *brush < 4 && newValue > -1)
        {
            end_x = -1;
            end_y = -1;
        }

        // Check if spike or arrow had its wall removed
        if(newValue >= 16) { // if intangible
            if(x_idx > 0 && tiles[x_idx - 1][y_idx] == 18) // if arrow
                tiles[x_idx - 1][y_idx] = 16; // set blank
            if(x_idx < GRID_X - 1 && tiles[x_idx + 1][y_idx] == 26 ) // if arrow
                tiles[x_idx + 1][y_idx] = 16; // set blank
            if(y_idx > 0 && tiles[x_idx][y_idx - 1] == 17 ) // if spike
                tiles[x_idx][y_idx - 1] = 16; // set blank
            if(y_idx < GRID_Y - 1 && tiles[x_idx][y_idx + 1] == 23) // if spike
                tiles[x_idx][y_idx + 1] = 16; // set blank
        }

        return newValue;
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

        // Draw grid itself
        SDL_SetRenderDrawColor(mRendererRef, 150, 150, 150, SDL_ALPHA_OPAQUE);
        foreach (i; 0 .. GRID_X + 1)
        {
            SDL_RenderDrawLine(mRendererRef, x + i * square_size, 0, x + i * square_size, GRID_Y * square_size);
        }
        foreach (i; 0 .. GRID_Y + 1)
        {
            SDL_RenderDrawLine(mRendererRef, x, i * square_size, x + GRID_X * square_size, i * square_size);
        }
        SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
    }
}
