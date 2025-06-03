module constants;

immutable int SCREEN_X = 1280; // screen pixels
immutable int SCREEN_Y = 960; // screen pixels

immutable int GRID_X = 16; // Number of grid squares (tiles) on screen at a time
immutable int GRID_Y = 12;

immutable int PIXELS_PER_TILE = 8; // Pixels per tile

immutable int TILE_SIZE = SCREEN_X / GRID_X;
immutable float PIXEL_WIDTH = (cast(float) SCREEN_X / cast(float) GRID_X) / PIXELS_PER_TILE;
