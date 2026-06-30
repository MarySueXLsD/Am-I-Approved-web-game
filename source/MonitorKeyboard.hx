package;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class MonitorKeyboard
{
	public static function typedCharacter(e:KeyboardEvent):Null<String>
	{
		if (e.keyCode == Keyboard.BACKSPACE || e.keyCode == Keyboard.ESCAPE || e.keyCode == Keyboard.ENTER)
			return null;

		if (e.keyCode == Keyboard.SPACE)
			return " ";

		if (e.charCode >= 33)
			return String.fromCharCode(e.charCode);

		if (e.keyCode >= Keyboard.A && e.keyCode <= Keyboard.Z)
			return String.fromCharCode(e.keyCode + (e.shiftKey ? 0 : 32));

		if (e.keyCode >= Keyboard.NUMBER_0 && e.keyCode <= Keyboard.NUMBER_9)
			return String.fromCharCode(e.keyCode);

		if (e.keyCode >= Keyboard.NUMPAD_0 && e.keyCode <= Keyboard.NUMPAD_9)
			return String.fromCharCode(e.keyCode - Keyboard.NUMPAD_0 + Keyboard.NUMBER_0);

		if (e.keyCode == Keyboard.MINUS || e.keyCode == 109)
			return "-";

		if (e.keyCode == Keyboard.PERIOD || e.keyCode == Keyboard.NUMPAD_DECIMAL)
			return ".";

		return null;
	}

	public static function attach(stage:openfl.display.Stage, handler:KeyboardEvent->Void, attached:Bool):Bool
	{
		if (attached || stage == null)
			return attached;
		stage.addEventListener(KeyboardEvent.KEY_DOWN, handler, false, 0, true);
		return true;
	}

	public static function detach(stage:openfl.display.Stage, handler:KeyboardEvent->Void, attached:Bool):Bool
	{
		if (!attached || stage == null)
			return false;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, handler);
		return false;
	}
}
