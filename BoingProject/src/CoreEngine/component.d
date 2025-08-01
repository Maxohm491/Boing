module Engine.component;

import std.stdio;
import Engine.scene;
import std.algorithm;
import std.array;
import std.json;
import bindbc.sdl;
import Engine.gameobject;
import Engine.resourcemanager;
import Engine.tilemapcomponents;
import std.math;
import constants;

enum ComponentType {
	TEXTURE,
	TRANSFORM,
	SPRITE,
	SCRIPT,
	INPUT,
	TILEMAP_SPRITE,
	TILEMAP_COLLIDER,
	COLLIDER
}

abstract class IComponent {
	GameObject mOwner;
}

class TextureComponent : IComponent {
	SDL_Texture* mTexture;
	alias mTexture this;

	this(GameObject owner) {
		mOwner = owner;
	}

	void LoadTexture(string filename, SDL_Renderer* r) {
		mTexture = ResourceManager.GetInstance().LoadImageResource(filename, r);
	}
}

// Collider
class ColliderComponent : IComponent {
	TransformComponent mTransformRef;
	SDL_Rect rect;
	SDL_Point offset;
	ColliderComponent[]* solids;
	GameObject[]* solidObjects; // For checking collisions with other game objects
	TilemapCollider tilemapCollider = null;
	GameObject* tilemap = null;
	bool active = true;
	string[] mCollisions;

	this(GameObject owner) {
		mOwner = owner;
		mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
	}

	void Update() {
		rect.x = mTransformRef.worldPos.x + offset.x;
		rect.y = mTransformRef.worldPos.y + offset.y;
	}

	bool overlaps(ColliderComponent other) {
		return SDL_HasIntersection(&rect, &(other.rect)) != 0;
	}

	bool CollidesWithSolid() {
		if (tilemapCollider is null && tilemap !is null) {
			tilemapCollider = cast(TilemapCollider) tilemap.GetComponent(
				ComponentType.TILEMAP_COLLIDER);
			if (tilemapCollider is null) {
				assert(0, "Tilemap collider not found");
			}
		} else if (tilemap is null) {
			assert(0, "Tilemap not found");
		}

		if (tilemapCollider.CheckRect(&rect)) {
			return true;
		}
		if (solidObjects is null)
			return false;
		foreach (solid; *solidObjects) {
			auto collider = cast(ColliderComponent) solid.GetComponent(ComponentType.COLLIDER);
			if (collider.active && SDL_HasIntersection(&rect, &(collider.rect))) {
				return true;
			}
		}
		return false;
	}

	// Recursively check all collidables
	string[] CheckCollisions(GameObject[] toCheck) {
		string[] toReturn;
		// check for actual intersection
		foreach (obj; toCheck) {
			auto collider = obj.GetComponent(ComponentType.COLLIDER);
			if (collider !is null) {
				if (obj.GetID() != mOwner.GetID() &&
					SDL_HasIntersection(&((cast(ColliderComponent) collider)
						.rect), &(rect))) {
					toReturn ~= obj.GetName();
				}
			}
		}
		mCollisions = toReturn;

		return toReturn;
	}

	/// Return names of gameobjects that the collider has collided with since last frame
	string[] GetCollisions() {
		return mCollisions;
	}
}

/// Store a series of frames and multiple animation sequences that can be played
class SpriteComponent : IComponent {
	/// Store an individual Frame for an animation
	struct Frame {
		SDL_Rect mRect;
		size_t mDuration; // In number of frames
	}

	Frame[] mFrames;
	long[][string] mFrameNumbers; // Map name to frame numbers

	SDL_Renderer* mRendererRef;
	TextureComponent mTextureRef;
	TransformComponent mTransformRef;

	string mCurrentAnimationName; // Which animation is currently playing
	size_t mCurrentFrameDuration = 0; // Frames since start of current animation
	size_t mCurrentFrameIndex = 0; // Index into mFrameNumbers[mCurrentAnimationName]

	bool flipped = false;

	/// Hold a copy of the texture that is referenced
	this(GameObject owner) {
		mOwner = owner;
		mTextureRef = cast(TextureComponent) mOwner.GetComponent(ComponentType.TEXTURE);
		mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
	}

	/// Load a data file that describes meta-data about animations stored in a single file.
	void LoadMetaData(string filename) {
		auto jsonString = File(filename, "r").byLine.joiner("\n");
		auto json = parseJSON(jsonString);
		auto formatJson = json["format"];

		// Fill mFrames:
		for (auto topBound = 0; topBound < formatJson["height"].integer; topBound += formatJson["tileHeight"]
			.integer) {
			for (auto leftBound = 0; leftBound < formatJson["width"].integer; leftBound += formatJson["tileWidth"]
				.integer) {
				Frame newFrame;
				newFrame.mRect.x = leftBound;
				newFrame.mRect.y = topBound;
				newFrame.mRect.w = cast(int) formatJson["tileWidth"].integer;
				newFrame.mRect.h = cast(int) formatJson["tileHeight"].integer;
				newFrame.mDuration = 1; // default length of 1 frame
				mFrames ~= newFrame;
			}
		}

		// Parse "frames" into the associative array
		foreach (animName; json["frames"].object.keys) {
			// Funny one liner
			long[] sequence = json["frames"][animName].array.map!(a => a.integer).array;
			mFrameNumbers[animName] = sequence;

			if("durations" in json.object && animName in json["durations"].object) {
				foreach (i; mFrameNumbers[animName]) {
					mFrames[i].mDuration = json["durations"][animName].integer;
				}
			}

			// Set default animation to a random one (useful if there's just one)
			mCurrentAnimationName = animName;
		}
	}

	void SetAnimation(string name) {
		if (name in mFrameNumbers) {
			mCurrentAnimationName = name;
			mCurrentFrameIndex = 0;
		} else {
			assert(0, "Animation name not found");
		}
	}

	void Render() {
		SDL_Point screenPos = mTransformRef.GetScreenPos();
		SDL_Rect drawRect = SDL_Rect(0, 0, 0, 0);
		drawRect.x = screenPos.x;
		drawRect.y = screenPos.y;

		if (mFrames.length > 0) {
			Frame frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
			mCurrentFrameDuration += 1;

			if (mCurrentFrameDuration > frame.mDuration) {
				mCurrentFrameDuration = 0;
				mCurrentFrameIndex = (mCurrentFrameIndex + 1) % mFrameNumbers[mCurrentAnimationName]
					.length;
				frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
			}

			drawRect.w = cast(int)(frame.mRect.w * PIXEL_WIDTH);
			drawRect.h = cast(int)(frame.mRect.h * PIXEL_WIDTH);

			SDL_RenderCopyEx(mRendererRef, mTextureRef, &(frame.mRect), &(drawRect), 0, null,
				flipped ? SDL_RendererFlip.SDL_FLIP_HORIZONTAL : SDL_RendererFlip
					.SDL_FLIP_NONE);
		} else {
			SDL_RenderCopyEx(mRendererRef, mTextureRef, null, &(drawRect), 0, null, flipped ? SDL_RendererFlip
					.SDL_FLIP_HORIZONTAL : SDL_RendererFlip
					.SDL_FLIP_NONE);
		}
	}
}

class InputComponent : IComponent {
	// Input
	bool leftPressed = false;
	bool rightPressed = false;
	bool upPressed = false;
	bool downPressed = false;
	bool dashPressed = false;
	bool bouncyPressed = false;

	this(GameObject owner) {
		mOwner = owner;
	}

	/// Returns -1 for left, 1 for right, 0 otherwise
	int GetDir() {
		if (leftPressed && !rightPressed) {
			return -1;
		}
		if (rightPressed && !leftPressed) {
			return 1;
		}
		return 0;
	}

	void Input(SDL_Event event) {
		switch (event.type) {
		case SDL_KEYDOWN:
			auto key = event.key.keysym.sym;
			// Should probably be another switch but oh well
			if (key == SDLK_a || key == SDLK_LEFT)
				leftPressed = true;
			else if (key == SDLK_d || key == SDLK_RIGHT)
				rightPressed = true;
			else if (key == SDLK_w || key == SDLK_UP || key == SDLK_SPACE)
				upPressed = true;
			else if (key == SDLK_s || key == SDLK_DOWN)
				downPressed = true;
			else if (key == SDLK_x)
				dashPressed = true;
			else if (key == SDLK_z)
				bouncyPressed = true; 
			break;
		case SDL_KEYUP:
			auto key = event.key.keysym.sym;
			if (key == SDLK_a || key == SDLK_LEFT)
				leftPressed = false;
			else if (key == SDLK_d || key == SDLK_RIGHT)
				rightPressed = false;
			else if (key == SDLK_w || key == SDLK_UP || key == SDLK_SPACE)
				upPressed = false;
			else if (key == SDLK_s || key == SDLK_DOWN)
				downPressed = false;
			else if (key == SDLK_x)
				dashPressed = false;
			else if (key == SDLK_z)
				bouncyPressed = false; 
			break;
		default:
			break;
		}
	}
}

class TransformComponent : IComponent {
	// Rectangle origin at the upper left corner
	SDL_Point screenPos;
	SDL_Point worldPos;
	alias worldPos this;

	this(GameObject owner) {
		mOwner = owner;
	}

	void Translate(int x, int y) {
		worldPos.x += x;
		worldPos.y += y;
	}

	void SetPos(int x, int y) {
		worldPos.x = x;
		worldPos.y = y;
	}

	void UpdateScreenPos(SDL_Point cameraPos) {
		screenPos.x = cast(int)((worldPos.x - cameraPos.x) * PIXEL_WIDTH);
		screenPos.y = cast(int)((worldPos.y - cameraPos.y) * PIXEL_WIDTH);
	}

	SDL_Point GetScreenPos() {
		return screenPos;
	}

}
