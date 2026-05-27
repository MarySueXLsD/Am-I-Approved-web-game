package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

class MonitorConfirmDialog extends FlxGroup
{
	var overlay:FlxSprite;
	var panel:FlxSprite;
	var message:FlxText;
	var confirmBtn:FlxSprite;
	var cancelBtn:FlxSprite;
	var confirmLabel:FlxText;
	var cancelLabel:FlxText;
	var btnW = 0;
	var btnH = 0;
	var fontSize = 12;
	var onConfirm:Void->Void;
	var onCancel:Void->Void;

	public function new()
	{
		super();
		overlay = new FlxSprite();
		panel = new FlxSprite();
		message = new FlxText(0, 0, 100, "");
		confirmBtn = new FlxSprite();
		cancelBtn = new FlxSprite();
		confirmLabel = new FlxText(0, 0, 80, "CONFIRM");
		cancelLabel = new FlxText(0, 0, 80, "CANCEL");

		add(overlay);
		add(panel);
		add(message);
		add(confirmBtn);
		add(cancelBtn);
		add(confirmLabel);
		add(cancelLabel);

		visible = false;
	}

	public function isOpen():Bool
	{
		return visible;
	}

	public function show(areaX:Float, areaY:Float, areaW:Float, areaH:Float, propertyLabel:String, oldValue:String,
			newValue:String, confirm:Void->Void, cancel:Void->Void):Void
	{
		onConfirm = confirm;
		onCancel = cancel;
		fontSize = Std.int(Math.max(11, areaH / 28));
		btnH = fontSize + 10;
		btnW = Std.int(Math.max(72, areaW * 0.28));

		overlay.setPosition(areaX, areaY);
		overlay.makeGraphic(Std.int(areaW), Std.int(areaH), 0xAA000000, true);
		overlay.updateHitbox();

		var panelW = Std.int(Math.min(areaW - 16, 360));
		var panelH = Std.int(Math.min(areaH - 16, 150));
		var panelX = areaX + (areaW - panelW) * 0.5;
		var panelY = areaY + (areaH - panelH) * 0.5;

		panel.setPosition(panelX, panelY);
		panel.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(panel, panelW, panelH, MonitorScreenUi.GREEN, 1);
		panel.updateHitbox();

		var pad = 10;
		var msgW = panelW - pad * 2;
		message.text = 'Are you sure you want to change ${propertyLabel}\nfrom "${oldValue}"\nto "${newValue}"?';
		message.setFormat(null, fontSize, MonitorScreenUi.GREEN, "center");
		message.fieldWidth = msgW;
		message.scale.set(1, 1);
		message.setPosition(panelX + pad, panelY + pad);

		var btnY = panelY + panelH - pad - btnH;
		var gap = 8;
		var totalBtnW = btnW * 2 + gap;
		var btnStartX = panelX + (panelW - totalBtnW) * 0.5;

		layoutBtn(confirmBtn, confirmLabel, btnStartX, btnY, btnW, btnH, "CONFIRM");
		layoutBtn(cancelBtn, cancelLabel, btnStartX + btnW + gap, btnY, btnW, btnH, "CANCEL");

		visible = true;
	}

	public function showWarning(areaX:Float, areaY:Float, areaW:Float, areaH:Float, warningText:String,
			dismiss:Void->Void):Void
	{
		onConfirm = dismiss;
		onCancel = null;
		fontSize = Std.int(Math.max(11, areaH / 28));
		btnH = fontSize + 10;
		btnW = Std.int(Math.max(72, areaW * 0.28));

		overlay.setPosition(areaX, areaY);
		overlay.makeGraphic(Std.int(areaW), Std.int(areaH), 0xAA000000, true);
		overlay.updateHitbox();

		var panelW = Std.int(Math.min(areaW - 16, 360));
		var panelH = Std.int(Math.min(areaH - 16, 130));
		var panelX = areaX + (areaW - panelW) * 0.5;
		var panelY = areaY + (areaH - panelH) * 0.5;

		panel.setPosition(panelX, panelY);
		panel.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(panel, panelW, panelH, MonitorScreenUi.GREEN, 1);
		panel.updateHitbox();

		var pad = 10;
		var msgW = panelW - pad * 2;
		message.text = warningText;
		message.setFormat(null, fontSize, MonitorScreenUi.GREEN, "center");
		message.fieldWidth = msgW;
		message.scale.set(1, 1);
		message.setPosition(panelX + pad, panelY + pad);

		var btnY = panelY + panelH - pad - btnH;
		var btnStartX = panelX + (panelW - btnW) * 0.5;

		layoutBtn(confirmBtn, confirmLabel, btnStartX, btnY, btnW, btnH, "OK");
		cancelBtn.visible = false;
		cancelLabel.visible = false;

		visible = true;
	}

	public function handleKey(keyCode:Int):Bool
	{
		if (!visible)
			return false;

		if (keyCode == Keyboard.ENTER)
		{
			var cb = onConfirm;
			close();
			if (cb != null)
				cb();
			return true;
		}

		if (keyCode == Keyboard.ESCAPE && cancelBtn.visible && onCancel != null)
		{
			var cb = onCancel;
			close();
			if (cb != null)
				cb();
			return true;
		}

		return false;
	}

	public function handleClick(mx:Float, my:Float):Bool
	{
		if (!visible)
			return false;

		if (confirmBtn.overlapsPoint(new FlxPoint(mx, my)))
		{
			var cb = onConfirm;
			close();
			if (cb != null)
				cb();
			return true;
		}

		if (cancelBtn.visible && cancelBtn.overlapsPoint(new FlxPoint(mx, my)))
		{
			var cb = onCancel;
			close();
			if (cb != null)
				cb();
			return true;
		}

		return overlay.overlapsPoint(new FlxPoint(mx, my));
	}

	public function close():Void
	{
		visible = false;
		onConfirm = null;
		onCancel = null;
		cancelBtn.visible = true;
		cancelLabel.visible = true;
	}

	function layoutBtn(btn:FlxSprite, label:FlxText, x:Float, y:Float, w:Int, h:Int, text:String):Void
	{
		btn.setPosition(x, y);
		btn.makeGraphic(w, h, 0xFF0D1A12, true);
		drawRectBorder(btn, w, h, MonitorScreenUi.GREEN_DIM, 1);
		btn.updateHitbox();

		label.text = text;
		label.setFormat(null, fontSize, MonitorScreenUi.GREEN, "center");
		label.fieldWidth = w;
		label.scale.set(1, 1);
		label.setPosition(x, y + (h - fontSize) * 0.5);
		label.visible = true;
	}

	function drawRectBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}
}
