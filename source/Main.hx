package;

import flixel.FlxGame;

class Main extends FlxGame
{
	public function new()
	{
		super(800, 600, PlayState, 60, 60, true, false);
	}
}
