module LevelEditor.grid;

import LevelEditor.UI;
import LevelEditor.tilemap;
import bindbc.sdl;
import constants;
import std.stdio;
import std.algorithm.comparison;
import std.math;
import LevelEditor.editor;

/// Represents a grid of tiles in the level editor, used for placing and visualizing platform elements.
/// Also supports start/end placement, spike/arrow autoplacement, and brush-driven editing.
class Grid : Button {
    int x, y, square_size, num_y, num_x; // x is coord of start of grid, y is coord of end
    int* brush;
    int start_x = -1, start_y = -1;
    int end_x = -1, end_y = -1;
    Tilemap mTilemap;
    int[][] tiles;
    int width, height;
    SDL_Renderer* mRendererRef;
    float scale = 1.0f;

    Camera* camera;
    SDL_Rect window; // The rectangle that represents what part of the grid is visible

    /// Constructs a Grid UI element given renderer, x-offset, tilemap, and brush reference.
    this(SDL_Renderer* r, int x, int y, Tilemap tilemap, int* brush, Camera* camera) {
        mRendererRef = r;
        this.x = x;
        this.y = y;
        this.mTilemap = tilemap;
        this.brush = brush;
        onClick = &Clicked;
        onDragOver = &Clicked;
        rect = SDL_Rect(x, 0, SCREEN_X - x, y);
        this.camera = camera;
        window = SDL_Rect(0, 0, SCREEN_X - x, y);
    }

    void SetDimensions(int width, int height) {
        this.width = width;
        this.height = height;
        RecalculateSquareSize();
    }

    void RecalculateSquareSize() {
        float size_x = camera.zoom * ((SCREEN_X - x) / cast(float) width);
        float size_y = camera.zoom * (y / cast(float) height);
        this.square_size = cast(int) round(min(size_x, size_y));
        this.scale = cast(float) PIXELS_PER_TILE / cast(float) square_size;
    }

    /// Handles mouse clicks or drag events, updating tile values using current brush.
    void Clicked(SDL_Point point) {
        // Find which box was clicked and update index
        int x_idx = (point.x - x) / square_size;
        int y_idx = point.y / square_size;

        // Just make sure
        x_idx = clamp(x_idx, 0, width - 1);
        y_idx = clamp(y_idx, 0, height - 1);

        int newTile = BrushToIndex(x_idx, y_idx);
        if (newTile > -1) // If failure just do nothin
        {
            tiles[x_idx][y_idx] = newTile;
            // DO binary fancy count around
            int platValue = RecalculateSurroundings(x_idx, y_idx);
            if (newTile <= 15) {
                tiles[x_idx][y_idx] = platValue;
            }
        }
    }

    /// Recalculates surrounding tile binary value for terrain-blending logic.
    void RecalculateTile(int x_idx, int y_idx) {
        // Make sure we're not checking off the edge
        if (x_idx < 0 || x_idx >= width || y_idx < 0 || y_idx >= height)
            return;

        // binary fancy
        int value = 0;
        if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15)
            value += 1;
        if (y_idx == height - 1 || tiles[x_idx][y_idx + 1] <= 15)
            value += 8;
        if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15)
            value += 2;
        if (x_idx == width - 1 || tiles[x_idx + 1][y_idx] <= 15)
            value += 4;

        tiles[x_idx][y_idx] = value;
    }

    /// Recalculates surrounding tile binary value for terrain-blending logic.
    int RecalculateSurroundings(int x_idx, int y_idx) // return the binary representation of what was recalculated
    {
        int value = 0;
        if (y_idx == 0 || tiles[x_idx][y_idx - 1] <= 15) {
            RecalculateTile(x_idx, y_idx - 1);
            value += 1;
        }
        if (y_idx == height - 1 || tiles[x_idx][y_idx + 1] <= 15) {
            RecalculateTile(x_idx, y_idx + 1);
            value += 8;
        }
        if (x_idx == 0 || tiles[x_idx - 1][y_idx] <= 15) {
            RecalculateTile(x_idx - 1, y_idx);
            value += 2;
        }
        if (x_idx == width - 1 || tiles[x_idx + 1][y_idx] <= 15) {
            RecalculateTile(x_idx + 1, y_idx);
            value += 4;
        }
        return value;
    }

    /// Converts brush type and context into a tile index for the grid.
    ///
    /// Returns: Tile ID to place, or -1 if placement is invalid (e.g., overwriting start/end).
    int BrushToIndex(int x_idx, int y_idx) // 0 background, 1 platform, 2 spike, 3 arrow, 4 start, 5 end
    {
        // Check if we're trying to overwrite start or end
        if ((start_x == x_idx && start_y == y_idx) || (end_x == x_idx && end_y == y_idx)) {
            return -1;
        }

        int newValue = -1;

        switch (*brush) {
        case 0: // background (empty)
            newValue = 16;
            break;
        case 1: // platform base
            newValue = 0;
            break;
        case 2: // spike (top or bottom)
            // If on bottom of level or block below, rightsideup spike. else upsidedown
            if (y_idx == height - 1) {
                newValue = 17;
                break;
            } else if (tiles[x_idx][y_idx + 1] <= 15) {
                newValue = 17;
                break;
            } else if (y_idx == 0) {
                newValue = 23;
                break;
            } else if (tiles[x_idx][y_idx - 1] <= 15) {
                newValue = 23;
                break;
            }
            newValue = -1;
            break;
        case 3: // arrow (left or right)
            // If on left or right, flip accordingly
            if (x_idx == width - 1) {
                newValue = 18;
                break;
            } else if (tiles[x_idx + 1][y_idx] <= 15) {
                newValue = 18;
                break;
            } else if (x_idx == 0) {
                newValue = 26;
                break;
            } else if (tiles[x_idx - 1][y_idx] <= 15) {
                newValue = 26;
                break;
            }
            newValue = -1;
            break;
        case 4: // start tile
            // Clear old start/end so only one per level
            if (start_x > -1)
                tiles[start_x][start_y] = 16;
            start_x = x_idx;
            start_y = y_idx;
            newValue = 19;
            break;
        case 5: // end tile
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
        if (start_x == x_idx && start_y == y_idx && *brush < 4 && newValue > -1) {
            start_x = -1;
            start_y = -1;
        }
        if (end_x == x_idx && end_y == y_idx && *brush < 4 && newValue > -1) {
            end_x = -1;
            end_y = -1;
        }

        // Check if spike or arrow had its wall removed
        if (newValue >= 16) { // if intangible
            if (x_idx > 0 && tiles[x_idx - 1][y_idx] == 18) // if arrow
                tiles[x_idx - 1][y_idx] = 16; // set blank
            if (x_idx < width - 1 && tiles[x_idx + 1][y_idx] == 26) // if arrow
                tiles[x_idx + 1][y_idx] = 16; // set blank
            if (y_idx > 0 && tiles[x_idx][y_idx - 1] == 17) // if spike
                tiles[x_idx][y_idx - 1] = 16; // set blank
            if (y_idx < height - 1 && tiles[x_idx][y_idx + 1] == 23) // if spike
                tiles[x_idx][y_idx + 1] = 16; // set blank
        }

        return newValue;
    }

    /// Renders the tile grid and its UI representation.
    override void Render() {

        SDL_Rect square = SDL_Rect(0, 0, square_size, square_size);
        foreach (i; 0 .. height) {
            foreach (j; 0 .. width) {
                SDL_Rect screenPos = SDL_Rect(cast(int)(square.x - camera.x), cast(
                        int)(square.y - camera.y), square_size, square_size);

                SDL_Rect clipped;
                if (SDL_IntersectRect(&screenPos, &window, &clipped)) {
                    // Calculate the offset in the tile texture to start drawing from. mainly just for ones right on the edge
                    int dx = cast(int) round((clipped.x - screenPos.x) * scale);
                    int dy = cast(int) round((clipped.y - screenPos.y) * scale);
                    int dw = cast(int) round(clipped.w * scale);
                    int dh = cast(int) round(clipped.h * scale);

                    // Source rect for the tile texture 
                    SDL_Rect srcRect = SDL_Rect(dx, dy, dw, dh);
                    writeln(srcRect);
                    clipped.x += x; // Offset by grid x position

                    // Render only the visible part of the tile
                    mTilemap.RenderTilePartial(tiles[j][i], &srcRect, &clipped);
                }

                square.x += square_size;
            }
            square.x = 0;
            square.y += square_size;
        }

        // Draw grid itself
        SDL_SetRenderDrawColor(mRendererRef, 150, 150, 150, SDL_ALPHA_OPAQUE);

        SDL_RenderDrawLine(mRendererRef, x, 1, x + width * square_size, 1);
        SDL_RenderDrawLine(mRendererRef, x, y, x + width * square_size, y);
        SDL_RenderDrawLine(mRendererRef, SCREEN_X - 1, 0, SCREEN_X - 1, y);
        SDL_RenderDrawLine(mRendererRef, x, 0, x, y);

        // math magic !
        for(int i = (cast(int) floor(cast(float) camera.x / cast(float) square_size) + 1) * square_size  - camera.x + x; i <= SCREEN_X; i+= square_size) {
            SDL_RenderDrawLine(mRendererRef, i, 0, i, y);
        }

        for(int i = (cast(int) floor(cast(float) camera.y / cast(float) square_size) + 1) * square_size - camera.y; i <= y; i += square_size) {
            SDL_RenderDrawLine(mRendererRef, x, i, SCREEN_X, i);
        }

        // foreach (i; 0 .. width + 1) {
        //     SDL_RenderDrawLine(mRendererRef, x + i * square_size, 0, x + i * square_size, height * square_size);
        // }
        // foreach (i; 0 .. height + 1) {
        //     SDL_RenderDrawLine(mRendererRef, x, i * square_size, x + width * square_size, i * square_size);
        // }
        SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
    }
}
