package;

import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
#if FLX_DEBUG
import flixel.system.debug.FlxDebugger;
#end

/**
 * Controls the Flixel stats (performance) panel only — hidden by default, toggled with Shift+1.
 */
class DebugOverlay
{
	public static var isStatsVisible(default, null) = false;

	public static function init():Void
	{
		#if FLX_DEBUG
		if (FlxG.game == null || FlxG.game.debugger == null)
			return;

		// Disable Flixel's default F2 / ` / \ toggles so only Shift+1 controls the panel.
		FlxG.debugger.toggleKeys = [];

		hide();
		#end
	}

	public static function hide():Void
	{
		#if FLX_DEBUG
		if (FlxG.game == null || FlxG.game.debugger == null)
			return;

		isStatsVisible = false;
		var dbg = FlxG.game.debugger;

		dbg.stats.stop();
		dbg.stats.visible = false;
		hideAuxWindows(dbg);

		dbg.visible = false;
		FlxG.debugger.visible = false;
		#end
	}

	public static function toggle():Void
	{
		#if FLX_DEBUG
		if (FlxG.game == null || FlxG.game.debugger == null)
			return;

		if (isStatsVisible)
			hide();
		else
			show();
		#end
	}

	public static function handleKeyUp(e:KeyboardEvent):Void
	{
		#if FLX_DEBUG
		if (!e.shiftKey)
			return;

		if (e.keyCode == Keyboard.NUMBER_1 || e.keyCode == 49)
			toggle();
		#end
	}

	#if FLX_DEBUG
	static function show():Void
	{
		isStatsVisible = true;
		var dbg = FlxG.game.debugger;

		hideAuxWindows(dbg);

		dbg.stats.visible = true;
		dbg.stats.start();

		dbg.visible = true;
		FlxG.debugger.visible = true;
	}

	static function hideAuxWindows(dbg:FlxDebugger):Void
	{
		dbg.log.visible = false;
		dbg.watch.visible = false;
		dbg.console.visible = false;
		dbg.bitmapLog.visible = false;
		dbg.interaction.visible = false;
	}
	#end
}
