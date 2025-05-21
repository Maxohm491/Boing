// Sourced with modifications from the class github at 06_gameobject/full_component/component.d
module GameCode.component;

import std.stdio;
import GameCode.scene;
import std.algorithm;
import std.array;
import std.json;
import bindbc.sdl;
import GameCode.gameobject;
import GameCode.resourcemanager;
import std.math;
import constants;
import linear;

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
	string[] mCollisions;

	this(GameObject owner) {
		mOwner = owner;
		mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
	}

	void Update() {
		// Round posittion to a pixel
		// 8 pixels/tile
		float pixelWidth = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f;
		rect.x = cast(int)(round(mTransformRef.x / pixelWidth) * pixelWidth) + offset.x;
		rect.y = cast(int)(round(mTransformRef.y / pixelWidth) * pixelWidth) + offset.y;
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

	SDL_Rect mRect;
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
				newFrame.mDuration = 25;
				mFrames ~= newFrame;
			}
		}

		// Parse "frames" into the associative array
		foreach (animName; json["frames"].object.keys) {
			// Funny one liner
			long[] sequence = json["frames"][animName].array.map!(a => a.integer).array;
			mFrameNumbers[animName] = sequence;

			// Set default animation to a random one (useful if there's just one)
			mCurrentAnimationName = animName;
		}
	}

	void SetAnimation(string name) {
		if (name in mFrameNumbers) {
			mCurrentAnimationName = name;
		} else {
			assert(0, "Animation name not found");
		}
	}

	void Render() {
		// Round posittion to a pixel
		// 8 pixels/tile
		float pixelWidth = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f;
		Vec2f screenPos = mTransformRef.GetScreenPos();
		SDL_Rect drawRect = SDL_Rect(0, 0, 0, 0);
		drawRect.x = cast(int)(round(screenPos.x / pixelWidth) * pixelWidth);
		drawRect.y = cast(int)(round(screenPos.y / pixelWidth) * pixelWidth);
		drawRect.w = cast(int)(round((mTransformRef.GetScreenScale().x * mRect.w) / pixelWidth) * pixelWidth);
		drawRect.h = cast(int)(round((mTransformRef.GetScreenScale().y * mRect.w) / pixelWidth) * pixelWidth);
		// mRect.x = cast(int)(round(mTransformRef.x / pixelWidth) * pixelWidth);
		// mRect.y = cast(int)(round(mTransformRef.y / pixelWidth) * pixelWidth);

		if (mFrames.length > 0) {
			Frame frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
			mCurrentFrameDuration += 1;

			if (mCurrentFrameDuration > frame.mDuration) {
				mCurrentFrameDuration = 0;
				mCurrentFrameIndex = (mCurrentFrameIndex + 1) % mFrameNumbers[mCurrentAnimationName]
					.length;
				frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
			}

			SDL_RenderCopyEx(mRendererRef, mTextureRef, &(frame.mRect), &(drawRect), 0, null,
				flipped ? SDL_RendererFlip.SDL_FLIP_HORIZONTAL : SDL_RendererFlip
					.SDL_FLIP_NONE);
		} else {
			SDL_RenderCopyEx(mRendererRef, mTextureRef, null, &(drawRect), 0, null, flipped ? SDL_RendererFlip.SDL_FLIP_HORIZONTAL
					: SDL_RendererFlip
					.SDL_FLIP_NONE);
		}
	}
}

class InputComponent : IComponent {
	// Input
	bool leftPressed = false;
	bool rightPressed = false;
	bool upPressed = false;

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
			break;
		case SDL_KEYUP:
			auto key = event.key.keysym.sym;
			if (key == SDLK_a || key == SDLK_LEFT)
				leftPressed = false;
			else if (key == SDLK_d || key == SDLK_RIGHT)
				rightPressed = false;
			else if (key == SDLK_w || key == SDLK_UP || key == SDLK_SPACE)
				upPressed = false;
			break;
		default:
			break;
		}
	}
}

class TransformComponent : IComponent {
	this(GameObject owner) {
		mOwner = owner;
	}

	@property float x() {
        return mWorldMatrix.e[0][2];
    }

	@property float y() {
        return mWorldMatrix.e[1][2];
    }

	@property void x(float value) {
        mWorldMatrix.e[0][2] = value;
    }

	@property void y(float value) {
        mWorldMatrix.e[1][2] = value;
    }

	void Translate(float x, float y) {
		mWorldMatrix = mWorldMatrix * MakeTranslate(x, y);
	}

	void SetPos(float x, float y) {
		mWorldMatrix = MakeTranslate(x, y);
	}

	// Note scale is only for visual effects
	void Scale(float x, float y)
	{
		mWorldMatrix = mWorldMatrix * MakeScale(x, y);
	}

	Vec2f GetScreenScale() {
		return mScreenMatrix.Frommat3GetScale();
	}

	Vec2f GetScreenPos() {
		return mScreenMatrix.Frommat3GetTranslation();
	}

	mat3 mScreenMatrix;
	mat3 mWorldMatrix;
}
