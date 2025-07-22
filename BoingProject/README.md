## Add any additional notes here

SDL_2 must be installed. Enjoy the game!

## Game/Engine Publicity

**Project Website**: [website](https://andrewfu1.github.io/bamn-website/) (See part 3)

## Compilation Instructions

Run the Linux precompiled binary `./compiled_prog` from within `Engine/`!

Alternatvely, build from source and run with `dub` from within `Engine/`.

## Project Hieararchy

In the future, other engineers may take on our project, so we have to keep it organized given the following requirements below. Forming some good organization habits now will help us later on when our project grows as well. These are the required files you should have 

### ./Engine Directory Organization

- docs 
    - Source Code Documentation
- assets
    - Art assets (With the Sub directories music, sound, images, and anything else)
- src
    - source code(.d files) The make file or any build scripts that automate the building of your project should reside here.
- include
    - header files(.di files if needed)
- lib
    - libraries (.so, .dll, .a, .dylib files). Note this is a good place to put SDL
- bin
    - This is the directory where your built executable(.exe for windows, .app for Mac, or a.out for Linux) and any additional generated files are put after each build.


**Note: For the final project you may add additional directories if you like, for example for your game which demonstrates your engine works.** 

**Additional Notes:** 

1. src and include should only contain ".d" or ".di" files. Why? It makes it very fast to do a backup of your game project as one example. Secondly, binary files that are generated often clutter up directories. I should not see any binaries in your repository, you may use a '.gitignore' file to help prevent this automatically. 
