package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class PlayState extends FlxState
{
	var zones:LayoutZones;
	var documents:FlxGroup;
	var passport:Passport;
	var idDocument:IdDocument;
	var magnifyingGlass:MagnifyingGlass;
	var monitor:MonitorOverlay;

	static inline var LEFT_COL_RATIO:Float = 0.3;
	static inline var CLIENT_H_RATIO:Float = 0.4;
	static inline var CLIENT_TABLE_H_RATIO:Float = 0.25;
	static inline var WINDOW_H_RATIO:Float = 0.15;

	override function create():Void
	{
		super.create();
		DebugOverlay.init();
		#if FLX_DEBUG
		if (Lib.current.stage != null)
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onDebugKeyUp);
		#end
		buildLayout();
	}

	#if FLX_DEBUG
	function onDebugKeyUp(e:KeyboardEvent):Void
	{
		DebugOverlay.handleKeyUp(e);
	}
	#end

	function buildLayout():Void
	{
		var screenW = FlxG.width;
		var screenH = FlxG.height;
		var sep = Std.int(Math.max(2, screenH / 300));

		var leftW = Std.int(screenW * LEFT_COL_RATIO);
		var clientH = Std.int(screenH * CLIENT_H_RATIO);
		var clientTableY = clientH;
		var clientTableH = Std.int(screenH * CLIENT_TABLE_H_RATIO);
		var computerY = clientTableY + clientTableH;
		var computerH = screenH - computerY;

		var employerX = leftW;
		var employerW = screenW - leftW;
		var windowH = Std.int(screenH * WINDOW_H_RATIO);
		var employerTableY = windowH;
		var employerTableH = screenH - employerTableY;

		var client = new LayoutPanel(0, 0, leftW, clientH, "Client", FlxColor.fromRGB(42, 58, 74));
		add(client);

		var clientWall = new FlxSprite(0, 0);
		clientWall.loadGraphic("static/wall.webp");
		clientWall.setGraphicSize(leftW, clientH);
		clientWall.updateHitbox();
		add(clientWall);

		var clientImg = new FlxSprite(0, 0);
		clientImg.loadGraphic("static/client.png");
		var clientScale = leftW / clientImg.frameWidth;
		clientImg.scale.set(clientScale, clientScale);
		clientImg.updateHitbox();
		clientImg.x = (leftW - clientImg.width) / 2;
		clientImg.y = clientH - clientImg.height;
		add(clientImg);

		var clientTable = new LayoutPanel(0, clientTableY, leftW, clientTableH, "Client's table", FlxColor.fromRGB(52, 68, 84));
		add(clientTable);

		var clientTableImg = new FlxSprite(0, clientTableY);
		clientTableImg.loadGraphic("static/table.png");
		clientTableImg.setGraphicSize(leftW, clientTableH);
		clientTableImg.updateHitbox();
		add(clientTableImg);

		var computer = new LayoutPanel(0, computerY, leftW, computerH, "Computer", FlxColor.fromRGB(44, 54, 68));
		add(computer);

		var hudFont = Std.int(Math.max(7, FlxG.height / 72));
		var hudBottomPad = Std.int(Math.max(6, FlxG.height / 80));
		var computerHudH = hudFont + 4 + hudBottomPad + 2;
		if (computerHudH >= computerH)
			computerHudH = computerH - 1;
		var computerImgH = computerH - computerHudH;
		if (computerImgH < 1)
			computerImgH = 1;

		var computerTable = new FlxSprite(0, computerY);
		computerTable.loadGraphic("static/computer_table.jpg");
		computerTable.setGraphicSize(leftW, computerImgH);
		computerTable.updateHitbox();
		add(computerTable);

		var computerImg = new FlxSprite(0, computerY);
		computerImg.loadGraphic("static/computer.png");
		computerImg.setGraphicSize(leftW, computerImgH);
		computerImg.updateHitbox();
		add(computerImg);

		var computerHud = new ComputerHud(0, computerY + computerImgH, leftW, computerHudH);
		add(computerHud);

		var window = new LayoutPanel(employerX, 0, employerW, windowH, "Window", FlxColor.fromRGB(48, 58, 72));
		add(window);

		var windowImg = new FlxSprite(employerX, 0);
		windowImg.loadGraphic("static/window.webp");
		windowImg.setGraphicSize(employerW, windowH);
		windowImg.updateHitbox();
		add(windowImg);

		var employerTable = new LayoutPanel(employerX, employerTableY, employerW, employerTableH, "Employer's table", FlxColor.fromRGB(32, 48, 62));
		add(employerTable);

		var employerTableTiles = createTiledSprite("static/employers_table.png", employerX, employerTableY, employerW, employerTableH);
		add(employerTableTiles);

		addSeparator(0, clientH, leftW, sep);
		addSeparator(0, computerY, leftW, sep);
		addSeparator(employerX - sep, 0, sep, screenH);
		addSeparator(employerX, windowH, employerW, sep);

		zones = {
			leftW: leftW,
			clientH: clientH,
			clientTableY: clientTableY,
			clientTableH: clientTableH,
			computerY: computerY,
			computerH: computerH,
			employerX: employerX,
			employerW: employerW,
			windowH: windowH,
			employerTableY: employerTableY,
			employerTableH: employerTableH
		};
		documents = new FlxGroup();
		passport = new Passport(zones, documents);
		idDocument = new IdDocument(zones, documents);
		idDocument.placeBeside(passport);
		magnifyingGlass = new MagnifyingGlass(zones, documents);
		magnifyingGlass.placeBeside(idDocument);
		documents.add(passport);
		documents.add(idDocument);
		documents.add(magnifyingGlass);
		add(documents);

		var lc = magnifyingGlass.lensCam;
		if (lc != null)
		{
			employerTable.cameras = [FlxG.camera, lc];
			employerTableTiles.cameras = [FlxG.camera, lc];
			passport.cameras = [FlxG.camera, lc];
			idDocument.cameras = [FlxG.camera, lc];
		}

		CitizenRegistry.load();
		if (CitizenRegistry.all.length > 0)
			passport.setCitizen(CitizenRegistry.all[0]);

		monitor = new MonitorOverlay();
		add(monitor);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		magnifyingGlass.setHidden(monitor.isShowing);

		var p = FlxG.mouse.getViewPosition();

		if (monitor.isShowing)
		{
			if (!monitor.isBusy)
				monitor.updateScreenInput(p);

			if (FlxG.mouse.justReleased)
				monitor.handleScreenRelease();

			if (monitor.isBusy)
				return;

			if (FlxG.mouse.justPressed)
			{
				if (monitor.containsInteractivePoint(p))
				{
					monitor.handleScreenClick(p);
					return;
				}
				monitor.hide();
			}
			return;
		}

		if (!FlxG.mouse.justPressed)
			return;

		if (!isComputerZoneClick() || isDocumentAtMouse())
			return;

		monitor.show();
	}

	function isComputerZoneClick():Bool
	{
		var p = FlxG.mouse.getViewPosition();
		return p.x >= 0 && p.x < zones.leftW && p.y >= zones.computerY && p.y < zones.computerY + zones.computerH;
	}

	function isDocumentAtMouse():Bool
	{
		var p = FlxG.mouse.getViewPosition();
		for (member in documents.members)
		{
			if (member == null)
				continue;
			var doc:DeskDocument = Std.downcast(member, DeskDocument);
			if (doc != null && doc.hitsPoint(p))
				return true;
		}
		return false;
	}

	function createTiledSprite(path:String, x:Int, y:Int, w:Int, h:Int):FlxSprite
	{
		var sample = new FlxSprite();
		sample.loadGraphic(path);
		var tileW = sample.frameWidth;
		var tileH = sample.frameHeight;
		var tilePixels = sample.pixels;

		var bg = new FlxSprite(x, y);
		bg.makeGraphic(w, h, FlxColor.TRANSPARENT, true);

		var destY = 0;
		while (destY < h)
		{
			var destX = 0;
			while (destX < w)
			{
				var copyW = Std.int(Math.min(tileW, w - destX));
				var copyH = Std.int(Math.min(tileH, h - destY));
				bg.pixels.copyPixels(tilePixels, new Rectangle(0, 0, copyW, copyH), new Point(destX, destY));
				destX += tileW;
			}
			destY += tileH;
		}
		bg.dirty = true;
		return bg;
	}

	function addSeparator(x:Int, y:Int, w:Int, h:Int):Void
	{
		var line = new LayoutPanel(x, y, w, h, "", FlxColor.fromRGB(120, 130, 145), FlxColor.fromRGB(120, 130, 145));
		add(line);
	}
}
