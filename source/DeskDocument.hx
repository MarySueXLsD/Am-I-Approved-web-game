package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import openfl.display.BitmapData;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class DeskDocument extends FlxSprite
{
	static inline var SNAP_DURATION = 0.4;

	var zones:LayoutZones;
	var layer:FlxGroup;
	var closedPath:String;
	var openPath:String;
	var customOpenGraphic:BitmapData;
	var openSizeMultiplier:Float;
	var closedDisplayWidth:Float;
	var dragging = false;
	var snapping = false;
	var scanLocked = false;
	var shredLocked = false;
	var snapTween:FlxTween;
	var dragGrabNormX = 0.0;
	var dragGrabNormY = 0.0;
	var isOpen = false;
	var activeZone:Zone = ClientTable;
	public var onDroppedOnPrinter:DeskDocument->Bool;
	public var onDroppedOnShredder:DeskDocument->Bool;
	public static var resolveClientTableLayoutTarget:DeskDocument->{x:Float, y:Float};
	public static var onDrawLayerChanged:DeskDocument->Void;
	public static var onUpdateDragPresentation:DeskDocument->Void;
	public static var isOpenFolderStackUnderDragHover:Void->Bool;
	public static var onLensCamerasSync:DeskDocument->Void;
	public static var onDeskPropsLensSync:Void->Void;
	public static var lensSyncGroups:Array<FlxGroup>;
	public static var onCanStartDrag:DeskDocument->FlxPoint->Bool;
	public static var isTopmostAtPoint:DeskDocument->FlxPoint->Bool;
	public static var frontmostDocumentAtPoint:FlxPoint->DeskDocument;
	public static var magnifierHitsPoint:FlxPoint->Bool;
	public static var isOverDeskPropsAtPoint:FlxPoint->Bool;
	public static var isAboveDrawLayerBlockingPoint:FlxPoint->Bool;
	public static var currentDrag:DeskDocument = null;

	public var loanFolderStorage:LoanFolderDocument = null;
	public var loanFolderPullHost:LoanFolderDocument = null;
	var compactDragPreviewActive = false;
	var compactDragPreviewWasOpen = false;
	var compactDragPreviewScaleX = 1.0;
	var compactDragPreviewScaleY = 1.0;
	var compactDragPreviewAngle = 0.0;

	var useAlphaHitTest = false;
	var alphaThreshold = 20;

	var clientTableAngle = -14.0;
	var employerTableAngle = -6.0;
	var windowAngle = -10.0;
	var clientAngle = -12.0;
	var computerAngle = -12.0;
	var noneAngle = -14.0;

	public function setZoneAngles(clientTable:Float, employerTable:Float, window:Float, client:Float, computer:Float, none:Float):Void
	{
		clientTableAngle = clientTable;
		employerTableAngle = employerTable;
		windowAngle = window;
		clientAngle = client;
		computerAngle = computer;
		noneAngle = none;
		if (!isOpen)
			angle = getAngleForZone(activeZone);
	}

	public function new(zones:LayoutZones, layer:FlxGroup, closedPath:String, openPath:String, openSizeMultiplier:Float = 9.0, placeOnTable:Bool = true)
	{
		super();
		this.zones = zones;
		this.layer = layer;
		this.closedPath = closedPath;
		this.openPath = openPath;
		this.openSizeMultiplier = openSizeMultiplier;
		closedDisplayWidth = zones.leftW * 0.18;
		loadClosedGraphic();
		angle = clientTableAngle;
		if (placeOnTable)
			placeOnClientTable();
	}

	public function placeBeside(other:DeskDocument):Void
	{
		var gap = zones.leftW * 0.02;
		activeZone = ClientTable;
		setPosition(other.x + other.width + gap, other.y + (other.height - height) * 0.5);
		angle = clientTableAngle;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (loanFolderStorage != null)
			return;

		if (scanLocked || shredLocked)
			return;

		if (snapping)
			return;

		if (MonitorOverlay.blocksWorldInput() || BeginningDayOverlay.blocksWorldInput() || MainMenuOverlay.blocksWorldInput()
			|| ShiftPauseOverlay.blocksWorldInput() || ScreenFadeOverlay.blocksWorldInput())
		{
			if (dragging)
				finishDrag();
			return;
		}

		var mouse = FlxG.mouse.getViewPosition();

		if (ScanModeOverlay.blocksDocumentInteraction(this, mouse))
		{
			if (dragging)
				finishDrag();
			return;
		}

		if (dragging)
		{
			var pullHost = loanFolderPullHost;
			if (pullHost != null)
			{
				if (pullHost.updatePullingDocument(this, mouse))
				{
					if (FlxG.mouse.justReleased)
						finishDrag();
					return;
				}
				loanFolderPullHost = null;
				pullHost.onDocumentPulledOutside(this);
			}

			setPosition(mouse.x - width * dragGrabNormX, mouse.y - height * dragGrabNormY);
			applyDragBounds();
			if (onUpdateDragPresentation != null)
				onUpdateDragPresentation(this);
			updateStateFromPosition();
			LoanFolderDocument.updateDragHover(this, mouse.x, mouse.y);
			if (FlxG.mouse.justReleased)
				finishDrag();
			return;
		}

		if (ScanModeOverlay.isScanModeActive() && FlxG.mouse.justPressed)
			return;

		if (ScanModeOverlay.suppressDocumentPress && FlxG.mouse.justPressed)
			return;

		if (FlxG.mouse.justPressed
			&& currentDrag == null
			&& hitsPoint(mouse)
			&& isFrontmostAtPoint(mouse)
			&& (onCanStartDrag == null || onCanStartDrag(this, mouse)))
		{
			bringToFront();
			startDrag(mouse.x, mouse.y);
		}
	}

	function bringToFront():Void
	{
		if (layer.members.indexOf(this) < 0)
			return;
		layer.remove(this, true);
		layer.add(this);
	}

	function isFrontmostAtPoint(point:FlxPoint):Bool
	{
		var frontmost:DeskDocument = null;
		for (member in layer.members)
		{
			if (member == null)
				continue;
			var doc = Std.downcast(member, DeskDocument);
			if (doc == null || !doc.hitsPoint(point))
				continue;
			frontmost = doc;
		}
		return frontmost == this;
	}

	public function hitsPoint(point:FlxPoint):Bool
	{
		if (loanFolderStorage != null)
			return false;
		if (!overlapsPoint(point))
			return false;
		if (!useAlphaHitTest)
			return true;
		return pixelsOverlapPoint(point, alphaThreshold);
	}

	public function resolveScanBoundsAt(point:FlxPoint):Null<ScanBounds>
	{
		if (!visible || !hitsPoint(point))
			return null;

		return {
			x: x,
			y: y,
			w: width,
			h: height
		};
	}

	public function isOpenOnEmployerTable():Bool
	{
		if (activeZone == ClientTable)
			return false;
		return isOpen && (activeZone == EmployerTable || overlapsEmployerTable());
	}

	public function hasEmployerClipReady():Bool
	{
		return clipRect != null && clipRect.width > 0 && clipRect.height > 0;
	}

	public static function blocksOverlayUpdates():Bool
	{
		return MonitorOverlay.blocksWorldInput()
			|| BeginningDayOverlay.blocksWorldInput()
			|| MainMenuOverlay.blocksWorldInput();
	}

	public function refreshEmployerTableClip():Void
	{
		if (isOpen && (activeZone == EmployerTable || overlapsEmployerTable()))
			updateEmployerTableClip();
	}

	function shouldOpenOnEmployerDrop():Bool
	{
		var mouse = FlxG.mouse.getViewPosition();
		var norm = normalizeZoneCoords(mouse.x, mouse.y);
		return cursorInEmployerTable(norm.x, norm.y);
	}

	function prefersFreeDropPlacement():Bool
	{
		return false;
	}

	function shouldSnapToEmployerTableOpenOnDrop():Bool
	{
		return false;
	}

	public function getClosedGraphicPath():String
	{
		return closedPath;
	}

	public function getClosedDisplayScale():Float
	{
		if (frameWidth <= 0)
			return 1.0;
		return closedDisplayWidth / frameWidth;
	}

	public function getOpenGraphicPath():String
	{
		return openPath;
	}

	public function getOpenDisplayTargetWidth():Float
	{
		return closedDisplayWidth * openSizeMultiplier;
	}

	public function getOpenDisplayTargetHeight(bitmapWidth:Int, bitmapHeight:Int):Float
	{
		if (bitmapWidth <= 0)
			return 0;
		return bitmapHeight * getOpenDisplayTargetWidth() / bitmapWidth;
	}

	public function setCustomOpenGraphic(bmp:BitmapData):Void
	{
		customOpenGraphic = bmp;
	}

	public function isDragging():Bool
	{
		return dragging;
	}

	public function isStoredInLoanFolder():Bool
	{
		return loanFolderStorage != null;
	}

	public function setLoanFolderStorage(folder:Null<LoanFolderDocument>):Void
	{
		var leavingFolder = loanFolderStorage != null && folder == null;
		loanFolderStorage = folder;
		if (leavingFolder)
			restoreAfterLoanFolderStorage();
	}

	function restoreAfterLoanFolderStorage():Void
	{
		refreshDisplaySize();
	}

	public function getLoanFolderPullHost():LoanFolderDocument
	{
		return loanFolderPullHost;
	}

	public function setLoanFolderPullHost(folder:Null<LoanFolderDocument>):Void
	{
		loanFolderPullHost = folder;
	}

	public function setActiveZone(zone:Zone):Void
	{
		activeZone = zone;
	}

	public function cancelDragState():Void
	{
		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}
		FlxTween.cancelTweensOf(this);
		dragging = false;
		snapping = false;
	}

	public function bringToFrontInLayer():Void
	{
		bringToFront();
	}

	public function snapToMouseWhileDragging(mouseX:Float, mouseY:Float):Void
	{
		if (!dragging)
			return;
		setPosition(mouseX - width * dragGrabNormX, mouseY - height * dragGrabNormY);
	}

	public function recenterDragOnMouse(mouseX:Float, mouseY:Float):Void
	{
		dragGrabNormX = 0.5;
		dragGrabNormY = 0.5;
		if (dragging)
			setPosition(mouseX - width * 0.5, mouseY - height * 0.5);
	}

	public function refreshDisplaySize():Void
	{
		applyDisplaySize();
	}

	public function applyStoredDisplayWidth(targetWidth:Float):Void
	{
		if (isOpen)
			setClosed();
		if (frameWidth <= 0)
			return;
		var s = targetWidth / frameWidth;
		scale.set(s, s);
		updateHitbox();
		angle = 0;
	}

	public function isCompactDragPreviewActive():Bool
	{
		return compactDragPreviewActive;
	}

	public function isSnappingToTable():Bool
	{
		return snapping;
	}

	public function beginFolderHoverPreview():Void
	{
		beginCompactDragPreview();
	}

	public function endFolderHoverPreview():Void
	{
		endCompactDragPreview();
	}

	public function beginCompactDragPreview():Void
	{
		if (compactDragPreviewActive)
			return;

		compactDragPreviewActive = true;
		compactDragPreviewWasOpen = isOpen;
		compactDragPreviewScaleX = scale.x;
		compactDragPreviewScaleY = scale.y;
		compactDragPreviewAngle = angle;

		if (isOpen)
			setClosed();
		else
		{
			var paper = Std.downcast(this, PrinterPaperDocument);
			if (paper != null)
				paper.ensureSmallClosedGraphic();
		}
		applyDisplaySize();

		var paper = Std.downcast(this, PrinterPaperDocument);
		if (paper != null)
			angle = PrinterPaperDocument.CLOSED_ANGLE;
		else
			syncClosedDragAngle();

		notifyDrawLayerChanged();
	}

	public function discardCompactDragPreview():Void
	{
		compactDragPreviewActive = false;
	}

	public function endCompactDragPreview():Void
	{
		if (!compactDragPreviewActive)
			return;
		compactDragPreviewActive = false;
		if (compactDragPreviewWasOpen)
			setOpen();
		else
			setClosed();
		scale.set(compactDragPreviewScaleX, compactDragPreviewScaleY);
		angle = compactDragPreviewAngle;
		updateHitbox();
		notifyDrawLayerChanged();
	}

	public function isOnClientOrEmployerTable():Bool
	{
		return activeZone == ClientTable || activeZone == EmployerTable;
	}

	public function isOnClientTable():Bool
	{
		return activeZone == ClientTable;
	}

	public function belongsInClientTableRow():Bool
	{
		if (isStoredInLoanFolder())
			return false;
		if (isOpenOnEmployerTable())
			return false;
		return isOnClientTable();
	}

	public function isOnClientWindow():Bool
	{
		return activeZone == Client;
	}

	public function isOnComputerWindow():Bool
	{
		return activeZone == Computer;
	}

	public function isOnLeftColumnAboveLens():Bool
	{
		return isOnClientTable() || isOnClientWindow() || isOnComputerWindow();
	}

	public function isCurrentlyOpen():Bool
	{
		return isOpen;
	}

	public static function shouldUseLensMagnifier(doc:DeskDocument, layerIndex:Int, magnifierIndex:Int):Bool
	{
		if (layerIndex < 0 || magnifierIndex < 0 || layerIndex >= magnifierIndex)
			return false;

		var folder = Std.downcast(doc, LoanFolderDocument);
		if (folder != null)
			return folder.isOpenOnEmployerTable();

		if (doc.loanFolderStorage != null)
			return doc.loanFolderStorage.isOpenOnEmployerTable();

		return doc.isCurrentlyOpen();
	}

	public static function usesMagnifierCoverLayer(doc:DeskDocument):Bool
	{
		var folder = Std.downcast(doc, LoanFolderDocument);
		if (folder != null)
			return folder.isOpenOnEmployerTable();

		if (doc.loanFolderStorage != null)
			return doc.loanFolderStorage.isOpenOnEmployerTable();

		return doc.isCurrentlyOpen();
	}

	public function setInteractionLayer(newLayer:FlxGroup):Void
	{
		layer = newLayer;
	}

	public function moveToLayer(target:FlxGroup):Void
	{
		if (layer == target)
			return;

		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);
		setInteractionLayer(target);
		target.add(this);
	}

	public function lockForPrinterScan():Void
	{
		scanLocked = true;
		visible = false;
		onScanLockChanged(true);
	}

	public function unlockAfterPrinterScan():Void
	{
		if (!scanLocked)
			return;

		scanLocked = false;
		visible = true;
		onScanLockChanged(false);
		activeZone = ClientTable;
		setClosed();
		placeOnClientTableAtDropPosition();
	}

	public function lockForShredder():Void
	{
		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}
		FlxTween.cancelTweensOf(this);
		dragging = false;
		snapping = false;
		shredLocked = true;
		clearEmployerClip();
		setClosed();
	}

	public function isShredLocked():Bool
	{
		return shredLocked;
	}

	public function finishShredder():Void
	{
		destroy();
	}

	public function rejectsPrinterAndShredder():Bool
	{
		return false;
	}

	public function hideFromDesk():Void
	{
		visible = false;
		activeZone = None;
	}

	public function prepareClientHandoff():Void
	{
		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}
		FlxTween.cancelTweensOf(this);
		dragging = false;
		snapping = false;
		scanLocked = false;
		clearEmployerClip();
		setClosed();
		activeZone = ClientTable;
		visible = true;
		refreshDisplaySize();
		onScanLockChanged(false);
	}

	function onScanLockChanged(locked:Bool):Void
	{
	}

	public function startDragFromExternal(mouseX:Float, mouseY:Float, ?centerGrab:Bool = false):Void
	{
		bringToFront();
		startDrag(mouseX, mouseY, centerGrab);
	}

	function startDrag(mouseX:Float, mouseY:Float, ?centerGrab:Bool = false):Void
	{
		if (currentDrag != null && currentDrag != this)
			return;

		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}

		currentDrag = this;
		dragging = true;
		snapping = false;
		if (onUpdateDragPresentation != null)
			onUpdateDragPresentation(this);
		if (centerGrab)
		{
			dragGrabNormX = 0.5;
			dragGrabNormY = 0.5;
			setPosition(mouseX - width * 0.5, mouseY - height * 0.5);
		}
		else
		{
			dragGrabNormX = (mouseX - x) / width;
			dragGrabNormY = (mouseY - y) / height;
		}
		updateStateFromPosition();
	}

	public function cancelDrag():Void
	{
		if (dragging)
			finishDrag();
	}

	function finishDrag():Void
	{
		dragging = false;
		if (currentDrag == this)
			currentDrag = null;
		clearEmployerClip();
		storeAngleForZone(activeZone);
		var mouse = FlxG.mouse.getViewPosition();
		var droppedOnDeskProp = isOverDeskPropsAtPoint != null && isOverDeskPropsAtPoint(mouse);
		finishDragResolve();
		if (isStoredInLoanFolder())
			discardCompactDragPreview();
		else if (!snapping && compactDragPreviewActive)
		{
			// Drop resolved closed (e.g. client table) — keep closed; do not restore open preview scale.
			if (!isOpen)
				discardCompactDragPreview();
			else
				endCompactDragPreview();
		}
		LoanFolderDocument.clearDragHover(this);
		notifyDrawLayerChanged();
	}

	function finishDragResolve():Bool
	{
		var mouse = FlxG.mouse.getViewPosition();
		var pullHost = loanFolderPullHost;
		if (pullHost != null)
		{
			loanFolderPullHost = null;
			if (pullHost.finishPullDrag(this, mouse.x, mouse.y))
				return true;
			pullHost.onDocumentPulledOutside(this);
		}

		if (LoanFolderDocument.tryStoreDragged(this, mouse.x, mouse.y))
			return true;

		if (LoanFolderDocument.shouldSnapToClientTableOnDrop(this, mouse.x, mouse.y))
		{
			setClosed();
			placeOnClientTableAtDropPosition();
			return false;
		}

		if (!rejectsPrinterAndShredder() && (cursorInPrinter(mouse.x, mouse.y) || cursorInShredder(mouse.x, mouse.y)))
		{
			var accepted = false;
			if (cursorInPrinter(mouse.x, mouse.y))
				accepted = onDroppedOnPrinter != null && onDroppedOnPrinter(this);
			else
				accepted = onDroppedOnShredder != null && onDroppedOnShredder(this);
			if (!accepted)
				rejectToClientTable();
			else
				discardCompactDragPreview();
			return false;
		}

		if (shouldRejectDeskPropDrop(mouse.x, mouse.y))
		{
			rejectToClientTable();
			return false;
		}

		if (rejectsPrinterAndShredder() && (cursorInPrinter(mouse.x, mouse.y) || cursorInShredder(mouse.x, mouse.y)))
		{
			rejectToClientTable();
			return false;
		}

		var dropZone = getDropZoneOnRelease();
		if (dropZone == None)
			dropZone = activeZone;

		if (dropZone == EmployerTable)
		{
			resolveEmployerTableDrop();
			return false;
		}

		updateZoneFromCenter(dropZone);

		setClosed();

		switch (dropZone)
		{
			case ClientTable:
				placeOnClientTableAtDropPosition();
			case Computer:
				if (prefersFreeDropPlacement())
					clampToComputer();
				else
					snapToDesk(x, y);
			case Client:
				if (prefersFreeDropPlacement())
					clampToClient();
				else
					snapToDesk(x, y);
			case Window:
				snapToClientTableTopRight();
			case EmployerTable:
			case None:
				snapToDesk(x, y);
			default:
		}
		return false;
	}

	function updateStateFromPosition():Void
	{
		if (compactDragPreviewActive)
			return;

		var zone = dragging ? getZoneAtCursor() : getDocumentZone();
		updateZoneFromCenter(zone);

		if (shouldShowOpen())
		{
			setOpen();
			updateEmployerTableClip();
		}
		else
		{
			if (isOpen)
				setClosed();
			else
				clearEmployerClip();
		}

		if (dragging && !isOpen && !compactDragPreviewActive)
			syncClosedDragAngle();
	}

	public function syncClosedDragAngle():Void
	{
		if (!usesZoneAngleWhenClosed())
		{
			angle = 0;
			return;
		}

		var mouse = FlxG.mouse.getViewPosition();
		if (cursorInPrinter(mouse.x, mouse.y) || cursorInShredder(mouse.x, mouse.y) || cursorInCalculator(mouse.x, mouse.y))
		{
			angle = getAngleForZone(ClientTable);
			return;
		}

		var zone = dragging ? getZoneAtCursor() : activeZone;
		if (zone == None)
			zone = activeZone;
		angle = getAngleForZone(zone);
	}

	function updateZoneFromCenter(zone:Zone):Void
	{
		if (zone != activeZone)
		{
			storeAngleForZone(activeZone);
			activeZone = zone;
			if (!isOpen)
				angle = getAngleForZone(zone);
			else
				notifyDrawLayerChanged();
		}
	}

	function shouldShowOpen():Bool
	{
		if (dragging)
		{
			if (compactDragPreviewActive)
				return false;

			var mouse = FlxG.mouse.getViewPosition();
			if (LoanFolderDocument.blocksOpenWhileDraggingOver(mouse.x, mouse.y)
				&& Std.downcast(this, MagnifyingGlass) == null
				&& Std.downcast(this, LoanFolderDocument) == null)
				return false;
			if (cursorInPrinter(mouse.x, mouse.y))
				return false;
			if (cursorInCalculator(mouse.x, mouse.y) || cursorInShredder(mouse.x, mouse.y))
				return false;
			if (rejectsPrinterAndShredder() && (cursorInPrinter(mouse.x, mouse.y) || cursorInShredder(mouse.x, mouse.y)))
				return false;
			if (getDocumentZone() == ClientTable)
				return false;
			return cursorInEmployerTable(mouse.x, mouse.y);
		}
		if (isOpen)
			return overlapsEmployerTable();
		return activeZone == EmployerTable;
	}

	function cursorInEmployerTable(cx:Float, cy:Float):Bool
	{
		var norm = normalizeZoneCoords(cx, cy);
		return inRect(norm.x, norm.y, zones.employerX, zones.employerTableY, zones.employerW, zones.employerTableH);
	}

	function cursorInPrinter(cx:Float, cy:Float):Bool
	{
		return inRect(cx, cy, zones.printerX, zones.printerY, zones.printerW, zones.printerH);
	}

	function cursorInCalculator(cx:Float, cy:Float):Bool
	{
		return inRect(cx, cy, zones.calculatorX, zones.calculatorY, zones.calculatorW, zones.calculatorH);
	}

	function cursorInShredder(cx:Float, cy:Float):Bool
	{
		return inRect(cx, cy, zones.shredderX, zones.shredderY, zones.shredderW, zones.shredderH);
	}

	function overlapsPrinter():Bool
	{
		var px = zones.printerX;
		var py = zones.printerY;
		var pr = px + zones.printerW;
		var pb = py + zones.printerH;
		return x < pr && x + width > px && y < pb && y + height > py;
	}

	function overlapsShredder():Bool
	{
		var sx = zones.shredderX;
		var sy = zones.shredderY;
		var sr = sx + zones.shredderW;
		var sb = sy + zones.shredderH;
		return x < sr && x + width > sx && y < sb && y + height > sy;
	}

	function isDropOnPrinterOrShredder(mouseX:Float, mouseY:Float):Bool
	{
		if (cursorInPrinter(mouseX, mouseY) || cursorInShredder(mouseX, mouseY))
			return true;
		if (rejectsPrinterAndShredder() && (overlapsPrinter() || overlapsShredder()))
			return true;
		return false;
	}

	function centerInPrinter():Bool
	{
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		return inRect(cx, cy, zones.printerX, zones.printerY, zones.printerW, zones.printerH);
	}

	function getDocumentCenter():FlxPoint
	{
		return FlxPoint.get(x + width * 0.5, y + height * 0.5);
	}

	function getDocumentZone():Zone
	{
		var center = getDocumentCenter();
		var zone = getZoneAt(center.x, center.y);
		center.put();
		return zone != None ? zone : activeZone;
	}

	function getDropZoneOnRelease():Zone
	{
		var mouse = FlxG.mouse.getViewPosition();
		var mouseZone = getZoneAt(mouse.x, mouse.y);
		var docZone = getDocumentZone();

		// Large docs can cover the client table while the cursor stays in the employer column.
		if (mouseZone == ClientTable || docZone == ClientTable)
			return ClientTable;

		if (mouseZone != None)
			return mouseZone;

		if (overlapsWindow())
			return Window;

		return docZone != None ? docZone : activeZone;
	}

	function cursorOnDeskProp(mouseX:Float, mouseY:Float):Bool
	{
		if (cursorInCalculator(mouseX, mouseY) || cursorInPrinter(mouseX, mouseY) || cursorInShredder(mouseX, mouseY))
			return true;
		if (isOverDeskPropsAtPoint == null)
			return false;
		var p = FlxPoint.get(mouseX, mouseY);
		var hit = isOverDeskPropsAtPoint(p);
		p.put();
		return hit;
	}

	function shouldRejectDeskPropDrop(mouseX:Float, mouseY:Float):Bool
	{
		if (!cursorOnDeskProp(mouseX, mouseY))
			return false;
		if (getZoneAt(mouseX, mouseY) == ClientTable)
			return false;
		if (isOpen && overlapsEmployerTable())
			return false;
		if (rejectsPrinterAndShredder())
			return true;
		if (compactDragPreviewActive)
			return true;
		return !isOpen;
	}

	function resolveEmployerTableDrop():Void
	{
		activeZone = EmployerTable;
		if (compactDragPreviewActive)
			endCompactDragPreview();
		if (shouldOpenOnEmployerDrop())
		{
			if (!isOpen)
				setOpen();
			updateEmployerTableClip();
			return;
		}
		if (shouldSnapToEmployerTableOpenOnDrop())
		{
			snapToClosestEmployerTableOpen();
			return;
		}
		setClosed();
	}

	function overlapsWindow():Bool
	{
		var wx = zones.employerX;
		var wy = 0.0;
		var ww = zones.employerW;
		var wh = zones.windowH;
		return x < wx + ww && x + width > wx && y < wy + wh && y + height > wy;
	}

	function overlapsEmployerTable():Bool
	{
		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var er = ex + zones.employerW;
		var eb = ey + zones.employerTableH;
		return x < er && x + width > ex && y < eb && y + height > ey;
	}

	function applyDragBounds():Void
	{
		if (dragging)
			return;

		if (activeZone == EmployerTable || overlapsEmployerTable())
			return;

		switch (getDocumentZone())
		{
			case ClientTable:
				clampToClientTable();
			case Window:
				clampToWindow();
			case Client:
				clampToClient();
			case Computer:
				clampToComputer();
			default:
				clampToZone(activeZone);
		}
	}

	function getZoneAtCursor():Zone
	{
		var mouse = FlxG.mouse.getViewPosition();
		var zone = getZoneAt(mouse.x, mouse.y);
		return zone != None ? zone : activeZone;
	}

	function clampToZone(zone:Zone):Void
	{
		switch (zone)
		{
			case ClientTable:
				clampToClientTable();
			case Window:
				clampToWindow();
			case EmployerTable:
			case Client:
				if (zone == Client)
					clampToClient();
			case Computer:
				clampToComputer();
			default:
		}
	}

	function updateEmployerTableClip():Void
	{
		if (!isOpen)
		{
			clearEmployerClip();
			return;
		}

		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var er = ex + zones.employerW;
		var eb = ey + zones.employerTableH;

		var visL = Math.max(x, ex);
		var visT = Math.max(y, ey);
		var visR = Math.min(x + width, er);
		var visB = Math.min(y + height, eb);

		if (visR <= visL || visB <= visT)
		{
			if (isOpen && (activeZone == EmployerTable || overlapsEmployerTable()))
			{
				if (clipRect == null)
					clipRect = FlxRect.get();
				clipRect.set(0, 0, 0, 0);
				return;
			}

			clearEmployerClip();
			return;
		}

		if (!scanLocked && !shredLocked)
			visible = true;
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		if (clipRect == null)
			clipRect = FlxRect.get();
		clipRect.set((visL - x) / sx, (visT - y) / sy, (visR - visL) / sx, (visB - visT) / sy);
	}

	function clearEmployerClip():Void
	{
		clipRect = null;
		if (!scanLocked && !shredLocked)
			visible = true;
	}

	public function syncOverlayClip(overlay:FlxSprite):Void
	{
		if (!visible)
		{
			overlay.clipRect = null;
			return;
		}

		if (clipRect != null)
		{
			var dsx = Math.abs(scale.x);
			var dsy = Math.abs(scale.y);
			applyWorldClipRect(overlay, x + clipRect.x * dsx, y + clipRect.y * dsy, x + (clipRect.x + clipRect.width) * dsx,
				y + (clipRect.y + clipRect.height) * dsy);
			return;
		}

		if (isOpen && (activeZone == EmployerTable || overlapsEmployerTable()))
		{
			var ex = zones.employerX;
			var ey = zones.employerTableY;
			var er = ex + zones.employerW;
			var eb = ey + zones.employerTableH;
			applyWorldClipRect(overlay, Math.max(x, ex), Math.max(y, ey), Math.min(x + width, er), Math.min(y + height, eb));
			return;
		}

		var visL:Float = 0;
		var visT:Float = 0;
		var visR:Float = 0;
		var visB:Float = 0;
		var hasClip = false;

		switch (activeZone)
		{
			case ClientTable:
				if (overlapsComputer())
				{
					visL = 0;
					visT = zones.clientTableY;
					visR = zones.leftW;
					visB = zones.clientTableY + zones.clientTableH;
					hasClip = true;
				}
			case Client:
				if (overlapsClientTable())
				{
					visL = 0;
					visT = 0;
					visR = zones.leftW;
					visB = zones.clientH;
					hasClip = true;
				}
			case Computer:
				if (overlapsClientTable())
				{
					visL = 0;
					visT = zones.computerY;
					visR = zones.leftW;
					visB = zones.computerY + zones.computerH;
					hasClip = true;
				}
			default:
		}

		if (!hasClip)
		{
			overlay.clipRect = null;
			return;
		}

		applyWorldClipRect(overlay, visL, visT, visR, visB);
	}

	function overlapsClientTable():Bool
	{
		var ty = zones.clientTableY;
		var tr = zones.leftW;
		var tb = ty + zones.clientTableH;
		return x < tr && x + width > 0 && y < tb && y + height > ty;
	}

	function overlapsComputer():Bool
	{
		var cy = zones.computerY;
		var cr = zones.leftW;
		var cb = cy + zones.computerH;
		return x < cr && x + width > 0 && y < cb && y + height > cy;
	}

	public function applyWorldClipRect(sprite:FlxSprite, visL:Float, visT:Float, visR:Float, visB:Float):Void
	{
		var sx = Math.abs(sprite.scale.x);
		var sy = Math.abs(sprite.scale.y);
		if (sx <= 0 || sy <= 0)
			return;

		var sL = sprite.x;
		var sT = sprite.y;
		var sR = sprite.x + sprite.width;
		var sB = sprite.y + sprite.height;
		var clipL = Math.max(visL, sL);
		var clipT = Math.max(visT, sT);
		var clipR = Math.min(visR, sR);
		var clipB = Math.min(visB, sB);

		if (clipR <= clipL || clipB <= clipT)
		{
			if (sprite.clipRect == null)
				sprite.clipRect = FlxRect.get();
			sprite.clipRect.set(0, 0, 0, 0);
			return;
		}

		if (sprite.clipRect == null)
			sprite.clipRect = FlxRect.get();
		sprite.clipRect.set((clipL - sprite.x) / sx, (clipT - sprite.y) / sy, (clipR - clipL) / sx, (clipB - clipT) / sy);
	}

	function storeAngleForZone(zone:Zone):Void
	{
		switch (zone)
		{
			case ClientTable:
				clientTableAngle = angle;
			case EmployerTable:
				employerTableAngle = angle;
			case Window:
				windowAngle = angle;
			case Client:
				clientAngle = angle;
			case Computer:
				computerAngle = angle;
			case None:
				noneAngle = angle;
			default:
		}
	}

	function usesZoneAngleWhenClosed():Bool
	{
		return true;
	}

	function getAngleForZone(zone:Zone):Float
	{
		if (!isOpen && !usesZoneAngleWhenClosed())
			return 0;
		return switch (zone)
		{
			case ClientTable: clientTableAngle;
			case EmployerTable: employerTableAngle;
			case Window: windowAngle;
			case Client: clientAngle;
			case Computer: computerAngle;
			case None: noneAngle;
			default: noneAngle;
		}
	}

	function getZoneAt(cx:Float, cy:Float):Zone
	{
		var norm = normalizeZoneCoords(cx, cy);
		cx = norm.x;
		cy = norm.y;

		if (inRect(cx, cy, zones.employerX, zones.employerTableY, zones.employerW, zones.employerTableH))
			return EmployerTable;
		if (inRect(cx, cy, zones.employerX, 0, zones.employerW, zones.windowH))
			return Window;
		if (inRect(cx, cy, 0, zones.clientTableY, zones.leftW, zones.clientTableH))
			return ClientTable;
		if (inRect(cx, cy, 0, 0, zones.leftW, zones.clientH))
			return Client;
		if (inRect(cx, cy, 0, zones.computerY, zones.leftW, zones.computerH))
			return Computer;
		return None;
	}

	static inline var ZONE_EDGE_EPSILON = 0.5;

	function normalizeZoneCoords(cx:Float, cy:Float):{x:Float, y:Float}
	{
		if (cy >= FlxG.height - ZONE_EDGE_EPSILON)
			cy = FlxG.height - ZONE_EDGE_EPSILON;
		if (cx >= FlxG.width - ZONE_EDGE_EPSILON)
			cx = FlxG.width - ZONE_EDGE_EPSILON;
		if (cy < 0)
			cy = 0;
		if (cx < 0)
			cx = 0;
		return {x: cx, y: cy};
	}

	function inRect(cx:Float, cy:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
	{
		return cx >= rx && cx < rx + rw && cy >= ry && cy < ry + rh;
	}

	function rejectToClientTable():Void
	{
		discardCompactDragPreview();
		setClosed();
		refreshDisplaySize();
		placeOnClientTableAtDropPosition(true);
		notifyDrawLayerChanged();
	}

	function snapRejectedDropToClientTable():Void
	{
		rejectToClientTable();
	}

	function snapToDesk(fromX:Float, fromY:Float):Void
	{
		activeZone = ClientTable;
		var target = findClosestDeskSnap(fromX, fromY);
		snapping = true;
		snapTween = FlxTween.tween(this, {x: target.x, y: target.y, angle: getAngleForZone(ClientTable)}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function findClosestDeskSnap(fromX:Float, fromY:Float):{x:Float, y:Float}
	{
		var points = getDeskSnapPoints();
		var best = points[0];
		var bestDist = Math.POSITIVE_INFINITY;

		for (p in points)
		{
			var dx = fromX - p.x;
			var dy = fromY - p.y;
			var dist = dx * dx + dy * dy;
			if (dist < bestDist)
			{
				bestDist = dist;
				best = p;
			}
		}
		return best;
	}

	function getDeskSnapPoints():Array<{x:Float, y:Float}>
	{
		var margin = Std.int(Math.max(6, zones.leftW * 0.04));
		var tableY = zones.clientTableY;
		var tableH = zones.clientTableH;
		var w = width;
		var h = height;

		return [
			{x: margin, y: tableY + tableH * 0.25 - h * 0.5},
			{x: zones.leftW * 0.5 - w * 0.5, y: tableY + tableH * 0.5 - h * 0.5},
			{x: zones.leftW - w - margin, y: tableY + tableH * 0.72 - h * 0.5}
		];
	}

	function placeOnClientTable():Void
	{
		activeZone = ClientTable;
		var center = findClosestDeskSnap(zones.leftW * 0.5, zones.clientTableY + zones.clientTableH * 0.5);
		setPosition(center.x, center.y);
		angle = clientTableAngle;
	}

	function placeOnClientTableAtDropPosition(?animate:Bool = false):Void
	{
		activeZone = ClientTable;
		var target = getClientTableDropTarget();
		var targetAngle = getAngleForZone(ClientTable);

		if (!animate)
		{
			x = target.x;
			y = target.y;
			angle = targetAngle;
			return;
		}

		tweenToClientTablePosition(target.x, target.y, targetAngle);
	}

	function getClientTableDropTarget():{x:Float, y:Float}
	{
		var tx = FlxMath.bound(x, 0, zones.leftW - width);
		var ty = FlxMath.bound(y, zones.clientTableY, zones.clientTableY + zones.clientTableH - height);
		var minX = CLIENT_TABLE_PAD_LEFT;
		var maxX = zones.leftW - width - CLIENT_TABLE_PAD_RIGHT;
		var minY = zones.clientTableY + CLIENT_TABLE_PAD_TOP;
		var maxY = zones.clientTableY + zones.clientTableH - height - CLIENT_TABLE_PAD_BOTTOM;
		return {
			x: FlxMath.bound(tx, minX, maxX),
			y: FlxMath.bound(ty, minY, maxY)
		};
	}

	function tweenToClientTablePosition(targetX:Float, targetY:Float, targetAngle:Float):Void
	{
		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}

		snapping = true;
		snapTween = FlxTween.tween(this, {x: targetX, y: targetY, angle: targetAngle}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	static inline var CLIENT_TABLE_PAD_LEFT:Float = 5;
	static inline var CLIENT_TABLE_PAD_RIGHT:Float = 5;
	static inline var CLIENT_TABLE_PAD_TOP:Float = 25;
	static inline var CLIENT_TABLE_PAD_BOTTOM:Float = 2;

	function clampToClientTable():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, zones.clientTableY, zones.clientTableY + zones.clientTableH - height);
	}

	function clampToClient():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, 0, zones.clientH - height);
	}

	static inline var COMPUTER_PAD_LEFT:Float = 10;
	static inline var COMPUTER_PAD_RIGHT:Float = 10;

	function clampToComputer():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, zones.computerY, zones.computerY + zones.computerH - height);
	}

	function nudgeFromComputerEdges():Void
	{
		var minX = COMPUTER_PAD_LEFT;
		var maxX = zones.leftW - width - COMPUTER_PAD_RIGHT;

		var needsNudge = x < minX || x > maxX;
		if (!needsNudge)
			return;

		var nx = FlxMath.bound(x, minX, maxX);

		snapping = true;
		snapTween = FlxTween.tween(this, {x: nx}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function clampToWindow():Void
	{
		x = FlxMath.bound(x, zones.employerX, zones.employerX + zones.employerW - width);
		y = FlxMath.bound(y, 0, zones.windowH - height);
	}

	function clampToEmployerTable():Void
	{
		x = FlxMath.bound(x, zones.employerX, zones.employerX + zones.employerW - width);
		y = FlxMath.bound(y, zones.employerTableY, zones.employerTableY + zones.employerTableH - height);
	}

	function snapToClientTableTopRight():Void
	{
		activeZone = ClientTable;
		var margin = Std.int(Math.max(6, zones.leftW * 0.04));
		var targetX = zones.leftW - width - Math.max(margin, CLIENT_TABLE_PAD_RIGHT);
		var targetY = zones.clientTableY + Math.max(margin, CLIENT_TABLE_PAD_TOP);

		snapping = true;
		snapTween = FlxTween.tween(this, {x: targetX, y: targetY, angle: getAngleForZone(ClientTable)}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function snapToClosestEmployerTableOpen():Void
	{
		activeZone = EmployerTable;
		setOpen();
		var target = findClosestEmployerTableSnap(x + width * 0.5, y + height * 0.5);
		clampSnapTargetToEmployerTable(target);
		snapping = true;
		snapTween = FlxTween.tween(this, {x: target.x, y: target.y, angle: getAngleForZone(EmployerTable)}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function findClosestEmployerTableSnap(fromX:Float, fromY:Float):{x:Float, y:Float}
	{
		var points = getEmployerSnapPoints();
		var best = points[0];
		var bestDist = Math.POSITIVE_INFINITY;

		for (p in points)
		{
			var dx = fromX - (p.x + width * 0.5);
			var dy = fromY - (p.y + height * 0.5);
			var dist = dx * dx + dy * dy;
			if (dist < bestDist)
			{
				bestDist = dist;
				best = p;
			}
		}
		return best;
	}

	function getEmployerSnapPoints():Array<{x:Float, y:Float}>
	{
		var margin = Std.int(Math.max(6, zones.employerW * 0.02));
		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var ew = zones.employerW;
		var eh = zones.employerTableH;
		var w = width;
		var h = height;

		return [
			{x: ex + margin, y: ey + margin},
			{x: ex + ew * 0.5 - w * 0.5, y: ey + eh * 0.5 - h * 0.5},
			{x: ex + ew - w - margin, y: ey + margin},
			{x: ex + margin, y: ey + eh - h - margin},
			{x: ex + ew - w - margin, y: ey + eh - h - margin}
		];
	}

	function clampSnapTargetToEmployerTable(target:{x:Float, y:Float}):Void
	{
		target.x = FlxMath.bound(target.x, zones.employerX, zones.employerX + zones.employerW - width);
		target.y = FlxMath.bound(target.y, zones.employerTableY, zones.employerTableY + zones.employerTableH - height);
	}

	function setClosed():Void
	{
		if (!isOpen)
		{
			syncClosedDragAngle();
			return;
		}

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = false;
		loadGraphic(closedPath);
		applyDisplaySize();
		angle = getAngleForZone(activeZone);
		placeAfterResize(cx, cy);
		notifyDrawLayerChanged();
	}

	function setOpen():Void
	{
		if (isOpen)
			return;

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = true;
		if (customOpenGraphic != null)
			loadGraphic(customOpenGraphic.clone());
		else
			loadGraphic(openPath);
		applyDisplaySize();
		angle = 0;
		placeAfterResize(cx, cy);
		notifyDrawLayerChanged();
	}

	public function refreshDrawLayer():Void
	{
		notifyDrawLayerChanged();
	}

	function notifyDrawLayerChanged():Void
	{
		if (onDrawLayerChanged != null)
			onDrawLayerChanged(this);
	}

	function placeAfterResize(prevCenterX:Float, prevCenterY:Float):Void
	{
		if (dragging)
			alignToDragPoint();
		else
			setPosition(prevCenterX - width * 0.5, prevCenterY - height * 0.5);
	}

	function alignToDragPoint():Void
	{
		var mouse = FlxG.mouse.getViewPosition();
		setPosition(mouse.x - width * dragGrabNormX, mouse.y - height * dragGrabNormY);
	}

	function loadClosedGraphic():Void
	{
		loadGraphic(closedPath);
		applyDisplaySize();
	}

	function applyDisplaySize():Void
	{
		var targetWidth = isOpen ? closedDisplayWidth * openSizeMultiplier : closedDisplayWidth;
		var s = targetWidth / frameWidth;
		scale.set(s, s);
		updateHitbox();
	}
}
