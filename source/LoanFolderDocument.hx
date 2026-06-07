package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class LoanFolderDocument extends DeskDocument
{
	static inline var CLOSED_PATH = "static/loan_folder.png";
	static inline var OPENED_PATH = "static/loan_opened_folder.png";
	static inline var OPEN_SIZE_MULTIPLIER = 2.5;
	static inline var SPREAD_SIZE_MULTIPLIER = 4.0;
	static inline var CLOSED_WIDTH_RATIO = 0.13;
	public static inline var TABLE_ANGLE = -6.0;

	static inline var CLOSED_ARROW_NX0 = 0.549;
	static inline var CLOSED_ARROW_NY0 = 0.78;
	static inline var CLOSED_ARROW_NX1 = 0.956;
	static inline var CLOSED_ARROW_NY1 = 0.996;

	static inline var OPENED_ARROW_NX0 = 0.071;
	static inline var OPENED_ARROW_NY0 = 0.869;
	static inline var OPENED_ARROW_NX1 = 0.147;
	static inline var OPENED_ARROW_NY1 = 0.955;

	// Storage pocket on loan_opened_folder.png (421×359), art-space pixels.
	static inline var OPENED_ART_W = 421;
	static inline var OPENED_ART_H = 359;
	static inline var STORAGE_X0 = 184;
	static inline var STORAGE_Y0 = 35;
	static inline var STORAGE_X1 = 405;
	static inline var STORAGE_Y1 = 345;
	static inline var STORED_STACK_OFFSET = 3.0;
	static inline var STORED_WIDTH_IN_POCKET_RATIO = 0.92;
	// Pocket art tucks under the front lip; keep stored copies above that fold.
	static inline var STORAGE_BOTTOM_INSET = 24.0;

	public static var activeFolder:LoanFolderDocument = null;

	public var onStoredDocumentsChanged:Void->Void;

	var folderSpreadOpen = false;
	var loadedEmployerPath:String = null;
	var storedDocs:Array<DeskDocument> = [];
	var pullSlotIndex = 0;
	var storedLayoutDirty = false;
	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		super(zones, layer, CLOSED_PATH, CLOSED_PATH, OPEN_SIZE_MULTIPLIER, false);
		closedDisplayWidth = zones.employerW * CLOSED_WIDTH_RATIO;
		applyDisplaySize();
		setZoneAngles(TABLE_ANGLE, TABLE_ANGLE, TABLE_ANGLE, TABLE_ANGLE, TABLE_ANGLE, TABLE_ANGLE);
		angle = TABLE_ANGLE;
		useAlphaHitTest = true;
	}

	public function isSpreadOpen():Bool
	{
		return folderSpreadOpen;
	}

	override public function isOpenOnEmployerTable():Bool
	{
		return isOpen && (activeZone == EmployerTable || overlapsEmployerTable());
	}

	override function shouldShowOpen():Bool
	{
		if (dragging && folderSpreadOpen)
			return true;
		if (folderSpreadOpen)
			return activeZone == EmployerTable || overlapsEmployerTable();
		return super.shouldShowOpen();
	}

	public function hasStoredDocuments():Bool
	{
		return storedDocs.length > 0;
	}

	public function getStoredDocuments():Array<DeskDocument>
	{
		return storedDocs;
	}

	override function destroy():Void
	{
		if (activeFolder == this)
			activeFolder = null;
		releaseAllStoredToDesk();
		super.destroy();
	}

	override function usesZoneAngleWhenClosed():Bool
	{
		return true;
	}

	override function applyDisplaySize():Void
	{
		if (frameWidth <= 0)
			return;

		var openMultiplier = folderSpreadOpen ? SPREAD_SIZE_MULTIPLIER : OPEN_SIZE_MULTIPLIER;
		var targetWidth = isOpen ? closedDisplayWidth * openMultiplier : closedDisplayWidth;
		var s = targetWidth / frameWidth;
		scale.set(s, s);
		updateHitbox();
		layoutStoredDocuments();
	}

	override function update(elapsed:Float):Void
	{
		if (!scanLocked && !shredLocked && !snapping && folderSpreadOpen && storedDocs.length > 0)
		{
			var mouse = FlxG.mouse.getViewPosition();
			if (FlxG.mouse.justPressed
				&& DeskDocument.currentDrag == null
				&& pointInStorageWorld(mouse.x, mouse.y)
				&& !isAnyOtherDocumentDragging()
				&& !isStoredDocDragBlockedAt(mouse)
				&& (DeskDocument.magnifierHitsPoint == null || !DeskDocument.magnifierHitsPoint(mouse)))
			{
				var doc = topStoredDocAt(mouse);
				if (doc != null)
				{
					beginStoredDocDrag(doc, mouse.x, mouse.y);
					return;
				}
			}
		}

		if (!scanLocked && !shredLocked && !snapping && isBigOnEmployerTable())
		{
			var mouse = FlxG.mouse.getViewPosition();
			if (FlxG.mouse.justPressed && canHandleArrowClickAt(mouse) && tryHandleArrowClick(mouse))
				return;
		}

		if (folderSpreadOpen && storedLayoutDirty)
			layoutStoredDocuments();

		super.update(elapsed);
	}

	override function hitsPoint(point:FlxPoint):Bool
	{
		if (!visible)
			return false;

		if (!isBigOnEmployerTable())
			return super.hitsPoint(point);

		if (pointInArrowRegion(point))
			return super.hitsPoint(point);

		if (!folderSpreadOpen)
			return super.hitsPoint(point);

		if (pointInFolderDragRegion(point) || pointInStorageWorld(point.x, point.y))
			return super.hitsPoint(point);

		return false;
	}

	public function canBeginDragAt(point:FlxPoint):Bool
	{
		if (!folderSpreadOpen || !isBigOnEmployerTable())
			return true;

		if (pointInArrowRegion(point))
			return false;

		if (isAnyOtherDocumentDragging())
			return false;

		if (pointInStorageWorld(point.x, point.y) && storedDocs.length > 0)
		{
			if (DeskDocument.magnifierHitsPoint != null && DeskDocument.magnifierHitsPoint(point))
				return false;
			if (DeskDocument.currentDrag != null)
				return false;
			if (isStoredDocDragBlockedAt(point))
				return false;
			var doc = topStoredDocAt(point);
			if (doc != null)
				beginStoredDocDrag(doc, point.x, point.y);
			return false;
		}

		return canDragFolderAt(point);
	}

	override function setOpen():Void
	{
		if (isOpen)
		{
			clearEmployerClip();
			ensureEmployerGraphic();
			syncStoredVisibility();
			return;
		}

		clearEmployerClip();
		var right = x + width;
		var cy = y + height * 0.5;
		isOpen = true;
		loadEmployerGraphic();
		applyDisplaySize();
		angle = 0;
		setPosition(right - width, cy - height * 0.5);
		syncStoredVisibility();
		notifyDrawLayerChanged();
	}

	override function setClosed():Void
	{
		if (!isOpen)
			return;

		folderSpreadOpen = false;
		loadedEmployerPath = null;
		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = false;
		loadGraphic(CLOSED_PATH);
		applyDisplaySize();
		angle = getAngleForZone(activeZone);
		placeAfterResize(cx, cy);
		syncStoredVisibility();
		notifyDrawLayerChanged();
	}

	function isBigOnEmployerTable():Bool
	{
		return isOpen && (activeZone == EmployerTable || overlapsEmployerTable());
	}

	function loadEmployerGraphic():Void
	{
		var path = folderSpreadOpen ? OPENED_PATH : CLOSED_PATH;
		if (loadedEmployerPath == path)
			return;
		loadedEmployerPath = path;
		loadGraphic(path);
	}

	function ensureEmployerGraphic():Void
	{
		loadEmployerGraphic();
		applyDisplaySize();
	}

	function toggleFolderSpread():Void
	{
		if (!isBigOnEmployerTable())
			return;

		var right = x + width;
		var cy = y + height * 0.5;
		folderSpreadOpen = !folderSpreadOpen;
		loadEmployerGraphic();
		applyDisplaySize();
		angle = 0;
		setPosition(right - width, cy - height * 0.5);
		updateEmployerTableClip();
		syncStoredVisibility();
		layoutStoredDocuments();
		reorderStoredCopiesAfterFolder();
	}

	function tryHandleArrowClick(point:FlxPoint):Bool
	{
		if (!pointInArrowRegion(point))
			return false;

		toggleFolderSpread();
		markStoredLayoutDirty();
		return true;
	}

	function canHandleArrowClickAt(point:FlxPoint):Bool
	{
		if (!pointInArrowRegion(point))
			return false;

		if (DeskDocument.magnifierHitsPoint != null && DeskDocument.magnifierHitsPoint(point))
			return false;

		if (DeskDocument.isOverDeskPropsAtPoint != null && DeskDocument.isOverDeskPropsAtPoint(point))
			return false;

		if (DeskDocument.isTopmostAtPoint != null)
			return DeskDocument.isTopmostAtPoint(this, point);

		return isFrontmostAtPoint(point);
	}

	function pointInArrowRegion(point:FlxPoint):Bool
	{
		var local = worldToLocal(point.x, point.y);
		if (local == null)
			return false;

		if (folderSpreadOpen)
			return local.x >= frameWidth * OPENED_ARROW_NX0 && local.x <= frameWidth * OPENED_ARROW_NX1
				&& local.y >= frameHeight * OPENED_ARROW_NY0 && local.y <= frameHeight * OPENED_ARROW_NY1;

		return local.x >= frameWidth * CLOSED_ARROW_NX0 && local.x <= frameWidth * CLOSED_ARROW_NX1
			&& local.y >= frameHeight * CLOSED_ARROW_NY0 && local.y <= frameHeight * CLOSED_ARROW_NY1;
	}

	public function pointInStorageWorld(px:Float, py:Float):Bool
	{
		if (!folderSpreadOpen || !visible)
			return false;

		var local = worldToLocal(px, py);
		if (local == null)
			return false;

		var hit = pointInStorageLocal(local.x, local.y);
		local.put();
		return hit;
	}

	function pointInStorageLocal(localX:Float, localY:Float):Bool
	{
		var b = getStorageLocalBounds();
		return localX >= b.x0 && localX <= b.x1 && localY >= b.y0 && localY <= b.y1;
	}

	function getStorageLocalBounds():{x0:Float, y0:Float, x1:Float, y1:Float}
	{
		var fx = frameWidth > 0 ? frameWidth / OPENED_ART_W : 1.0;
		var fy = frameHeight > 0 ? frameHeight / OPENED_ART_H : 1.0;
		return {
			x0: STORAGE_X0 * fx,
			y0: STORAGE_Y0 * fy,
			x1: STORAGE_X1 * fx,
			y1: STORAGE_Y1 * fy
		};
	}

	public function isDepositHoverAt(px:Float, py:Float):Bool
	{
		return pointInDepositHoverRegion(px, py);
	}

	function pointInDepositHoverRegion(px:Float, py:Float):Bool
	{
		if (!folderSpreadOpen || !visible)
			return false;

		var point = FlxPoint.get(px, py);
		if (pointInArrowRegion(point))
		{
			point.put();
			return false;
		}

		var hit = overlapsPoint(point);
		if (hit && useAlphaHitTest)
			hit = pixelsOverlapPoint(point, alphaThreshold);
		point.put();
		return hit;
	}

	function pointInFolderDragRegion(point:FlxPoint):Bool
	{
		if (!folderSpreadOpen)
			return true;

		var local = worldToLocal(point.x, point.y);
		if (local == null)
			return false;
		if (pointInArrowRegion(point))
			return false;

		var b = getStorageLocalBounds();
		var besidePocket = local.x < b.x0 || local.x > b.x1;
		local.put();
		return besidePocket;
	}

	function canDragFolderAt(point:FlxPoint):Bool
	{
		if (!folderSpreadOpen)
			return true;

		if (pointInFolderDragRegion(point))
			return true;

		return storedDocs.length == 0 && pointInStorageWorld(point.x, point.y);
	}

	static function isStorableCopy(doc:DeskDocument):Bool
	{
		if (Std.downcast(doc, BankDocument) != null)
			return true;
		if (Std.downcast(doc, JobContractDocument) != null)
			return true;
		return Std.downcast(doc, PrinterPaperDocument) != null;
	}

	function worldToLocal(px:Float, py:Float):Null<FlxPoint>
	{
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		if (sx <= 0 || sy <= 0)
			return null;

		return FlxPoint.get((px - x) / sx, (py - y) / sy);
	}

	function getStorageWorldRect():{x:Float, y:Float, w:Float, h:Float}
	{
		var b = getStorageLocalBounds();
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		return {
			x: x + b.x0 * sx,
			y: y + b.y0 * sy,
			w: (b.x1 - b.x0) * sx,
			h: (b.y1 - b.y0) * sy
		};
	}

	function storedDisplayWidth():Float
	{
		var pocket = getStorageWorldRect();
		return pocket.w * STORED_WIDTH_IN_POCKET_RATIO;
	}

	function getStoredDocLayoutRect():{x:Float, y:Float, w:Float, h:Float}
	{
		var pocket = getStorageWorldRect();
		var fy = frameHeight > 0 ? frameHeight / OPENED_ART_H : 1.0;
		var sy = Math.abs(scale.y);
		var bottomInset = STORAGE_BOTTOM_INSET * fy * sy;
		return {
			x: pocket.x,
			y: pocket.y,
			w: pocket.w,
			h: Math.max(1.0, pocket.h - bottomInset)
		};
	}

	function layoutStoredPaper(paper:PrinterPaperDocument, stackX:Float, stackY:Float, layoutW:Float, layoutH:Float,
		off:Float):Void
	{
		paper.applyStoredInFolderLayout(layoutW, layoutH, STORED_WIDTH_IN_POCKET_RATIO);
		paper.setPosition(stackX - paper.width * 0.5 + off, stackY - paper.height * 0.5 + off);
		paper.clipRect = null;
		paper.refreshStoredCopyOverlays();
		syncStoredDocCameras(paper);
	}

	function syncStoredDocCameras(doc:DeskDocument):Void
	{
		if (DeskDocument.onLensCamerasSync != null)
			DeskDocument.onLensCamerasSync(doc);
		else
			doc.cameras = [FlxG.camera];
	}

	function markStoredLayoutDirty():Void
	{
		storedLayoutDirty = true;
	}

	function layoutStoredDocuments():Void
	{
		storedLayoutDirty = false;

		if (!folderSpreadOpen || storedDocs.length == 0)
			return;

		var i = storedDocs.length - 1;
		while (i >= 0)
		{
			if (!isStorableCopy(storedDocs[i]))
				storedDocs.splice(i, 1);
			i--;
		}

		if (storedDocs.length == 0)
			return;

		var layout = getStoredDocLayoutRect();
		var stackX = layout.x + layout.w * 0.5;
		var stackY = layout.y + layout.h * 0.5;

		for (doc in storedDocs)
			doc.notifyDrawLayerChanged();
		reorderStoredCopiesAfterFolder();

		for (i in 0...storedDocs.length)
		{
			var doc = storedDocs[i];
			var off = i * STORED_STACK_OFFSET;
			var paper = Std.downcast(doc, PrinterPaperDocument);
			if (paper != null)
				layoutStoredPaper(paper, stackX, stackY, layout.w, layout.h, off);
			else
			{
				var docW = layout.w * STORED_WIDTH_IN_POCKET_RATIO;
				doc.applyStoredDisplayWidth(docW);
				doc.setPosition(stackX - doc.width * 0.5 + off, stackY - doc.height * 0.5 + off);
				doc.clipRect = null;
				syncStoredDocCameras(doc);
				var bankDoc = Std.downcast(doc, BankDocument);
				if (bankDoc != null)
					bankDoc.refreshStoredTextOverlays();
			}
		}

	}

	function syncStoredVisibility():Void
	{
		var show = folderSpreadOpen && isOpen;
		for (doc in storedDocs)
		{
			doc.visible = show;
			doc.clipRect = null;
		}
	}

	override function moveToLayer(target:FlxGroup):Void
	{
		super.moveToLayer(target);
		syncStoredCopiesToLayer();
	}

	public function syncStoredCopiesToLayer():Void
	{
		reorderStoredCopiesAfterFolder();
	}

	function reorderStoredCopiesAfterFolder():Void
	{
		if (layer == null || storedDocs.length == 0)
			return;

		var folderIndex = layer.members.indexOf(this);
		if (folderIndex < 0)
			return;

		for (doc in storedDocs)
			removeStoredDocFromLayer(doc);

		var insertAt = folderIndex + 1;
		for (doc in storedDocs)
		{
			layer.insert(insertAt, doc);
			insertAt++;
			insertAt = insertStoredDocOverlays(doc, insertAt);
		}
	}

	function removeStoredDocFromLayer(doc:DeskDocument):Void
	{
		for (overlay in storedDocOverlayMembers(doc))
		{
			if (layer.members.indexOf(overlay) >= 0)
				layer.remove(overlay, true);
		}

		if (layer.members.indexOf(doc) >= 0)
			layer.remove(doc, true);
	}

	function insertStoredDocOverlays(doc:DeskDocument, insertAt:Int):Int
	{
		for (overlay in storedDocOverlayMembers(doc))
		{
			if (layer.members.indexOf(overlay) >= 0)
				layer.remove(overlay, true);
			layer.insert(insertAt, overlay);
			insertAt++;
		}
		return insertAt;
	}

	function storedDocOverlayMembers(doc:DeskDocument):Array<Dynamic>
	{
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null)
			return bankDoc.getTextOverlayMembers();

		var paper = Std.downcast(doc, PrinterPaperDocument);
		if (paper != null)
			return paper.getCopyOverlayMembers();

		return [];
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		reorderStoredCopiesAfterFolder();
	}

	function topStoredDocAt(point:FlxPoint):Null<DeskDocument>
	{
		var i = storedDocs.length - 1;
		while (i >= 0)
		{
			var doc = storedDocs[i];
			if (doc.overlapsPoint(point))
				return doc;
			i--;
		}

		if (pointInStorageWorld(point.x, point.y) && storedDocs.length > 0)
			return storedDocs[storedDocs.length - 1];

		return null;
	}

	function beginStoredDocDrag(doc:DeskDocument, mouseX:Float, mouseY:Float):Void
	{
		if (isAnyOtherDocumentDragging() || doc.isDragging())
			return;
		if (DeskDocument.currentDrag != null)
			return;

		pullSlotIndex = storedDocs.indexOf(doc);
		if (pullSlotIndex < 0)
			pullSlotIndex = storedDocs.length;
		storedDocs.remove(doc);
		doc.setLoanFolderStorage(null);
		doc.setLoanFolderPullHost(this);
		doc.visible = true;
		doc.endFolderHoverPreview();
		doc.bringToFrontInLayer();
		doc.startDragFromExternal(mouseX, mouseY, true);
		doc.notifyDrawLayerChanged();
		if (pointInStorageWorld(mouseX, mouseY))
			snapPullingDoc(doc);
		layoutStoredDocuments();
		notifyStoredDocumentsChanged();
	}

	function snapPullingDoc(doc:DeskDocument):Void
	{
		var layout = getStoredDocLayoutRect();
		var stackX = layout.x + layout.w * 0.5;
		var stackY = layout.y + layout.h * 0.5;
		var off = pullSlotIndex * STORED_STACK_OFFSET;
		var paper = Std.downcast(doc, PrinterPaperDocument);
		if (paper != null)
			layoutStoredPaper(paper, stackX, stackY, layout.w, layout.h, off);
		else
		{
			var docW = layout.w * STORED_WIDTH_IN_POCKET_RATIO;
			doc.applyStoredDisplayWidth(docW);
			doc.setPosition(stackX - doc.width * 0.5 + off, stackY - doc.height * 0.5 + off);
			doc.clipRect = null;
			var bankDoc = Std.downcast(doc, BankDocument);
			if (bankDoc != null)
				bankDoc.refreshLoanFolderPocketTextOverlays();
			else
				syncStoredDocCameras(doc);
		}
	}

	public function shouldPullSnapInStorage(mx:Float, my:Float):Bool
	{
		return folderSpreadOpen && pointInStorageWorld(mx, my);
	}

	public function updatePullingDocument(doc:DeskDocument, mouse:FlxPoint):Bool
	{
		if (!folderSpreadOpen)
			return false;

		if (pointInStorageWorld(mouse.x, mouse.y))
		{
			snapPullingDoc(doc);
			return true;
		}

		return false;
	}

	public function onDocumentPulledOutside(doc:DeskDocument):Void
	{
		doc.setLoanFolderPullHost(null);
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null)
			bankDoc.clearLoanFolderPocketText();
		doc.discardCompactDragPreview();
		doc.setClosed();
		doc.refreshDisplaySize();
		doc.syncClosedDragAngle();
		var mouse = FlxG.mouse.getViewPosition();
		doc.recenterDragOnMouse(mouse.x, mouse.y);
		doc.notifyDrawLayerChanged();
	}

	public function finishPullDrag(doc:DeskDocument, mouseX:Float, mouseY:Float):Bool
	{
		doc.setLoanFolderPullHost(null);
		if (!folderSpreadOpen || !pointInStorageWorld(mouseX, mouseY) || !canAcceptDocument(doc))
			return false;

		storeDocument(doc);
		return true;
	}

	public function canAcceptDocument(doc:DeskDocument):Bool
	{
		if (!isStorableCopy(doc))
			return false;
		if (doc.isShredLocked())
			return false;
		if (doc.isStoredInLoanFolder())
			return false;
		if (doc.getLoanFolderPullHost() != null && doc.getLoanFolderPullHost() != this)
			return false;
		return true;
	}

	public function storeDocument(doc:DeskDocument):Void
	{
		if (!canAcceptDocument(doc) || !folderSpreadOpen)
			return;

		doc.discardCompactDragPreview();
		doc.cancelDragState();
		if (DeskDocument.currentDrag == doc)
			DeskDocument.currentDrag = null;
		doc.setLoanFolderPullHost(null);
		doc.setLoanFolderStorage(this);
		storedDocs.push(doc);
		doc.notifyDrawLayerChanged();
		doc.setActiveZone(EmployerTable);
		syncStoredVisibility();
		markStoredLayoutDirty();
		layoutStoredDocuments();
		notifyStoredDocumentsChanged();
	}

	public function seedStoredDocument(doc:DeskDocument):Void
	{
		if (!isStorableCopy(doc) || doc.isStoredInLoanFolder())
			return;

		doc.setLoanFolderStorage(this);
		storedDocs.push(doc);
		doc.setActiveZone(EmployerTable);
		syncStoredVisibility();
		markStoredLayoutDirty();
	}

	public function removeStoredDocument(doc:DeskDocument):Void
	{
		if (storedDocs.remove(doc))
		{
			doc.setLoanFolderStorage(null);
			doc.setLoanFolderPullHost(null);
			markStoredLayoutDirty();
			notifyStoredDocumentsChanged();
		}
	}

	function notifyStoredDocumentsChanged():Void
	{
		if (onStoredDocumentsChanged != null)
			onStoredDocumentsChanged();
	}

	function releaseAllStoredToDesk():Void
	{
		while (storedDocs.length > 0)
		{
			var doc = storedDocs.pop();
			doc.setLoanFolderStorage(null);
			doc.setLoanFolderPullHost(null);
			doc.visible = true;
			doc.setClosed();
			doc.setActiveZone(EmployerTable);
			doc.angle = TABLE_ANGLE;
			doc.refreshDisplaySize();
			doc.setPosition(x + width * 0.5 - doc.width * 0.5, y + height + 8);
		}
		notifyStoredDocumentsChanged();
	}

	public static function blocksOpenWhileDraggingOver(mx:Float, my:Float):Bool
	{
		var folder = activeFolder;
		if (folder == null || !folder.folderSpreadOpen || !folder.isBigOnEmployerTable())
			return false;
		return folder.pointInDepositHoverRegion(mx, my);
	}

	public static function shouldSnapToClientTableOnDrop(doc:DeskDocument, mx:Float, my:Float):Bool
	{
		var folder = activeFolder;
		if (folder == null || !folder.folderSpreadOpen || !folder.isBigOnEmployerTable())
			return false;
		if (Std.downcast(doc, LoanFolderDocument) != null)
			return false;
		if (Std.downcast(doc, MagnifyingGlass) != null)
			return false;
		if (folder.pointInStorageWorld(mx, my) && folder.canAcceptDocument(doc))
			return false;
		return folder.pointInDepositHoverRegion(mx, my);
	}

	public static function tryStoreDragged(doc:DeskDocument, mx:Float, my:Float):Bool
	{
		var folder = activeFolder;
		if (folder == null || !folder.folderSpreadOpen || !folder.isBigOnEmployerTable())
			return false;
		if (!folder.pointInStorageWorld(mx, my))
			return false;
		if (!folder.canAcceptDocument(doc))
			return false;

		folder.storeDocument(doc);
		return true;
	}

	public static function updateDragHover(doc:DeskDocument, mx:Float, my:Float):Void
	{
	}

	public static function clearDragHover(doc:DeskDocument):Void
	{
	}

	function isAnyOtherDocumentDragging():Bool
	{
		return DeskDocument.currentDrag != null;
	}

	function isStoredDocDragBlockedAt(point:FlxPoint):Bool
	{
		if (DeskDocument.frontmostDocumentAtPoint == null)
			return false;

		var front = DeskDocument.frontmostDocumentAtPoint(point);
		return front != null && front != this;
	}

	public function tweenSlideInFromEdge(duration:Float):Void
	{
		activeZone = EmployerTable;
		beginLargeDisplay();

		var targetX = zones.employerX + (zones.employerW - width) * 0.5;
		var targetY = zones.employerTableY + zones.employerTableH * 0.5 - height * 0.5;
		var startX = FlxG.width + width;
		setPosition(startX, targetY);
		notifyDrawLayerChanged();

		FlxTween.tween(this, {x: targetX, y: targetY}, duration, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				updateEmployerTableClip();
			}
		});
	}

	public function closeSpreadIfOpen():Void
	{
		if (!folderSpreadOpen)
			return;

		var right = x + width;
		var cy = y + height * 0.5;
		folderSpreadOpen = false;
		loadEmployerGraphic();
		applyDisplaySize();
		angle = 0;
		setPosition(right - width, cy - height * 0.5);
		updateEmployerTableClip();
		syncStoredVisibility();
		layoutStoredDocuments();
		reorderStoredCopiesAfterFolder();
		notifyStoredDocumentsChanged();
	}

	public function submitAndSlideOut(duration:Float, onComplete:Void->Void):Void
	{
		closeSpreadIfOpen();
		syncStoredVisibility();

		var targetX = FlxG.width + width;
		FlxTween.tween(this, {x: targetX}, duration, {
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				if (onComplete != null)
					onComplete();
			}
		});
	}

	public function destroyWithStoredDocuments():Void
	{
		if (activeFolder == this)
			activeFolder = null;

		while (storedDocs.length > 0)
		{
			var doc = storedDocs.pop();
			doc.setLoanFolderStorage(null);
			doc.setLoanFolderPullHost(null);
			doc.destroy();
		}

		onStoredDocumentsChanged = null;
		super.destroy();
	}

	function beginLargeDisplay():Void
	{
		folderSpreadOpen = false;
		loadedEmployerPath = null;
		clearEmployerClip();
		isOpen = true;
		loadEmployerGraphic();
		applyDisplaySize();
		angle = 0;
		syncStoredVisibility();
	}
}
