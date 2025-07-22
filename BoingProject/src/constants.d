module constants;

// immutable int SCREEN_X = 1920; // screen pixels
// immutable int SCREEN_Y = 1080; 
immutable int SCREEN_X = 1280; // screen pixels
immutable int SCREEN_Y = 720; // screen pixels

immutable float SCALE_FROM_720 = cast(float) SCREEN_Y / 720.0f; // Scale factor from 720p to current resolution

immutable int GRID_X = 40; // Number of tiles on screen at a time 
immutable int GRID_Y = 23;

immutable int PIXELS_PER_TILE = 8; // Pixels per tile

immutable int TILE_SIZE = SCREEN_X / GRID_X;
immutable float PIXEL_WIDTH = (cast(float) SCREEN_X / cast(float) GRID_X) / PIXELS_PER_TILE;
