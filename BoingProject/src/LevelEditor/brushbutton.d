module LevelEditor.brushbutton;

import bindbc.sdl;
import LevelEditor.UI;

// Select a brush on the left
class BrushButton : Button
{
    int brushType; // The brush type associated with this button (see grid for different values)
    int* brush; // pointer to selected brush
    SDL_Renderer* mRendererRef;
    SDL_Rect background1, background2; // For bordering. Two of them to make a 2px thick border

    /* Constructor: Initializes a new BrushButton with the given brush type and position.
        Params:
         thisBrush = The brush type this button will select when clicked.
         r         = SDL renderer used for drawing.
         brush     = Pointer to the currently selected brush (shared across buttons).
         location  = The position and size of this button on the UI.
    */
    this(int thisBrush, SDL_Renderer* r, int* brush, SDL_Rect location)
    {
        rect = location;
        brushType = thisBrush;
        this.brush = brush;
        onClick = &Clicked;
        onDragOver = &Dragged;
        mRendererRef = r;

        // Create borders slightly larger than the button rect to draw a 2px outline
        background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
        background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
    }

    /// Called when this button is clicked.
    /// Sets the current brush to this button's brush type.
    void Clicked(SDL_Point _)
    {
        *brush = brushType;
    }

    /// No-op: Required for interface, but drag-over doesn't alter state for this button.
    void Dragged(SDL_Point _) { }

    /// Renders this button. If this button's brush type is currently selected,
    /// it draws a red 2-pixel border around it.
    override void Render()
    {
        // If selected, draw a red border
        if (*brush == brushType)
        {
            SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
            SDL_RenderDrawRect(mRendererRef, &background1);
            SDL_RenderDrawRect(mRendererRef, &background2);
            SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        }
    }
}
