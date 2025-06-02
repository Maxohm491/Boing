// Sourced with modifications from the class github at 06_gameobject/full_component/gameobject.d
module Engine.gameobject;

import core.atomic;
import std.stdio;
import std.conv;

import bindbc.sdl;

import scripts;
import Engine.component;
import Engine.tilemapcomponents;

class GameObject
{
	static GameObject GetGameObject(string name)
	{
		if (name in sGameObjects)
		{
			return sGameObjects[name];
		}
		assert(0, "Game object '" ~ name ~ "' does not exist");
	}

	static GameObject[string] sGameObjects;

	// Constructor
	this(string name)
	{
		assert(name.length > 0);
		mName = name;
		// atomic increment of number of game objects
		sGameObjectCount.atomicOp!"+="(1);

		sGameObjects[name] = this;

		mID = sGameObjectCount;
		alive = true;
	}

	string GetName() const
	{
		return mName;
	}

	size_t GetID() const
	{
		return mID;
	}

	void Update()
	{
		// Update script. A gameobject can only have one in this engine.
		auto script = this.GetComponent(ComponentType.SCRIPT);
		if (script !is null)
			(cast(ScriptComponent) script).Update();

		// Update collider
		auto collider = this.GetComponent(ComponentType.COLLIDER);
		if (collider !is null)
			(cast(ColliderComponent) collider).Update();
	}

	void Input(SDL_Event event)
	{
		// Update input component
		auto input = this.GetComponent(ComponentType.INPUT);
		if (input !is null)
			(cast(InputComponent) input).Input(event);
	}

	void Render()
	{
		// Render all sprites
		auto stat_sprite = this.GetComponent(ComponentType.SPRITE);
		if (stat_sprite !is null)
		{
			(cast(SpriteComponent) stat_sprite).Render();
		}

		// Render all tilemap sprites
		auto tile_sprite = this.GetComponent(ComponentType.TILEMAP_SPRITE);
		if (tile_sprite !is null)
		{
			(cast(TilemapSprite) tile_sprite).Render();
		}
	}

	// Retrieve specific component type
	IComponent GetComponent(ComponentType type)
	{
		if (type in mComponents)
		{
			return mComponents[type];
		}
		else
		{
			return null;
		}
	}

	// Template parameter
	void AddComponent(ComponentType T)(IComponent component)
	{
		mComponents[T] = component;
	}

	bool alive = true;

	// Common components for all game objects
	IComponent[ComponentType] mComponents;

	// Any private fields that make up the game object
	string mName;
	size_t mID;

	static shared size_t sGameObjectCount = 0;
}

// Meta-programming to generate factories for creating game objects
// See: https://dlang.org/articles/variadic-function-templates.html
// CAUTION: Each new ordering of components will instantiate a new type.
// 					I'd thus recommend 'sorting' the variadic arguments. That takes
//          a little bit more work, and I'll leave as an exercise until someone asks..
GameObject GameObjectFactory(T...)(string name)
{
	// Create our game object
	GameObject go = new GameObject(name);
	// Static foreach loop will be 'unrolled' with
	// each 'if' condition for what is true.
	// This could also handle the case where we repeat component types as well if our
	// game object supports multiple components of the same type.
	static foreach (component; T)
	{
		static if (component == ComponentType.TEXTURE)
		{
			go.AddComponent!(component)(new TextureComponent(go));
		}
		static if (component == ComponentType.TRANSFORM)
		{
			go.AddComponent!(component)(new TransformComponent(go));
		}
		static if (component == ComponentType.COLLIDER)
		{
			go.AddComponent!(component)(new ColliderComponent(go));
		}
		static if (component == ComponentType.SPRITE)
		{
			go.AddComponent!(component)(new SpriteComponent(go));
		}
		static if (component == ComponentType.TILEMAP_SPRITE)
		{
			go.AddComponent!(component)(new TilemapSprite(go));
		}
		static if (component == ComponentType.TILEMAP_COLLIDER)
		{
			go.AddComponent!(component)(new TilemapCollider(go));
		}
	}
	return go;
}

// Example of an alias to make our GameObjectFactory a bit more clean.
alias MakeSprite = GameObjectFactory!(ComponentType
		.TRANSFORM, ComponentType.TEXTURE, ComponentType.COLLIDER, ComponentType.SPRITE);
alias MakeCollider = GameObjectFactory!(ComponentType
		.TRANSFORM, ComponentType.COLLIDER);
alias MakeTransform = GameObjectFactory!(ComponentType
		.TRANSFORM);
