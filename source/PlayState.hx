package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
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

	var clientImg:FlxSprite;
	var clientFinalX:Float;
	var clientFinalY:Float;
	var clientAnimPhase:Int = 0;
	var clientAnimTimer:Float = 0;
	var clientBobOffset:Float = 0;

	static inline var LEFT_COL_RATIO:Float = 0.3;
	static inline var CLIENT_H_RATIO:Float = 0.4;
	static inline var CLIENT_TABLE_H_RATIO:Float = 0.25;
	static inline var WINDOW_H_RATIO:Float = 0.20;

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
		clientWall.loadGraphic("static/wall.png");
		clientWall.setGraphicSize(leftW, clientH);
		clientWall.updateHitbox();
		add(clientWall);

		clientImg = new FlxSprite(0, 0);
		clientImg.loadGraphic("static/client.png");
		var clientScale = (leftW * 0.75) / clientImg.frameWidth;
		clientImg.scale.set(clientScale, clientScale);
		clientImg.updateHitbox();
		clientFinalX = (leftW - clientImg.width) / 2;
		clientFinalY = clientH - clientImg.height + CLIENT_BOB_AMPLITUDE;
		clientImg.x = -clientImg.width;
		clientImg.y = clientFinalY;
		clientImg.color = FlxColor.BLACK;
		clientAnimPhase = 1;
		clientAnimTimer = 0;
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
		computerTable.loadGraphic("static/computer_table.png");
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
		windowImg.loadGraphic("static/window.png");
		windowImg.setGraphicSize(employerW, windowH);
		windowImg.updateHitbox();
		add(windowImg);

		var employerTable = new LayoutPanel(employerX, employerTableY, employerW, employerTableH, "Employer's table", FlxColor.fromRGB(32, 48, 62));
		add(employerTable);

		var employerTableTiles = createTiledSprite("static/employers_table.png", employerX, employerTableY, employerW, employerTableH);
		add(employerTableTiles);

		var dotGrid = createDotGrid(employerX, employerTableY, employerW, employerTableH);
		add(dotGrid);


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
		var cc = magnifyingGlass.coverCam;
		if (lc != null)
		{
			employerTable.cameras = [FlxG.camera, lc];
			employerTableTiles.cameras = [FlxG.camera, lc];
			dotGrid.cameras = [FlxG.camera, lc];
			passport.cameras = [FlxG.camera, lc];
			idDocument.cameras = [FlxG.camera, lc];
		}
		if (cc != null)
		{
			client.cameras = [FlxG.camera, cc];
			clientWall.cameras = [FlxG.camera, cc];
			clientImg.cameras = [FlxG.camera, cc];
			clientTable.cameras = [FlxG.camera, cc];
			clientTableImg.cameras = [FlxG.camera, cc];
			computer.cameras = [FlxG.camera, cc];
			computerTable.cameras = [FlxG.camera, cc];
			computerImg.cameras = [FlxG.camera, cc];
			computerHud.cameras = [FlxG.camera, cc];
			window.cameras = [FlxG.camera, cc];
			windowImg.cameras = [FlxG.camera, cc];
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
		updateClientEntrance(elapsed);
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

	static inline var CLIENT_WALK_DURATION:Float = 1.1;
	static inline var CLIENT_REVEAL_DURATION:Float = 0.5;
	static inline var CLIENT_BOB_SPEED:Float = 6.0;
	static inline var CLIENT_BOB_AMPLITUDE:Float = 4.0;

	function updateClientEntrance(elapsed:Float):Void
	{
		if (clientAnimPhase == 0)
			return;

		clientAnimTimer += elapsed;

		if (clientAnimPhase == 1)
		{
			var t = Math.min(clientAnimTimer / CLIENT_WALK_DURATION, 1.0);
			var eased = FlxEase.quadOut(t);
			clientImg.x = -clientImg.width + (clientFinalX + clientImg.width) * eased;

			clientBobOffset += elapsed * CLIENT_BOB_SPEED;
			clientImg.y = clientFinalY + Math.sin(clientBobOffset) * CLIENT_BOB_AMPLITUDE;

			if (t >= 1.0)
			{
				clientImg.x = clientFinalX;
				clientImg.y = clientFinalY;
				clientAnimPhase = 2;
				clientAnimTimer = 0;
			}
		}
		else if (clientAnimPhase == 2)
		{
			var t = Math.min(clientAnimTimer / CLIENT_REVEAL_DURATION, 1.0);
			var eased = FlxEase.sineOut(t);
			var c = Std.int(eased * 255);
			clientImg.color = FlxColor.fromRGB(c, c, c);

			if (t >= 1.0)
			{
				clientImg.color = FlxColor.WHITE;
				clientAnimPhase = 0;
			}
		}
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

	function createDotGrid(x:Int, y:Int, w:Int, h:Int):FlxSprite
	{
		var dotSpacing = Std.int(Math.max(20, FlxG.height / 30));
		var dotRadius = Std.int(Math.max(1, dotSpacing / 14));
		var dotColor:Int = 0x40FFFFFF;

		var spr = new FlxSprite(x, y);
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		var bmd = spr.pixels;

		var py = dotSpacing;
		while (py < h)
		{
			var px = dotSpacing;
			while (px < w)
			{
				for (dy in -dotRadius...dotRadius + 1)
				{
					for (dx in -dotRadius...dotRadius + 1)
					{
						if (dx * dx + dy * dy <= dotRadius * dotRadius)
						{
							var drawX = px + dx;
							var drawY = py + dy;
							if (drawX >= 0 && drawX < w && drawY >= 0 && drawY < h)
								bmd.setPixel32(drawX, drawY, dotColor);
						}
					}
				}
				px += dotSpacing;
			}
			py += dotSpacing;
		}

		spr.dirty = true;
		return spr;
	}

	function addSeparator(x:Int, y:Int, w:Int, h:Int):Void
	{
		var line = new LayoutPanel(x, y, w, h, "", FlxColor.fromRGB(120, 130, 145), FlxColor.fromRGB(120, 130, 145));
		add(line);
	}
}
