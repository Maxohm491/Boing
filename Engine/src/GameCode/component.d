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

enum ComponentType
{
	TEXTURE,
	TRANSFORM,
	SPRITE,
	SCRIPT,
	INPUT,
	TILEMAP_SPRITE,
	TILEMAP_COLLIDER,
	COLLIDER
}

abstract class IComponent
{
	GameObject mOwner;
}

class TextureComponent : IComponent
{
	SDL_Texture* mTexture;
	alias mTexture this;

	this(GameObject owner)
	{
		mOwner = owner;
	}

	void LoadTexture(string filename, SDL_Renderer* r)
	{
		mTexture = ResourceManager.GetInstance().LoadImageResource(filename, r);
	}
}

// Collider
class ColliderComponent : IComponent
{
	TransformComponent mTransformRef;
	SDL_Rect mRect;
	string[] mCollisions;

	this(GameObject owner)
	{
		mOwner = owner;
		mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
	}

	void Update()
	{
		// Round posittion to a pixel
		// 8 pixels/tile
		float pixelWidth = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f; 
		mRect.x = cast(int) (round(mTransformRef.x / pixelWidth) * pixelWidth);
		mRect.y = cast(int) (round(mTransformRef.y / pixelWidth) * pixelWidth);
	}

	// Recursively check all collidables
	string[] CheckCollisions(GameObject[] toCheck)
	{
		string[] toReturn;
		// check for actual intersection
		foreach (obj; toCheck)
		{
			auto collider = obj.GetComponent(ComponentType.COLLIDER);
			if (collider !is null)
			{
				if (obj.GetID() != mOwner.GetID() &&
					SDL_HasIntersection(&((cast(ColliderComponent) collider)
						.mRect), &(mRect)))
				{
					toReturn ~= obj.GetName();
				}
			}
		}
		mCollisions = toReturn;

		return toReturn;
	}

	/// Return names of gameobjects that the collider has collided with since last frame
	string[] GetCollisions()
	{
		return mCollisions;
	}
}

/// Store a series of frames and multiple animation sequences that can be played
class SpriteComponent : IComponent
{
	/// Store an individual Frame for an animation
	struct Frame
	{
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

	/// Hold a copy of the texture that is referenced
	this(GameObject owner)
	{
		mOwner = owner;
		mTextureRef = cast(TextureComponent) mOwner.GetComponent(ComponentType.TEXTURE);
		mTransformRef = cast(TransformComponent) mOwner.GetComponent(ComponentType.TRANSFORM);
	}

	/// Load a data file that describes meta-data about animations stored in a single file.
	void LoadMetaData(string filename)
	{
		auto jsonString = File(filename, "r").byLine.joiner("\n");
		auto json = parseJSON(jsonString);
		auto formatJson = json["format"];

		// Fill mFrames:
		for (auto topBound = 0; topBound < formatJson["height"].integer; topBound += formatJson["tileHeight"]
			.integer)
		{
			for (auto leftBound = 0; leftBound < formatJson["width"].integer; leftBound += formatJson["tileWidth"]
				.integer)
			{
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
		foreach (animName; json["frames"].object.keys)
		{
			// Funny one liner
			long[] sequence = json["frames"][animName].array.map!(a => a.integer).array;
			mFrameNumbers[animName] = sequence;

			// Set default animation to a random one (useful if there's just one)
			mCurrentAnimationName = animName;
		}
	}

	void SetAnimation(string name)
	{
		if (name in mFrameNumbers)
		{
			mCurrentAnimationName = name;
		}
		else
		{
			assert(0, "Animation name not found");
		}
	}

	void Render()
	{
		Frame frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
		mCurrentFrameDuration += 1;

		if (mCurrentFrameDuration > frame.mDuration)
		{
			mCurrentFrameDuration = 0;
			mCurrentFrameIndex = (mCurrentFrameIndex + 1) % mFrameNumbers[mCurrentAnimationName]
				.length;
			frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFrameIndex]];
		}

		// Round posittion to a pixel
		// 8 pixels/tile
		float pixelWidth = (cast(float) SCREEN_X / cast(float) GRID_X) / 8f; 
		mRect.x = cast(int) (round(mTransformRef.x / pixelWidth) * pixelWidth);
		mRect.y = cast(int) (round(mTransformRef.y / pixelWidth) * pixelWidth);

		SDL_RenderCopyEx(mRendererRef, mTextureRef, &(frame.mRect), &(mRect), mTransformRef.GetAngle() * (180.0 / PI), null, SDL_RendererFlip
				.SDL_FLIP_NONE);
	}
}

class InputComponent : IComponent
{
	// Input
	bool leftPressed = false;
	bool rightPressed = false;
	bool upPressed = false;

	this(GameObject owner)
	{
		mOwner = owner;
	}

	/// Returns -1 for left, 1 for right, 0 otherwise
	int GetDir()
	{
		if (leftPressed && !rightPressed)
		{
			return -1;
		}
		if (rightPressed && !leftPressed)
		{
			return 1;
		}
		return 0;
	}

	void Input(SDL_Event event)
	{
		switch (event.type)
		{
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

class TransformComponent : IComponent
{
	this(GameObject owner)
	{
		mOwner = owner;
	}

	// Translate
	void Translate(float x, float y)
	{
		this.x += x;
		this.y += y;
	}

	void SetPos(float x, float y)
	{
		this.x = x;
		this.y = y;
	}

	// Rotate 
	void Rotate(float angle)
	{
		rotation += angle;
	}

	float GetAngle()
	{
		return rotation;
	}

	float x = 0, y = 0, rotation = 0; 
}
