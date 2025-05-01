module constants;

immutable int SCREEN_X = 1280; // Pixels
immutable int SCREEN_Y = 960; // Pixels

immutable int GRID_X = 16; // Number of grid squares per level
immutable int GRID_Y = 12;

immutable int TILE_SIZE = SCREEN_X / GRID_X;
immutable float PIXEL_WIDTH = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f;
