package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class BookDocument extends DeskDocument
{
	static inline var CLOSED_PATH = "static/closed_book.png";
	static inline var OPEN_PATH = "static/opened_book.png";
	static inline var ARROW_PATH = "static/arrow_right.png";
	static inline var EMBLEM_PATH = "static/lorian_emblem.png";
	static inline var OPEN_SIZE_MULTIPLIER = 7.0;
	static inline var CLOSED_WIDTH_RATIO = 0.25;
	static inline var PAGE_COUNT = 200;
	static inline var COVER_TITLE_PRIMARY = "Cool Math Bank";
	static inline var COVER_TITLE_SECONDARY = "Guide Book";
	static inline var COVER_SUBTITLE = "There you can find everything you need";
	static inline var COVER_SPONSOR = "This guide is sponsored by Republic of Loria and was written in 1967 year";
	static var TOC_LINK_LABELS = [
		"Introduction",
		"Questions to ask",
		"Quick Reference",
		"Exchange Rates"
	];
	static var TOC_LINK_PAGES = [3, 31, 33, 92];
	static var TOC_LINK_SPREADS = [1, 15, 16, 45];
	static var TOC_SUBTITLES = [
		{beforeLinkIndex: 0, text: "New Employees"},
		{beforeLinkIndex: 2, text: "Loan Processing"}
	];

	// Cover page (left page of first spread). Positive bias shifts content toward the spine/right.
	static inline var COVER_CONTENT_BIAS_NX = 0.07;
	static inline var COVER_EMBLEM_NY0 = 0.10;
	static inline var COVER_EMBLEM_NY1 = 0.34;
	static inline var COVER_EMBLEM_NX0 = 0.18;
	static inline var COVER_EMBLEM_NX1 = 0.74;
	static inline var COVER_TITLE_NX0 = 0.06;
	static inline var COVER_TITLE_NX1 = 0.88;
	static inline var COVER_TITLE_PRIMARY_NY = 0.38;
	static inline var COVER_TITLE_SECONDARY_NY = 0.46;
	static inline var COVER_SUBTITLE_NY = 0.53;
	static inline var COVER_SPONSOR_NY = 0.76;

	// Table of contents (right page of first spread).
	static inline var TOC_PAGE_BIAS_NX = 0.035;
	static inline var TOC_HEADING = "Contents";
	static inline var TOC_HEADING_NY = 0.10;
	static inline var TOC_LINK_NX0 = 0.03;
	static inline var TOC_LINK_NX1 = 0.94;
	static inline var TOC_BUTTON_FILL = 0x80345890;
	static inline var TOC_BUTTON_FILL_HOVER = 0xAA4468A8;
	static inline var TOC_BUTTON_BORDER = 0xCC142238;
	static inline var TOC_BUTTON_BORDER_HOVER = 0xEE0E1A30;
	static inline var TOC_LINK_TEXT_COLOR = 0xFFF0EEE8;
	static inline var TOC_LINK_TEXT_HOVER = 0xFFFFF4D8;
	static inline var TOC_LINK_PAGE_TEXT_COLOR = 0xFF000000;
	static inline var TOC_LINK1_NY0 = 0.17;

	// Navigation row near the bottom of each page; arrows sit toward the outer edges.
	static inline var NAV_ROW_NY0 = 0.82;
	static inline var NAV_ROW_NY1 = 0.92;
	static inline var LEFT_ARROW_NX0 = 0.18;
	static inline var LEFT_ARROW_NX1 = 0.32;
	static inline var CONTENTS_BUTTON_NX0 = 0.34;
	static inline var CONTENTS_BUTTON_NX1 = 0.58;
	static inline var CONTENTS_BUTTON_LABEL = "Contents";
	static inline var CONTENTS_BUTTON_FONT_RATIO = 0.015;
	static inline var CONTENTS_BUTTON_PAD_TOP_RATIO = 0.22;
	static inline var CONTENTS_BUTTON_PAD_BOTTOM_RATIO = 0.55;
	static inline var CONTENTS_BUTTON_MIN_ROW_RATIO = 0.62;
	static inline var RIGHT_ARROW_NX0 = 0.68;
	static inline var RIGHT_ARROW_NX1 = 0.82;
	static inline var LEFT_LABEL_NX0 = 0.58;
	static inline var LEFT_LABEL_NX1 = 0.88;
	static inline var RIGHT_LABEL_NX0 = 0.12;
	static inline var RIGHT_LABEL_NX1 = 0.42;

	static inline var INTRO_CONTENT_TOP_NY = 0.055;
	static inline var INTRO_CONTENT_BOTTOM_NY = 0.68;
	static inline var INTRO_CONTENT_NAV_GAP_NY = 0.035;
	static inline var INTRO_PAD_NX = 0.06;
	static inline var INTRO_LEFT_PAD_NX = 0.15;
	static inline var INTRO_RIGHT_PAD_NX = 0.12;
	static inline var INTRO_IMAGE_MAX_H_RATIO = 0.30;
	static inline var INTRO_IMAGE_MAX_H_RATIO_WITH_BODY = 0.22;
	static inline var INTRO_TITLE_SIZE_RATIO = 0.034;
	static inline var INTRO_BODY_SIZE_RATIO = 0.024;
	static inline var INTRO_MIN_TITLE_SIZE = 11;
	static inline var INTRO_MIN_BODY_SIZE = 10;
	static inline var INTRO_MIN_CAPTION_SIZE = 9;
	static inline var INTRO_TITLE_COLOR = 0xFF1E2838;
	static inline var INTRO_BODY_COLOR = 0xFF2A2218;
	static inline var INTRO_CAPTION_COLOR = 0xFF5A5048;
	static inline var INTRO_SECTION_COLOR = 0xFF4A4438;
	static inline var INTRO_QUESTION_COLOR = 0xFF6B4423;
	static inline var INTRO_SECTION_SIZE_RATIO = 0.03;
	static inline var INTRO_MIN_SECTION_SIZE = 10;
	static inline var MAX_BULLETS_PER_PAGE = 12;
	static inline var BULLET_SCAN_PAD = 4.0;

	var textLayer:FlxGroup;
	var leftPageLabel:FlxText;
	var rightPageLabel:FlxText;
	var coverEmblem:FlxSprite;
	var coverTitlePrimary:FlxText;
	var coverTitleSecondary:FlxText;
	var coverSubtitle:FlxText;
	var coverSponsor:FlxText;
	var tocHeading:FlxText;
	var tocSubtitleLabels:Array<FlxText>;
	var tocLinkButtons:Array<FlxSprite>;
	var tocLinkLayouts:Array<{w:Int, h:Int, radius:Int, border:Int}>;
	var tocLinks:Array<FlxText>;
	var tocLinkPageLabels:Array<FlxText>;
	var backArrow:FlxSprite;
	var forwardArrow:FlxSprite;
	var contentsNavButton:FlxSprite;
	var contentsNavLabel:FlxText;
	var contentsNavLayout:{w:Int, h:Int, radius:Int, border:Int};
	var contentsNavHovered = false;
	var leftIntroTitle:FlxText;
	var leftIntroBody:FlxText;
	var leftIntroCaption:FlxText;
	var leftIntroImage:FlxSprite;
	var rightIntroTitle:FlxText;
	var rightIntroBody:FlxText;
	var rightIntroCaption:FlxText;
	var rightIntroImage:FlxSprite;
	var leftBulletTexts:Array<FlxText>;
	var rightBulletTexts:Array<FlxText>;
	var leftBulletTags:Array<Null<String>>;
	var rightBulletTags:Array<Null<String>>;
	var spreadIndex = 0;
	var overlaysShown = false;
	var tocLinkHovered = -1;
	var tutorialInteractionLock = false;
	var hidePassportBookQuestion = false;
	var allowedTocLinkIndex = -1;
	var bookSlideTween:FlxTween;
	public var isBookSlideAnimating(default, null) = false;
	public var isBookSlideComplete(default, null) = false;
	public var slideAboveTableDocs(default, null) = false;
	var lastOverlayLayoutKey = -1.0;

	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		super(zones, layer, CLOSED_PATH, OPEN_PATH, OPEN_SIZE_MULTIPLIER);
		textLayer = layer;
		closedDisplayWidth = zones.leftW * CLOSED_WIDTH_RATIO;
		refreshDisplaySize();
		angle = 0;

		leftPageLabel = new FlxText(0, 0, 0, "");
		leftPageLabel.wordWrap = false;
		leftPageLabel.visible = false;
		textLayer.add(leftPageLabel);

		rightPageLabel = new FlxText(0, 0, 0, "");
		rightPageLabel.wordWrap = false;
		rightPageLabel.visible = false;
		textLayer.add(rightPageLabel);

		coverEmblem = new FlxSprite();
		coverEmblem.visible = false;
		coverEmblem.loadGraphic(EMBLEM_PATH);
		textLayer.add(coverEmblem);

		coverTitlePrimary = new FlxText(0, 0, 0, COVER_TITLE_PRIMARY);
		coverTitlePrimary.wordWrap = false;
		coverTitlePrimary.visible = false;
		textLayer.add(coverTitlePrimary);

		coverTitleSecondary = new FlxText(0, 0, 0, COVER_TITLE_SECONDARY);
		coverTitleSecondary.wordWrap = false;
		coverTitleSecondary.visible = false;
		textLayer.add(coverTitleSecondary);

		coverSubtitle = new FlxText(0, 0, 0, COVER_SUBTITLE);
		coverSubtitle.wordWrap = true;
		coverSubtitle.visible = false;
		textLayer.add(coverSubtitle);

		coverSponsor = new FlxText(0, 0, 0, COVER_SPONSOR);
		coverSponsor.wordWrap = true;
		coverSponsor.visible = false;
		textLayer.add(coverSponsor);

		tocHeading = new FlxText(0, 0, 0, TOC_HEADING);
		tocHeading.wordWrap = false;
		tocHeading.visible = false;
		textLayer.add(tocHeading);

		tocSubtitleLabels = [];
		for (entry in TOC_SUBTITLES)
		{
			var subtitle = new FlxText(0, 0, 0, entry.text);
			subtitle.wordWrap = false;
			subtitle.visible = false;
			tocSubtitleLabels.push(subtitle);
			textLayer.add(subtitle);
		}

		tocLinkButtons = [];
		tocLinkLayouts = [];
		tocLinks = [];
		tocLinkPageLabels = [];
		for (i in 0...TOC_LINK_LABELS.length)
		{
			var button = new FlxSprite();
			button.visible = false;
			tocLinkButtons.push(button);
			textLayer.add(button);

			var link = new FlxText(0, 0, 0, tocLinkLabelText(i));
			link.wordWrap = false;
			link.visible = false;
			tocLinks.push(link);
			textLayer.add(link);

			var pageLabel = new FlxText(0, 0, 0, tocLinkPageSuffixText(i));
			pageLabel.wordWrap = false;
			pageLabel.visible = false;
			tocLinkPageLabels.push(pageLabel);
			textLayer.add(pageLabel);
		}

		backArrow = new FlxSprite();
		backArrow.visible = false;
		loadBackArrowGraphic();
		textLayer.add(backArrow);

		forwardArrow = new FlxSprite();
		forwardArrow.visible = false;
		loadForwardArrowGraphic();
		textLayer.add(forwardArrow);

		contentsNavButton = new FlxSprite();
		contentsNavButton.visible = false;
		textLayer.add(contentsNavButton);

		contentsNavLabel = new FlxText(0, 0, 0, CONTENTS_BUTTON_LABEL);
		contentsNavLabel.wordWrap = false;
		contentsNavLabel.visible = false;
		textLayer.add(contentsNavLabel);

		leftIntroTitle = createIntroText(true);
		leftIntroBody = createIntroText(false);
		leftIntroCaption = createIntroText(false);
		leftIntroImage = createIntroImage();
		rightIntroTitle = createIntroText(true);
		rightIntroBody = createIntroText(false);
		rightIntroCaption = createIntroText(false);
		rightIntroImage = createIntroImage();

		leftBulletTexts = [];
		rightBulletTexts = [];
		leftBulletTags = [];
		rightBulletTags = [];
		for (i in 0...MAX_BULLETS_PER_PAGE)
		{
			leftBulletTexts.push(createIntroText(false));
			rightBulletTexts.push(createIntroText(false));
			leftBulletTags.push(null);
			rightBulletTags.push(null);
		}
	}

	function createIntroText(isTitle:Bool):FlxText
	{
		var text = new FlxText(0, 0, 0, "");
		text.wordWrap = true;
		text.visible = false;
		if (isTitle)
			text.bold = true;
		textLayer.add(text);
		return text;
	}

	function createIntroImage():FlxSprite
	{
		var image = new FlxSprite();
		image.visible = false;
		textLayer.add(image);
		return image;
	}

	function addIntroOverlaysToLayer(target:FlxGroup):Void
	{
		target.add(leftIntroTitle);
		target.add(leftIntroBody);
		target.add(leftIntroCaption);
		target.add(leftIntroImage);
		target.add(rightIntroTitle);
		target.add(rightIntroBody);
		target.add(rightIntroCaption);
		target.add(rightIntroImage);
		for (bullet in leftBulletTexts)
			target.add(bullet);
		for (bullet in rightBulletTexts)
			target.add(bullet);
	}

	function removeIntroOverlaysFromLayer(source:FlxGroup):Void
	{
		source.remove(leftIntroTitle, true);
		source.remove(leftIntroBody, true);
		source.remove(leftIntroCaption, true);
		source.remove(leftIntroImage, true);
		source.remove(rightIntroTitle, true);
		source.remove(rightIntroBody, true);
		source.remove(rightIntroCaption, true);
		source.remove(rightIntroImage, true);
		for (bullet in leftBulletTexts)
			source.remove(bullet, true);
		for (bullet in rightBulletTexts)
			source.remove(bullet, true);
	}

	function destroyIntroOverlays():Void
	{
		if (leftIntroTitle != null)
		{
			leftIntroTitle.destroy();
			leftIntroTitle = null;
		}
		if (leftIntroBody != null)
		{
			leftIntroBody.destroy();
			leftIntroBody = null;
		}
		if (leftIntroCaption != null)
		{
			leftIntroCaption.destroy();
			leftIntroCaption = null;
		}
		if (leftIntroImage != null)
		{
			leftIntroImage.destroy();
			leftIntroImage = null;
		}
		if (rightIntroTitle != null)
		{
			rightIntroTitle.destroy();
			rightIntroTitle = null;
		}
		if (rightIntroBody != null)
		{
			rightIntroBody.destroy();
			rightIntroBody = null;
		}
		if (rightIntroCaption != null)
		{
			rightIntroCaption.destroy();
			rightIntroCaption = null;
		}
		if (rightIntroImage != null)
		{
			rightIntroImage.destroy();
			rightIntroImage = null;
		}
		if (leftBulletTexts != null)
		{
			for (bullet in leftBulletTexts)
			{
				if (bullet != null)
					bullet.destroy();
			}
			leftBulletTexts = null;
		}
		if (rightBulletTexts != null)
		{
			for (bullet in rightBulletTexts)
			{
				if (bullet != null)
					bullet.destroy();
			}
			rightBulletTexts = null;
		}
	}

	function hideIntroOverlays():Void
	{
		leftIntroTitle.visible = false;
		leftIntroBody.visible = false;
		leftIntroCaption.visible = false;
		leftIntroImage.visible = false;
		rightIntroTitle.visible = false;
		rightIntroBody.visible = false;
		rightIntroCaption.visible = false;
		rightIntroImage.visible = false;
		leftIntroTitle.clipRect = null;
		leftIntroBody.clipRect = null;
		leftIntroCaption.clipRect = null;
		leftIntroImage.clipRect = null;
		rightIntroTitle.clipRect = null;
		rightIntroBody.clipRect = null;
		rightIntroCaption.clipRect = null;
		rightIntroImage.clipRect = null;
		hideBulletTexts(leftBulletTexts);
		hideBulletTexts(rightBulletTexts);
	}

	function hideBulletTexts(bullets:Array<FlxText>):Void
	{
		if (bullets == null)
			return;

		for (bullet in bullets)
		{
			bullet.visible = false;
			bullet.clipRect = null;
		}
	}

	function clearBulletTags(tags:Array<Null<String>>):Void
	{
		if (tags == null)
			return;

		for (i in 0...tags.length)
			tags[i] = null;
	}

	override function usesZoneAngleWhenClosed():Bool
	{
		return false;
	}

	override public function rejectsPrinterAndShredder():Bool
	{
		return true;
	}

	override function setClosed():Void
	{
		super.setClosed();
		updateOverlays();
	}

	override function setOpen():Void
	{
		super.setOpen();
		updateOverlays();
	}

	override function destroy():Void
	{
		if (leftPageLabel != null)
		{
			leftPageLabel.destroy();
			leftPageLabel = null;
		}
		if (rightPageLabel != null)
		{
			rightPageLabel.destroy();
			rightPageLabel = null;
		}
		if (backArrow != null)
		{
			backArrow.destroy();
			backArrow = null;
		}
		if (forwardArrow != null)
		{
			forwardArrow.destroy();
			forwardArrow = null;
		}
		if (contentsNavButton != null)
		{
			contentsNavButton.destroy();
			contentsNavButton = null;
		}
		if (contentsNavLabel != null)
		{
			contentsNavLabel.destroy();
			contentsNavLabel = null;
		}
		if (coverEmblem != null)
		{
			coverEmblem.destroy();
			coverEmblem = null;
		}
		if (coverTitlePrimary != null)
		{
			coverTitlePrimary.destroy();
			coverTitlePrimary = null;
		}
		if (coverTitleSecondary != null)
		{
			coverTitleSecondary.destroy();
			coverTitleSecondary = null;
		}
		if (coverSubtitle != null)
		{
			coverSubtitle.destroy();
			coverSubtitle = null;
		}
		if (coverSponsor != null)
		{
			coverSponsor.destroy();
			coverSponsor = null;
		}
		if (tocHeading != null)
		{
			tocHeading.destroy();
			tocHeading = null;
		}
		if (tocSubtitleLabels != null)
		{
			for (subtitle in tocSubtitleLabels)
				subtitle.destroy();
			tocSubtitleLabels = null;
		}
		if (tocLinkButtons != null)
		{
			for (button in tocLinkButtons)
				button.destroy();
			tocLinkButtons = null;
		}
		if (tocLinks != null)
		{
			for (link in tocLinks)
				link.destroy();
			tocLinks = null;
		}
		if (tocLinkPageLabels != null)
		{
			for (pageLabel in tocLinkPageLabels)
				pageLabel.destroy();
			tocLinkPageLabels = null;
		}
		destroyIntroOverlays();
		super.destroy();
	}

	override function update(elapsed:Float):Void
	{
		if (!scanLocked && !shredLocked && !snapping && isBigOnEmployerTable())
		{
			var mouse = FlxG.mouse.getViewPosition();
			if (FlxG.mouse.justPressed && DeskDocument.currentDrag == null && canHandlePageClickAt(mouse) && tryHandlePageClick(mouse))
				return;
		}

		super.update(elapsed);

		if (isStoredInLoanFolder() || isOnClientTable())
		{
			hideOverlays();
			return;
		}

		syncOverlayCameras();
		if (!scanLocked)
			updateOverlays();
	}

	override function hitsPoint(point:FlxPoint):Bool
	{
		if (!visible)
			return false;

		if (!isOpenOnEmployerTable())
			return super.hitsPoint(point);

		// Open book draws under the client desk, computer, and desk props.
		if (DeskDocument.isOverDeskPropsAtPoint != null && DeskDocument.isOverDeskPropsAtPoint(point))
			return false;

		if (DeskDocument.isAboveDrawLayerBlockingPoint != null && DeskDocument.isAboveDrawLayerBlockingPoint(point))
			return false;

		if (overlayBlocksPoint(point))
			return true;

		return overlapsPoint(point);
	}

	function overlayBlocksPoint(point:FlxPoint):Bool
	{
		if (!isOpen)
			return false;

		if (leftPageLabel.visible && leftPageLabel.overlapsPoint(point))
			return true;
		if (rightPageLabel.visible && rightPageLabel.overlapsPoint(point))
			return true;
		if (coverEmblem.visible && coverEmblem.overlapsPoint(point))
			return true;
		if (coverTitlePrimary.visible && coverTitlePrimary.overlapsPoint(point))
			return true;
		if (coverTitleSecondary.visible && coverTitleSecondary.overlapsPoint(point))
			return true;
		if (coverSubtitle.visible && coverSubtitle.overlapsPoint(point))
			return true;
		if (coverSponsor.visible && coverSponsor.overlapsPoint(point))
			return true;
		if (tocHeading.visible && tocHeading.overlapsPoint(point))
			return true;

		for (subtitle in tocSubtitleLabels)
			if (subtitle.visible && subtitle.overlapsPoint(point))
				return true;
		for (button in tocLinkButtons)
			if (button.visible && button.overlapsPoint(point))
				return true;
		for (link in tocLinks)
			if (link.visible && link.overlapsPoint(point))
				return true;

		if (leftIntroTitle.visible && leftIntroTitle.overlapsPoint(point))
			return true;
		if (leftIntroBody.visible && leftIntroBody.overlapsPoint(point))
			return true;
		if (leftIntroCaption.visible && leftIntroCaption.overlapsPoint(point))
			return true;
		if (leftIntroImage.visible && leftIntroImage.overlapsPoint(point))
			return true;
		if (rightIntroTitle.visible && rightIntroTitle.overlapsPoint(point))
			return true;
		if (rightIntroBody.visible && rightIntroBody.overlapsPoint(point))
			return true;
		if (rightIntroCaption.visible && rightIntroCaption.overlapsPoint(point))
			return true;
		if (rightIntroImage.visible && rightIntroImage.overlapsPoint(point))
			return true;

		for (bullet in leftBulletTexts)
			if (bullet.visible && bullet.overlapsPoint(point))
				return true;
		for (bullet in rightBulletTexts)
			if (bullet.visible && bullet.overlapsPoint(point))
				return true;

		if (backArrow.visible && backArrow.overlapsPoint(point))
			return true;
		if (contentsNavButton.visible && contentsNavButton.overlapsPoint(point))
			return true;
		if (forwardArrow.visible && forwardArrow.overlapsPoint(point))
			return true;

		return false;
	}

	public function setTutorialInteractionLock(locked:Bool, ?allowedTocIndex:Int = -1):Void
	{
		tutorialInteractionLock = locked;
		allowedTocLinkIndex = allowedTocIndex;
	}

	public function setHidePassportBookQuestion(hide:Bool):Void
	{
		if (hidePassportBookQuestion == hide)
			return;

		hidePassportBookQuestion = hide;
		if (isOpen)
			refreshOverlaysNow();
	}

	function filterBullets(bullets:Array<{?id:Null<String>, text:String}>):Array<{?id:Null<String>, text:String}>
	{
		if (!hidePassportBookQuestion)
			return bullets;

		var filtered:Array<{?id:Null<String>, text:String}> = [];
		for (entry in bullets)
		{
			if (entry.id == "passport_request")
				continue;
			filtered.push(entry);
		}
		return filtered;
	}

	public function isOnQuestionsSpread():Bool
	{
		return spreadIndex == 15;
	}

	public function openToQuestionsSpread():Void
	{
		spreadIndex = 15;
		setOpen();
		refreshDisplaySize();
		refreshOverlaysNow();
	}

	public function resetForNewDay():Void
	{
		resetBookSlideState();
		hideFromDesk();
	}

	public function placeClosedOnClientTable():Void
	{
		resetBookSlideState();
		prepareClientHandoff();
		placeOnClientTable();
		angle = 0;
	}

	function resetBookSlideState():Void
	{
		if (bookSlideTween != null)
		{
			bookSlideTween.cancel();
			bookSlideTween = null;
		}
		FlxTween.cancelTweensOf(this);
		dragging = false;
		snapping = false;
		scanLocked = false;
		isBookSlideAnimating = false;
		isBookSlideComplete = false;
		slideAboveTableDocs = false;
		spreadIndex = 0;
		tutorialInteractionLock = false;
		allowedTocLinkIndex = -1;
		tocLinkHovered = -1;
	}

	public function slideOpenToEmployerTableCenter(?onComplete:Void->Void):Void
	{
		if (bookSlideTween != null)
		{
			bookSlideTween.cancel();
			bookSlideTween = null;
		}
		FlxTween.cancelTweensOf(this);
		dragging = false;
		snapping = false;
		scanLocked = false;
		visible = true;
		isBookSlideAnimating = true;
		isBookSlideComplete = false;
		slideAboveTableDocs = true;
		spreadIndex = 0;

		activeZone = EmployerTable;
		setOpen();
		refreshDisplaySize();

		var endCenterX = zones.employerX + zones.employerW * 0.5;
		var endCenterY = zones.employerTableY + zones.employerTableH * 0.5;
		var targetX = endCenterX - width * 0.5;
		var targetY = endCenterY - height * 0.5;
		setPosition(FlxG.width + width, targetY);
		notifyDrawLayerChanged();

		bookSlideTween = FlxTween.tween(this, {
			x: targetX,
			y: targetY
		}, 0.75, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				bookSlideTween = null;
				setPosition(endCenterX - width * 0.5, endCenterY - height * 0.5);
				updateEmployerTableClip();
				refreshOverlaysNow();
				isBookSlideAnimating = false;
				isBookSlideComplete = true;
				slideAboveTableDocs = false;
				notifyDrawLayerChanged();
				if (onComplete != null)
					onComplete();
			}
		});
	}

	public function getTutorialHighlight(kind:String):Null<TutorialGuideRect>
	{
		return switch (kind)
		{
			case "toc_questions_to_ask":
				getTocLinkHighlight(1);
			case "questions_area":
				getQuestionsAreaHighlight();
			case "first_question":
				getFirstQuestionHighlight();
			case "book_frame":
				if (!isOpenOnEmployerTable())
					null;
				else
					{x: x, y: y, w: width, h: height};
			default:
				null;
		}
	}

	function getTocLinkHighlight(index:Int):Null<TutorialGuideRect>
	{
		if (!isOnCoverSpread() || index < 0 || index >= tocLinkButtons.length)
			return null;
		var btn = tocLinkButtons[index];
		if (!btn.visible)
			return null;
		return {x: btn.x, y: btn.y, w: btn.width, h: btn.height};
	}

	function getQuestionsAreaHighlight():Null<TutorialGuideRect>
	{
		if (!isOnQuestionsSpread())
			return null;
		return unionBulletHighlights(true);
	}

	function getFirstQuestionHighlight():Null<TutorialGuideRect>
	{
		if (!isOnQuestionsSpread())
			return null;
		for (i in 0...leftBulletTexts.length)
		{
			var bullet = leftBulletTexts[i];
			var tag = leftBulletTags[i];
			if (!bullet.visible || tag == null)
				continue;
			var bounds = textScanBounds(bullet, tag);
			return {x: bounds.x, y: bounds.y, w: bounds.w, h: bounds.h};
		}
		for (i in 0...rightBulletTexts.length)
		{
			var bullet = rightBulletTexts[i];
			var tag = rightBulletTags[i];
			if (!bullet.visible || tag == null)
				continue;
			var bounds = textScanBounds(bullet, tag);
			return {x: bounds.x, y: bounds.y, w: bounds.w, h: bounds.h};
		}
		return null;
	}

	function unionBulletHighlights(includeHeaders:Bool):Null<TutorialGuideRect>
	{
		var minX = 1e9;
		var minY = 1e9;
		var maxX = -1e9;
		var maxY = -1e9;
		var found = false;

		function consider(text:FlxText, tag:Null<String>):Void
		{
			if (!text.visible)
				return;
			if (!includeHeaders && tag == null)
				return;
			var bounds = textScanBounds(text, tag);
			minX = Math.min(minX, bounds.x);
			minY = Math.min(minY, bounds.y);
			maxX = Math.max(maxX, bounds.x + bounds.w);
			maxY = Math.max(maxY, bounds.y + bounds.h);
			found = true;
		}

		for (i in 0...leftBulletTexts.length)
			consider(leftBulletTexts[i], leftBulletTags[i]);
		for (i in 0...rightBulletTexts.length)
			consider(rightBulletTexts[i], rightBulletTags[i]);

		if (!found)
			return null;
		return {x: minX, y: minY, w: maxX - minX, h: maxY - minY};
	}

	public function canBeginDragAt(point:FlxPoint):Bool
	{
		if (tutorialInteractionLock)
			return false;

		if (!isOpenOnEmployerTable())
			return true;

		if (canGoBack() && pointInBackArrowRegion(point))
			return false;

		if (shouldShowContentsNav() && pointInContentsNavRegion(point))
			return false;

		if (canGoForward() && pointInForwardArrowRegion(point))
			return false;

		if (isOnCoverSpread() && pointInTocLinkRegion(point) >= 0)
			return false;

		return pointInBookDragRegion(point);
	}

	override public function resolveScanBoundsAt(point:FlxPoint):Null<ScanBounds>
	{
		if (!isOpenOnEmployerTable())
			return super.resolveScanBoundsAt(point);

		if (canGoBack() && pointInBackArrowRegion(point))
			return null;

		if (shouldShowContentsNav() && pointInContentsNavRegion(point))
			return null;

		if (canGoForward() && pointInForwardArrowRegion(point))
			return null;

		if (isOnCoverSpread() && pointInTocLinkRegion(point) >= 0)
			return null;

		var bulletBounds = scanBoundsForBulletAt(point);
		if (bulletBounds != null)
			return bulletBounds;

		return null;
	}

	function scanBoundsForBulletAt(point:FlxPoint):Null<ScanBounds>
	{
		for (i in 0...leftBulletTexts.length)
		{
			var bullet = leftBulletTexts[i];
			var tag = leftBulletTags[i];
			if (!bullet.visible || tag == null)
				continue;
			var bounds = textScanBounds(bullet, tag);
			if (pointInScanBounds(point, bounds))
				return bounds;
		}

		for (i in 0...rightBulletTexts.length)
		{
			var bullet = rightBulletTexts[i];
			var tag = rightBulletTags[i];
			if (!bullet.visible || tag == null)
				continue;
			var bounds = textScanBounds(bullet, tag);
			if (pointInScanBounds(point, bounds))
				return bounds;
		}

		return null;
	}

	function textScanBounds(text:FlxText, ?tag:Null<String>):ScanBounds
	{
		var glyphW = text.textField.textWidth;
		var glyphH = text.textField.textHeight;
		return {
			x: text.x,
			y: text.y,
			w: glyphW > 0 ? glyphW : text.width,
			h: glyphH > 0 ? glyphH : text.height,
			pad: BULLET_SCAN_PAD,
			tag: tag
		};
	}

	function pointInScanBounds(point:FlxPoint, bounds:ScanBounds):Bool
	{
		return point.x >= bounds.x && point.x < bounds.x + bounds.w
			&& point.y >= bounds.y && point.y < bounds.y + bounds.h;
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		if (isOpen)
			ensureOverlaysOnTop();
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		textLayer.remove(leftPageLabel, true);
		textLayer.remove(rightPageLabel, true);
		textLayer.remove(coverEmblem, true);
		textLayer.remove(coverTitlePrimary, true);
		textLayer.remove(coverTitleSecondary, true);
		textLayer.remove(coverSubtitle, true);
		textLayer.remove(coverSponsor, true);
		textLayer.remove(tocHeading, true);
		for (subtitle in tocSubtitleLabels)
			textLayer.remove(subtitle, true);
		for (button in tocLinkButtons)
			textLayer.remove(button, true);
		for (link in tocLinks)
			textLayer.remove(link, true);
		for (pageLabel in tocLinkPageLabels)
			textLayer.remove(pageLabel, true);
		textLayer.remove(backArrow, true);
		textLayer.remove(forwardArrow, true);
		textLayer.remove(contentsNavButton, true);
		textLayer.remove(contentsNavLabel, true);
		removeIntroOverlaysFromLayer(textLayer);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		target.add(leftPageLabel);
		target.add(rightPageLabel);
		target.add(coverEmblem);
		target.add(coverTitlePrimary);
		target.add(coverTitleSecondary);
		target.add(coverSubtitle);
		target.add(coverSponsor);
		target.add(tocHeading);
		for (subtitle in tocSubtitleLabels)
			target.add(subtitle);
		for (button in tocLinkButtons)
			target.add(button);
		for (link in tocLinks)
			target.add(link);
		for (pageLabel in tocLinkPageLabels)
			target.add(pageLabel);
		target.add(backArrow);
		target.add(forwardArrow);
		target.add(contentsNavButton);
		target.add(contentsNavLabel);
		addIntroOverlaysToLayer(target);
	}

	function isBigOnEmployerTable():Bool
	{
		return isOpen && (activeZone == EmployerTable || overlapsEmployerTable());
	}

	function leftPageNumber():Int
	{
		return spreadIndex * 2 + 1;
	}

	function rightPageNumber():Int
	{
		return spreadIndex * 2 + 2;
	}

	function canGoBack():Bool
	{
		return spreadIndex > 0;
	}

	function shouldShowContentsNav():Bool
	{
		return spreadIndex >= 1;
	}

	function canGoForward():Bool
	{
		return rightPageNumber() < PAGE_COUNT;
	}

	function isOnCoverSpread():Bool
	{
		return spreadIndex == 0;
	}

	function canHandlePageClickAt(point:FlxPoint):Bool
	{
		if (DeskDocument.magnifierHitsPoint != null && DeskDocument.magnifierHitsPoint(point))
			return false;

		if (DeskDocument.isOverDeskPropsAtPoint != null && DeskDocument.isOverDeskPropsAtPoint(point))
			return false;

		if (isOpenOnEmployerTable()
			&& DeskDocument.isAboveDrawLayerBlockingPoint != null
			&& DeskDocument.isAboveDrawLayerBlockingPoint(point))
			return false;

		if (DeskDocument.isTopmostAtPoint != null)
			return DeskDocument.isTopmostAtPoint(this, point);

		return isFrontmostAtPoint(point);
	}

	function tryHandlePageClick(point:FlxPoint):Bool
	{
		if (tutorialInteractionLock)
		{
			if (isOnCoverSpread())
			{
				var lockedLink = pointInTocLinkRegion(point);
				if (lockedLink == allowedTocLinkIndex && lockedLink >= 0 && lockedLink < TOC_LINK_SPREADS.length)
				{
					spreadIndex = TOC_LINK_SPREADS[lockedLink];
					updateOverlays();
					return true;
				}
			}
			return false;
		}

		if (isOnCoverSpread())
		{
			var linkIndex = pointInTocLinkRegion(point);
			if (linkIndex >= 0 && linkIndex < TOC_LINK_SPREADS.length)
			{
				spreadIndex = TOC_LINK_SPREADS[linkIndex];
				updateOverlays();
				return true;
			}
		}

		if (canGoForward() && pointInForwardArrowRegion(point))
		{
			spreadIndex++;
			updateOverlays();
			return true;
		}

		if (canGoBack() && pointInBackArrowRegion(point))
		{
			spreadIndex--;
			updateOverlays();
			return true;
		}

		if (shouldShowContentsNav() && pointInContentsNavRegion(point))
		{
			spreadIndex = 0;
			updateOverlays();
			return true;
		}

		return false;
	}

	function pointInContentsNavRegion(point:FlxPoint):Bool
	{
		return pointInPageNavRegion(point, false, CONTENTS_BUTTON_NX0, CONTENTS_BUTTON_NX1);
	}

	function pointInTocLinkRegion(point:FlxPoint):Int
	{
		if (!isOnCoverSpread())
			return -1;

		for (i in 0...tocLinkButtons.length)
		{
			if (tocLinkEntryHitsPoint(i, point))
				return i;
		}

		return -1;
	}

	function pointInBookDragRegion(point:FlxPoint):Bool
	{
		var local = worldToLocal(point.x, point.y);
		if (local == null)
			return false;

		var hit = local.x >= 0 && local.x <= frameWidth && local.y >= 0 && local.y <= frameHeight;
		local.put();
		return hit;
	}

	function pointInForwardArrowRegion(point:FlxPoint):Bool
	{
		return pointInPageNavRegion(point, true, RIGHT_ARROW_NX0, RIGHT_ARROW_NX1);
	}

	function pointInBackArrowRegion(point:FlxPoint):Bool
	{
		return pointInPageNavRegion(point, false, LEFT_ARROW_NX0, LEFT_ARROW_NX1);
	}

	function pointInPageNavRegion(point:FlxPoint, rightPage:Bool, nx0:Float, nx1:Float, ?ny0:Float, ?ny1:Float):Bool
	{
		var local = worldToLocal(point.x, point.y);
		if (local == null)
			return false;

		var halfW = frameWidth * 0.5;
		var pageX0 = rightPage ? halfW : 0.0;
		var pageW = halfW;
		var rowY0 = ny0 != null ? ny0 : NAV_ROW_NY0;
		var rowY1 = ny1 != null ? ny1 : NAV_ROW_NY1;
		var hit = local.x >= pageX0 + pageW * nx0 && local.x <= pageX0 + pageW * nx1
			&& local.y >= frameHeight * rowY0 && local.y <= frameHeight * rowY1;
		local.put();
		return hit;
	}

	function worldToLocal(px:Float, py:Float):Null<FlxPoint>
	{
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		if (sx <= 0 || sy <= 0)
			return null;

		return FlxPoint.get((px - x) / sx, (py - y) / sy);
	}

	function loadBackArrowGraphic():Void
	{
		backArrow.loadGraphic(ARROW_PATH);
		backArrow.flipX = true;
	}

	function loadForwardArrowGraphic():Void
	{
		forwardArrow.loadGraphic(ARROW_PATH);
		forwardArrow.flipX = false;
	}

	public function refreshOverlaysNow():Void
	{
		lastOverlayLayoutKey = -1.0;
		updateOverlays(true);
	}

	function shouldKeepOverlaysDuringBlock():Bool
	{
		return isOpen && activeZone == EmployerTable && BeginningDayOverlay.isGameRevealInProgress();
	}

	function updateOverlays(?force:Bool = false):Void
	{
		if (!force && DeskDocument.blocksOverlayUpdates())
		{
			if (!shouldKeepOverlaysDuringBlock())
			{
				hideOverlays();
				return;
			}
		}

		if (isOpenOnEmployerTable())
			refreshEmployerTableClip();

		var shouldShow = isOpen && activeZone == EmployerTable;
		if (shouldShow && isOpenOnEmployerTable() && !hasEmployerClipReady())
			shouldShow = false;

		var showCover = shouldShow && isOnCoverSpread();
		if (overlaysShown != shouldShow)
		{
			overlaysShown = shouldShow;
			leftPageLabel.visible = shouldShow && !showCover;
			rightPageLabel.visible = shouldShow;
			coverEmblem.visible = showCover;
			coverTitlePrimary.visible = showCover;
			coverTitleSecondary.visible = showCover;
			coverSubtitle.visible = showCover;
			coverSponsor.visible = showCover;
			tocHeading.visible = showCover;
			for (subtitle in tocSubtitleLabels)
				subtitle.visible = showCover;
			for (button in tocLinkButtons)
				button.visible = showCover;
			for (link in tocLinks)
				link.visible = showCover;
			for (pageLabel in tocLinkPageLabels)
				pageLabel.visible = showCover;
			backArrow.visible = shouldShow && canGoBack();
			forwardArrow.visible = shouldShow && canGoForward();
			contentsNavButton.visible = shouldShow && shouldShowContentsNav();
			contentsNavLabel.visible = shouldShow && shouldShowContentsNav();
		}
		else if (shouldShow)
		{
			leftPageLabel.visible = !showCover;
			rightPageLabel.visible = true;
			coverEmblem.visible = showCover;
			coverTitlePrimary.visible = showCover;
			coverTitleSecondary.visible = showCover;
			coverSubtitle.visible = showCover;
			coverSponsor.visible = showCover;
			tocHeading.visible = showCover;
			for (subtitle in tocSubtitleLabels)
				subtitle.visible = showCover;
			for (button in tocLinkButtons)
				button.visible = showCover;
			for (link in tocLinks)
				link.visible = showCover;
			for (pageLabel in tocLinkPageLabels)
				pageLabel.visible = showCover;
			backArrow.visible = canGoBack();
			forwardArrow.visible = canGoForward();
			contentsNavButton.visible = shouldShowContentsNav();
			contentsNavLabel.visible = shouldShowContentsNav();
		}

		if (!shouldShow)
		{
			lastOverlayLayoutKey = -1.0;
			hideIntroOverlays();
			clearAllOverlayClips();
			return;
		}

		var layoutKey = x + y * 10000 + width * 100 + height + spreadIndex * 1000000 + (showCover ? 1 : 0);
		if (layoutKey != lastOverlayLayoutKey)
		{
			lastOverlayLayoutKey = layoutKey;

			ensureOverlaysOnTop();
			if (showCover)
			{
				layoutCoverPage();
				layoutTocLinks();
				layoutRightPageLabel();
				hideIntroOverlays();
			}
			else
			{
				tocLinkHovered = -1;
				contentsNavHovered = false;
				coverEmblem.visible = false;
				coverTitlePrimary.visible = false;
				coverTitleSecondary.visible = false;
				coverSubtitle.visible = false;
				coverSponsor.visible = false;
				tocHeading.visible = false;
				for (subtitle in tocSubtitleLabels)
					subtitle.visible = false;
				for (button in tocLinkButtons)
					button.visible = false;
				for (link in tocLinks)
					link.visible = false;
				for (pageLabel in tocLinkPageLabels)
					pageLabel.visible = false;
				hideIntroOverlays();
				layoutPageLabels();
				layoutIntroPages();
			}
			layoutBackArrow();
			layoutContentsNavButton();
			layoutForwardArrow();
		}

		updateBookLinkHover(FlxG.mouse.getViewPosition());
	}

	function updateBookLinkHover(mouse:FlxPoint):Void
	{
		if (!overlaysShown)
			return;

		if (isOnCoverSpread())
		{
			if (contentsNavHovered)
			{
				contentsNavHovered = false;
				if (contentsNavButton.visible)
					applyContentsNavVisual(false);
			}
			updateTocLinkHover(mouse);
		}
		else
		{
			if (tocLinkHovered >= 0)
			{
				applyTocLinkVisual(tocLinkHovered, false);
				tocLinkHovered = -1;
			}
			updateContentsNavHover(mouse);
		}
	}

	function hideOverlays():Void
	{
		tocLinkHovered = -1;
		contentsNavHovered = false;
		overlaysShown = false;
		lastOverlayLayoutKey = -1.0;
		leftPageLabel.visible = false;
		rightPageLabel.visible = false;
		coverEmblem.visible = false;
		coverTitlePrimary.visible = false;
		coverTitleSecondary.visible = false;
		coverSubtitle.visible = false;
		coverSponsor.visible = false;
		tocHeading.visible = false;
		for (subtitle in tocSubtitleLabels)
			subtitle.visible = false;
		for (button in tocLinkButtons)
			button.visible = false;
		for (link in tocLinks)
			link.visible = false;
		for (pageLabel in tocLinkPageLabels)
			pageLabel.visible = false;
		backArrow.visible = false;
		forwardArrow.visible = false;
		contentsNavButton.visible = false;
		contentsNavLabel.visible = false;
		hideIntroOverlays();
		clearAllOverlayClips();
	}

	function clearAllOverlayClips():Void
	{
		leftPageLabel.clipRect = null;
		rightPageLabel.clipRect = null;
		coverEmblem.clipRect = null;
		coverTitlePrimary.clipRect = null;
		coverTitleSecondary.clipRect = null;
		coverSubtitle.clipRect = null;
		coverSponsor.clipRect = null;
		tocHeading.clipRect = null;
		for (subtitle in tocSubtitleLabels)
			subtitle.clipRect = null;
		for (button in tocLinkButtons)
			button.clipRect = null;
		for (link in tocLinks)
			link.clipRect = null;
		for (pageLabel in tocLinkPageLabels)
			pageLabel.clipRect = null;
		backArrow.clipRect = null;
		forwardArrow.clipRect = null;
		contentsNavButton.clipRect = null;
		contentsNavLabel.clipRect = null;
		leftIntroTitle.clipRect = null;
		leftIntroBody.clipRect = null;
		leftIntroCaption.clipRect = null;
		leftIntroImage.clipRect = null;
		rightIntroTitle.clipRect = null;
		rightIntroBody.clipRect = null;
		rightIntroCaption.clipRect = null;
		rightIntroImage.clipRect = null;
	}

	function layoutCoverPage():Void
	{
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var titleFieldW = halfW * (COVER_TITLE_NX1 - COVER_TITLE_NX0) * sx;
		var titleX = leftPageCoverX(COVER_TITLE_NX0, halfW, sx);

		var emblemBoxW = halfW * (COVER_EMBLEM_NX1 - COVER_EMBLEM_NX0) * sx;
		var emblemBoxH = frameHeight * (COVER_EMBLEM_NY1 - COVER_EMBLEM_NY0) * sy;
		var emblemAspect = coverEmblem.frameHeight > 0 ? coverEmblem.frameWidth / coverEmblem.frameHeight : 1.0;
		var emblemW = emblemBoxW;
		var emblemH = emblemW / emblemAspect;
		if (emblemH > emblemBoxH)
		{
			emblemH = emblemBoxH;
			emblemW = emblemH * emblemAspect;
		}
		coverEmblem.setGraphicSize(Std.int(Math.max(1, emblemW)), Std.int(Math.max(1, emblemH)));
		coverEmblem.updateHitbox();
		var emblemBoxX = leftPageCoverX(COVER_EMBLEM_NX0, halfW, sx);
		var emblemBoxY = y + frameHeight * COVER_EMBLEM_NY0 * sy;
		coverEmblem.setPosition(
			emblemBoxX + (emblemBoxW - emblemW) * 0.5,
			emblemBoxY + (emblemBoxH - emblemH) * 0.5
		);
		coverEmblem.angle = angle;
		syncBookOverlayClip(coverEmblem);

		var primaryFontSize = Std.int(Math.max(16, frameHeight * sy * 0.042));
		coverTitlePrimary.text = COVER_TITLE_PRIMARY;
		coverTitlePrimary.setFormat(null, primaryFontSize, FlxColor.fromRGB(28, 52, 96), "center");
		coverTitlePrimary.setBorderStyle(NONE, 0x00000000, 0);
		coverTitlePrimary.bold = true;
		coverTitlePrimary.italic = false;
		coverTitlePrimary.fieldWidth = titleFieldW;
		coverTitlePrimary.autoSize = false;
		coverTitlePrimary.setPosition(titleX, y + frameHeight * COVER_TITLE_PRIMARY_NY * sy);
		syncBookOverlayClip(coverTitlePrimary);

		var secondaryFontSize = Std.int(Math.max(13, frameHeight * sy * 0.034));
		coverTitleSecondary.text = COVER_TITLE_SECONDARY;
		coverTitleSecondary.setFormat(null, secondaryFontSize, FlxColor.fromRGB(130, 88, 28), "center");
		coverTitleSecondary.setBorderStyle(NONE, 0x00000000, 0);
		coverTitleSecondary.bold = false;
		coverTitleSecondary.italic = true;
		coverTitleSecondary.fieldWidth = titleFieldW;
		coverTitleSecondary.autoSize = false;
		coverTitleSecondary.setPosition(titleX, y + frameHeight * COVER_TITLE_SECONDARY_NY * sy);
		syncBookOverlayClip(coverTitleSecondary);

		var subtitleFontSize = Std.int(Math.max(10, frameHeight * sy * 0.024));
		coverSubtitle.text = COVER_SUBTITLE;
		coverSubtitle.setFormat(null, subtitleFontSize, FlxColor.fromRGB(75, 65, 55), "center");
		coverSubtitle.setBorderStyle(NONE, 0x00000000, 0);
		coverSubtitle.bold = false;
		coverSubtitle.italic = false;
		coverSubtitle.fieldWidth = titleFieldW;
		coverSubtitle.autoSize = false;
		coverSubtitle.setPosition(titleX, y + frameHeight * COVER_SUBTITLE_NY * sy);
		syncBookOverlayClip(coverSubtitle);

		var sponsorFontSize = Std.int(Math.max(8, frameHeight * sy * 0.018));
		coverSponsor.text = COVER_SPONSOR;
		coverSponsor.setFormat(null, sponsorFontSize, FlxColor.fromRGB(90, 80, 70), "center");
		coverSponsor.setBorderStyle(NONE, 0x00000000, 0);
		coverSponsor.bold = false;
		coverSponsor.italic = true;
		coverSponsor.fieldWidth = titleFieldW;
		coverSponsor.autoSize = false;
		coverSponsor.setPosition(titleX, y + frameHeight * COVER_SPONSOR_NY * sy);
		syncBookOverlayClip(coverSponsor);
	}

	function leftPageCoverX(nx:Float, halfW:Float, sx:Float):Float
	{
		return x + halfW * (nx + COVER_CONTENT_BIAS_NX) * sx;
	}

	function rightPageCoverX(nx:Float, halfW:Float, sx:Float):Float
	{
		return x + (halfW + halfW * (nx + TOC_PAGE_BIAS_NX)) * sx;
	}

	function tocLinkLabelText(index:Int):String
	{
		if (index < 0 || index >= TOC_LINK_LABELS.length)
			return "";
		return TOC_LINK_LABELS[index];
	}

	function tocLinkPageSuffixText(index:Int):String
	{
		if (index < 0 || index >= TOC_LINK_LABELS.length)
			return "";

		var page = index < TOC_LINK_PAGES.length ? TOC_LINK_PAGES[index] : 0;
		return '- page $page';
	}

	function insideRoundedRect(px:Float, py:Float, w:Int, h:Int, radius:Int, ?inset:Int = 0):Bool
	{
		var x0 = inset;
		var y0 = inset;
		var x1 = w - 1 - inset;
		var y1 = h - 1 - inset;
		var r = Std.int(Math.max(0, radius - inset));
		if (x1 < x0 || y1 < y0 || px < x0 || py < y0 || px > x1 || py > y1)
			return false;

		if (px >= x0 + r && px <= x1 - r)
			return true;
		if (py >= y0 + r && py <= y1 - r)
			return true;

		var cx = px < x0 + r ? x0 + r : x1 - r;
		var cy = py < y0 + r ? y0 + r : y1 - r;
		var dx = px - cx;
		var dy = py - cy;
		return dx * dx + dy * dy <= r * r;
	}

	function drawRoundedTocLinkButton(button:FlxSprite, width:Int, height:Int, radius:Int, borderSize:Int, ?hovered:Bool = false):Void
	{
		var fillColor = hovered ? TOC_BUTTON_FILL_HOVER : TOC_BUTTON_FILL;
		var borderColor = hovered ? TOC_BUTTON_BORDER_HOVER : TOC_BUTTON_BORDER;
		button.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		var pixels = button.pixels;
		for (py in 0...height)
		{
			for (px in 0...width)
			{
				if (!insideRoundedRect(px, py, width, height, radius))
					continue;

				var color = insideRoundedRect(px, py, width, height, radius, borderSize)
					? fillColor
					: borderColor;
				pixels.setPixel32(px, py, color);
			}
		}
		button.dirty = true;
		button.updateHitbox();
	}

	function applyTocLinkVisual(index:Int, hovered:Bool):Void
	{
		if (index < 0 || index >= tocLinkButtons.length || index >= tocLinkLayouts.length || index >= tocLinks.length)
			return;

		var button = tocLinkButtons[index];
		var link = tocLinks[index];
		var layout = tocLinkLayouts[index];
		var textColor = hovered ? TOC_LINK_TEXT_HOVER : TOC_LINK_TEXT_COLOR;
		drawRoundedTocLinkButton(button, layout.w, layout.h, layout.radius, layout.border, hovered);
		link.color = textColor;

	}

	function tocLinkEntryHitsPoint(index:Int, point:FlxPoint):Bool
	{
		if (index < 0 || index >= tocLinkButtons.length)
			return false;

		var button = tocLinkButtons[index];
		return button.visible && button.overlapsPoint(point);
	}

	function findTocLinkHoverIndex(mouse:FlxPoint):Int
	{
		for (i in 0...tocLinkButtons.length)
		{
			if (tocLinkEntryHitsPoint(i, mouse))
				return i;
		}
		return -1;
	}

	function updateTocLinkHover(mouse:FlxPoint):Void
	{
		var hovered = findTocLinkHoverIndex(mouse);
		if (hovered == tocLinkHovered)
			return;

		if (tocLinkHovered >= 0)
			applyTocLinkVisual(tocLinkHovered, false);

		tocLinkHovered = hovered;

		if (tocLinkHovered >= 0)
			applyTocLinkVisual(tocLinkHovered, true);
	}

	function measureTocLinkTextWidth(link:FlxText, text:String, fontSize:Int):Int
	{
		link.text = text;
		link.setFormat(null, fontSize, FlxColor.WHITE, "left");
		link.setBorderStyle(NONE, 0x00000000, 0);
		link.bold = false;
		link.wordWrap = false;
		link.autoSize = true;
		link.updateHitbox();
		return Std.int(Math.ceil(link.width));
	}

	function layoutTocSubtitlesBeforeLink(linkIndex:Int, linkX:Float, fieldW:Float, headingFontSize:Int, linkRowGap:Float, startY:Float):Float
	{
		var nextY = startY;
		for (subIdx in 0...TOC_SUBTITLES.length)
		{
			var entry = TOC_SUBTITLES[subIdx];
			if (entry.beforeLinkIndex != linkIndex || subIdx >= tocSubtitleLabels.length)
				continue;

			var subtitle = tocSubtitleLabels[subIdx];
			var subtitleFontSize = Std.int(Math.max(10, headingFontSize * 0.82));
			var gapBefore = linkRowGap * 0.55;
			var gapAfter = linkRowGap * 1.0;

			nextY += gapBefore;
			subtitle.text = entry.text;
			subtitle.setFormat(null, subtitleFontSize, FlxColor.fromRGB(55, 45, 35), "left");
			subtitle.setBorderStyle(NONE, 0x00000000, 0);
			subtitle.bold = true;
			subtitle.italic = true;
			subtitle.fieldWidth = fieldW;
			subtitle.autoSize = false;
			subtitle.visible = true;
			subtitle.setPosition(linkX, nextY);
			syncBookOverlayClip(subtitle);
			nextY += subtitleFontSize * 1.15 + gapAfter;
		}
		return nextY;
	}

	function layoutTocLinks():Void
	{
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var linkFontSize = Std.int(Math.max(8, frameHeight * sy * 0.020)) + 2;
		var pageFontSize = Std.int(Math.max(8, linkFontSize - 1));
		var headingFontSize = Std.int(Math.max(14, frameHeight * sy * 0.036));
		var pageFieldW = halfW * (TOC_LINK_NX1 - TOC_LINK_NX0) * sx;
		var linkX = rightPageCoverX(TOC_LINK_NX0, halfW, sx);
		var textPaddingX = linkFontSize * 0.5;
		var textPaddingTop = linkFontSize * 0.22;
		var textPaddingBottom = linkFontSize * 0.55;
		var pageSuffixGap = linkFontSize * 0.12;
		var borderSize = Std.int(Math.max(1, sx));
		var linkRowGap = linkFontSize * 0.5;
		var nextLinkY = y + frameHeight * TOC_LINK1_NY0 * sy;

		tocHeading.text = TOC_HEADING;
		tocHeading.setFormat(null, headingFontSize, FlxColor.fromRGB(40, 30, 20), "left");
		tocHeading.setBorderStyle(NONE, 0x00000000, 0);
		tocHeading.bold = true;
		tocHeading.fieldWidth = pageFieldW;
		tocHeading.autoSize = false;
		tocHeading.visible = true;
		tocHeading.setPosition(linkX, y + frameHeight * TOC_HEADING_NY * sy);
		syncBookOverlayClip(tocHeading);

		for (subtitle in tocSubtitleLabels)
			subtitle.visible = false;

		for (i in 0...tocLinks.length)
		{
			nextLinkY = layoutTocSubtitlesBeforeLink(i, linkX, pageFieldW, headingFontSize, linkRowGap, nextLinkY);

			var link = tocLinks[i];
			var button = i < tocLinkButtons.length ? tocLinkButtons[i] : null;
			var pageLabel = i < tocLinkPageLabels.length ? tocLinkPageLabels[i] : null;
			if (button == null)
			{
				link.visible = false;
				if (pageLabel != null)
					pageLabel.visible = false;
				continue;
			}

			var label = tocLinkLabelText(i);
			var pageSuffix = tocLinkPageSuffixText(i);
			var textW = measureTocLinkTextWidth(link, label, linkFontSize);
			var buttonW = Std.int(Math.max(1, textW + textPaddingX * 2));
			var buttonH = Std.int(linkFontSize + textPaddingTop + textPaddingBottom);
			var cornerRadius = Std.int(Math.min(buttonH * 0.42, Math.max(3, linkFontSize * 0.45)));
			var buttonY = nextLinkY;
			var textY = buttonY + textPaddingTop;
			var layout = {w: buttonW, h: buttonH, radius: cornerRadius, border: borderSize};
			if (tocLinkLayouts.length <= i)
				tocLinkLayouts.push(layout);
			else
				tocLinkLayouts[i] = layout;

			var isHovered = i == tocLinkHovered;
			var textColor = isHovered ? TOC_LINK_TEXT_HOVER : TOC_LINK_TEXT_COLOR;
			drawRoundedTocLinkButton(button, buttonW, buttonH, cornerRadius, borderSize, isHovered);
			button.visible = true;
			button.setPosition(linkX, buttonY);
			button.angle = angle;
			syncBookOverlayClip(button);

			link.text = label;
			link.setFormat(null, linkFontSize, textColor, "left");
			link.setBorderStyle(NONE, 0x00000000, 0);
			link.bold = false;
			link.wordWrap = false;
			link.autoSize = false;
			link.fieldWidth = textW;
			link.width = textW;
			link.height = buttonH;
			link.updateHitbox();
			link.visible = true;
			link.setPosition(linkX + textPaddingX, textY);
			syncBookOverlayClip(link);

			if (pageLabel != null)
			{
				var suffixW = measureTocLinkTextWidth(pageLabel, pageSuffix, pageFontSize);
				pageLabel.text = pageSuffix;
				pageLabel.setFormat(null, pageFontSize, TOC_LINK_PAGE_TEXT_COLOR, "left");
				pageLabel.setBorderStyle(NONE, 0x00000000, 0);
				pageLabel.bold = false;
				pageLabel.wordWrap = false;
				pageLabel.autoSize = false;
				pageLabel.fieldWidth = suffixW;
				pageLabel.width = suffixW;
				pageLabel.height = buttonH;
				pageLabel.updateHitbox();
				pageLabel.visible = true;
				pageLabel.setPosition(
					linkX + buttonW + pageSuffixGap,
					textY + (linkFontSize - pageFontSize) * 0.5
				);
				syncBookOverlayClip(pageLabel);
			}

			nextLinkY = buttonY + buttonH + linkRowGap;
		}

	}

	function syncBookOverlayClip(overlay:FlxSprite):Void
	{
		if (!visible)
		{
			overlay.clipRect = null;
			return;
		}

		// Clip to the full open book, not the employer-table slice, so both pages stay readable.
		applyWorldClipRect(overlay, x, y, x + width, y + height);
	}

	function pageLabelFontSize():Int
	{
		var sy = Math.abs(scale.y);
		return Std.int(Math.max(12, frameHeight * sy * 0.028));
	}

	function pageLabelY():Float
	{
		var sy = Math.abs(scale.y);
		return y + frameHeight * ((NAV_ROW_NY0 + NAV_ROW_NY1) * 0.5 - 0.035) * sy;
	}

	function layoutLeftPageLabel():Void
	{
		var sx = Math.abs(scale.x);
		var halfW = frameWidth * 0.5;
		var fontSize = pageLabelFontSize();
		var labelFieldW = halfW * 0.42 * sx;

		leftPageLabel.text = 'Page ${leftPageNumber()}';
		leftPageLabel.setFormat(null, fontSize, FlxColor.fromRGB(40, 30, 20), "right");
		leftPageLabel.setBorderStyle(NONE, 0x00000000, 0);
		leftPageLabel.fieldWidth = labelFieldW;
		leftPageLabel.setPosition(
			x + halfW * (LEFT_LABEL_NX1 - 0.42) * sx,
			pageLabelY()
		);
		syncBookOverlayClip(leftPageLabel);
	}

	function layoutRightPageLabel():Void
	{
		var sx = Math.abs(scale.x);
		var halfW = frameWidth * 0.5;
		var fontSize = pageLabelFontSize();
		var labelFieldW = halfW * 0.42 * sx;

		rightPageLabel.text = 'Page ${rightPageNumber()}';
		rightPageLabel.setFormat(null, fontSize, FlxColor.fromRGB(40, 30, 20), "left");
		rightPageLabel.setBorderStyle(NONE, 0x00000000, 0);
		rightPageLabel.fieldWidth = labelFieldW;
		rightPageLabel.setPosition(
			x + (halfW + halfW * RIGHT_LABEL_NX0) * sx,
			pageLabelY()
		);
		syncBookOverlayClip(rightPageLabel);
	}

	function layoutPageLabels():Void
	{
		layoutLeftPageLabel();
		layoutRightPageLabel();
	}

	function layoutIntroPages():Void
	{
		layoutIntroSide(false, leftPageNumber(), leftIntroTitle, leftIntroBody, leftIntroCaption, leftIntroImage, leftBulletTexts);
		layoutIntroSide(true, rightPageNumber(), rightIntroTitle, rightIntroBody, rightIntroCaption, rightIntroImage, rightBulletTexts);
	}

	function layoutIntroSide(
		rightPage:Bool,
		pageNum:Int,
		title:FlxText,
		body:FlxText,
		caption:FlxText,
		image:FlxSprite,
		bulletTexts:Array<FlxText>
	):Void
	{
		var content = BookIntroPages.getSide(pageNum);
		if (content == null)
		{
			title.visible = false;
			body.visible = false;
			caption.visible = false;
			image.visible = false;
			title.clipRect = null;
			body.clipRect = null;
			caption.clipRect = null;
			image.clipRect = null;
			hideBulletTexts(bulletTexts);
			return;
		}

		if (BookIntroPages.hasBulletList(pageNum))
		{
			var bulletTags = rightPage ? rightBulletTags : leftBulletTags;
			layoutBulletListSide(rightPage, pageNum, title, body, caption, image, bulletTexts, bulletTags, content.title);
			return;
		}

		clearBulletTags(rightPage ? rightBulletTags : leftBulletTags);
		hideBulletTexts(bulletTexts);

		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var pageX0 = rightPage ? halfW : 0.0;
		var padLeft = rightPage ? INTRO_PAD_NX : INTRO_LEFT_PAD_NX;
		var padRight = rightPage ? INTRO_RIGHT_PAD_NX : INTRO_PAD_NX;
		var contentX = x + (pageX0 + halfW * padLeft) * sx;
		var contentW = halfW * (1.0 - padLeft - padRight) * sx;
		var pageLeft = x + pageX0 * sx;
		var pageRight = x + (pageX0 + halfW) * sx;
		var cursorY = y + frameHeight * INTRO_CONTENT_TOP_NY * sy;
		var contentBottom = y + frameHeight * (NAV_ROW_NY0 - INTRO_CONTENT_NAV_GAP_NY) * sy;
		var bodySize = Std.int(Math.max(INTRO_MIN_BODY_SIZE, frameHeight * sy * INTRO_BODY_SIZE_RATIO));

		var titleSize = Std.int(Math.max(INTRO_MIN_TITLE_SIZE, frameHeight * sy * INTRO_TITLE_SIZE_RATIO));
		title.text = content.title;
		title.setFormat(null, titleSize, INTRO_TITLE_COLOR, "left");
		title.setBorderStyle(NONE, 0x00000000, 0);
		title.bold = true;
		title.italic = false;
		title.fieldWidth = contentW;
		title.autoSize = false;
		title.height = titleSize + 6;
		title.updateHitbox();
		title.setPosition(contentX, cursorY);
		title.visible = true;
		syncIntroOverlayClip(title, pageLeft, pageRight, contentBottom);
		cursorY += title.height + titleSize * 0.4;

		if (content.imagePath != null && content.imagePath.length > 0)
		{
			image.loadGraphic(content.imagePath);
			var hasBody = content.body.length > 0;
			var imageMaxRatio = hasBody ? INTRO_IMAGE_MAX_H_RATIO_WITH_BODY : INTRO_IMAGE_MAX_H_RATIO;
			var maxImageH = frameHeight * imageMaxRatio * sy;
			if (hasBody)
			{
				var bodyNeed = measureIntroBodyHeight(body, content.body, contentW, bodySize);
				var remaining = contentBottom - cursorY - bodyNeed - bodySize * 0.5;
				if (remaining > bodySize * 2)
					maxImageH = Math.min(maxImageH, remaining);
				else
					maxImageH = Math.min(maxImageH, Math.max(bodySize * 4, remaining));
			}
			maxImageH = Math.max(bodySize * 3, maxImageH);
			var maxImageW = contentW;
			var aspect = image.frameHeight > 0 ? image.frameWidth / image.frameHeight : 1.0;
			var imageW = maxImageW;
			var imageH = imageW / aspect;
			if (imageH > maxImageH)
			{
				imageH = maxImageH;
				imageW = imageH * aspect;
			}
			image.setGraphicSize(Std.int(Math.max(1, imageW)), Std.int(Math.max(1, imageH)));
			image.updateHitbox();
			image.setPosition(contentX + (contentW - imageW) * 0.5, cursorY);
			image.angle = angle;
			image.visible = true;
			syncIntroOverlayClip(image, pageLeft, pageRight, contentBottom);
			cursorY += imageH + titleSize * 0.3;

			var captionSize = Std.int(Math.max(INTRO_MIN_CAPTION_SIZE, titleSize - 1));
			caption.text = content.imageCaption != null ? content.imageCaption : "";
			caption.setFormat(null, captionSize, INTRO_CAPTION_COLOR, "center");
			caption.setBorderStyle(NONE, 0x00000000, 0);
			caption.bold = false;
			caption.italic = true;
			caption.fieldWidth = contentW;
			caption.autoSize = false;
			caption.height = captionSize + 4;
			caption.updateHitbox();
			caption.setPosition(contentX, cursorY);
			caption.visible = content.imageCaption != null && content.imageCaption.length > 0;
			syncIntroOverlayClip(caption, pageLeft, pageRight, contentBottom);
			cursorY += caption.visible ? caption.height + captionSize * 0.4 : 0;
		}
		else
		{
			image.visible = false;
			image.clipRect = null;
			caption.visible = false;
			caption.clipRect = null;
		}

		var availableH = Math.max(bodySize + 4, contentBottom - cursorY);
		body.text = content.body;
		body.setFormat(null, bodySize, INTRO_BODY_COLOR, "left");
		body.setBorderStyle(NONE, 0x00000000, 0);
		body.bold = false;
		body.italic = false;
		body.fieldWidth = contentW;
		body.autoSize = false;
		var textH = measureIntroBodyHeight(body, content.body, contentW, bodySize);
		body.height = Math.min(textH + bodySize * 0.25, availableH);
		body.updateHitbox();
		body.setPosition(contentX, cursorY);
		body.visible = content.body.length > 0;
		syncIntroOverlayClip(body, pageLeft, pageRight, contentBottom);
	}

	function layoutBulletListSide(
		rightPage:Bool,
		pageNum:Int,
		title:FlxText,
		body:FlxText,
		caption:FlxText,
		image:FlxSprite,
		bulletTexts:Array<FlxText>,
		bulletTags:Array<Null<String>>,
		pageTitle:String
	):Void
	{
		body.visible = false;
		body.clipRect = null;
		caption.visible = false;
		caption.clipRect = null;
		image.visible = false;
		image.clipRect = null;

		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var pageX0 = rightPage ? halfW : 0.0;
		var padLeft = rightPage ? INTRO_PAD_NX : INTRO_LEFT_PAD_NX;
		var padRight = rightPage ? INTRO_RIGHT_PAD_NX : INTRO_PAD_NX;
		var contentX = x + (pageX0 + halfW * padLeft) * sx;
		var contentW = halfW * (1.0 - padLeft - padRight) * sx;
		var pageLeft = x + pageX0 * sx;
		var pageRight = x + (pageX0 + halfW) * sx;
		var cursorY = y + frameHeight * INTRO_CONTENT_TOP_NY * sy;
		var contentBottom = y + frameHeight * (NAV_ROW_NY0 - INTRO_CONTENT_NAV_GAP_NY) * sy;
		var bodySize = Std.int(Math.max(INTRO_MIN_BODY_SIZE, frameHeight * sy * INTRO_BODY_SIZE_RATIO));
		var titleSize = Std.int(Math.max(INTRO_MIN_TITLE_SIZE, frameHeight * sy * INTRO_TITLE_SIZE_RATIO));
		var sectionSize = Std.int(Math.max(INTRO_MIN_SECTION_SIZE, frameHeight * sy * INTRO_SECTION_SIZE_RATIO));
		var bulletGap = bodySize * 0.45;
		var sectionGap = bodySize * 0.35;
		var sectionTopGap = bodySize * 0.65;

		title.text = pageTitle;
		title.setFormat(null, titleSize, INTRO_TITLE_COLOR, "left");
		title.setBorderStyle(NONE, 0x00000000, 0);
		title.bold = true;
		title.italic = false;
		title.fieldWidth = contentW;
		title.autoSize = false;
		title.height = titleSize + 6;
		title.updateHitbox();
		title.setPosition(contentX, cursorY);
		title.visible = true;
		syncIntroOverlayClip(title, pageLeft, pageRight, contentBottom);
		cursorY += title.height + titleSize * 0.5;

		var bullets = filterBullets(BookIntroPages.getBullets(pageNum));
		clearBulletTags(bulletTags);
		for (i in 0...bulletTexts.length)
		{
			var bullet = bulletTexts[i];
			if (i >= bullets.length)
			{
				bullet.visible = false;
				bullet.clipRect = null;
				if (i < bulletTags.length)
					bulletTags[i] = null;
				continue;
			}

			if (cursorY + bodySize > contentBottom)
			{
				bullet.visible = false;
				bullet.clipRect = null;
				if (i < bulletTags.length)
					bulletTags[i] = null;
				continue;
			}

			var entry = bullets[i];
			var isQuestion = BookIntroPages.isQuestionBullet(entry);
			if (i < bulletTags.length)
				bulletTags[i] = isQuestion ? BookScanActions.bookQuestionTag(entry.id) : null;

			if (!isQuestion && i > 0)
				cursorY += sectionTopGap;

			if (isQuestion)
			{
				bullet.text = '• ${entry.text}';
				bullet.setFormat(null, bodySize, INTRO_QUESTION_COLOR, "left");
				bullet.bold = false;
				bullet.italic = true;
			}
			else
			{
				bullet.text = entry.text;
				bullet.setFormat(null, sectionSize, INTRO_SECTION_COLOR, "left");
				bullet.bold = true;
				bullet.italic = false;
			}
			bullet.setBorderStyle(NONE, 0x00000000, 0);
			bullet.fieldWidth = contentW;
			bullet.autoSize = false;
			var lineSize = isQuestion ? bodySize : sectionSize;
			var textH = measureIntroBodyHeight(bullet, bullet.text, contentW, lineSize);
			bullet.height = textH + lineSize * 0.15;
			bullet.updateHitbox();
			bullet.setPosition(contentX, cursorY);
			bullet.visible = true;
			syncIntroOverlayClip(bullet, pageLeft, pageRight, contentBottom);
			cursorY += bullet.height + (isQuestion ? bulletGap : sectionGap);
		}
	}

	function syncIntroOverlayClip(overlay:FlxSprite, pageLeft:Float, pageRight:Float, contentBottom:Float):Void
	{
		if (!visible)
		{
			overlay.clipRect = null;
			return;
		}

		applyWorldClipRect(overlay, pageLeft, y, pageRight, Math.min(y + height, contentBottom));
	}

	function measureIntroBodyHeight(body:FlxText, text:String, fieldW:Float, fontSize:Int):Float
	{
		if (text.length == 0)
			return 0;

		body.text = text;
		body.setFormat(null, fontSize, INTRO_BODY_COLOR, "left");
		body.fieldWidth = fieldW;
		body.width = fieldW;
		if (body.textField != null)
		{
			body.textField.wordWrap = true;
			body.textField.width = fieldW;
			var measured = body.textField.textHeight + fontSize * 0.5;
			if (measured > fontSize)
				return measured;
		}

		var charsPerLine = Math.max(12, fieldW / (fontSize * 0.55));
		var lines = 0;
		for (paragraph in text.split("\n"))
		{
			if (paragraph.length == 0)
			{
				lines += 1;
				continue;
			}
			lines += Math.ceil(paragraph.length / charsPerLine);
		}
		return lines * (fontSize + 4);
	}

	function layoutBackArrow():Void
	{
		layoutPageArrow(backArrow, false, LEFT_ARROW_NX0, LEFT_ARROW_NX1, canGoBack());
	}

	function applyContentsNavVisual(hovered:Bool):Void
	{
		if (contentsNavButton == null || contentsNavLabel == null)
			return;

		drawRoundedTocLinkButton(
			contentsNavButton,
			contentsNavLayout.w,
			contentsNavLayout.h,
			contentsNavLayout.radius,
			contentsNavLayout.border,
			hovered
		);
		contentsNavLabel.color = hovered ? TOC_LINK_TEXT_HOVER : TOC_LINK_TEXT_COLOR;
	}

	function updateContentsNavHover(mouse:FlxPoint):Void
	{
		var hovered = shouldShowContentsNav()
			&& contentsNavButton.visible
			&& contentsNavButton.overlapsPoint(mouse);
		if (hovered == contentsNavHovered)
			return;

		if (contentsNavHovered)
			applyContentsNavVisual(false);

		contentsNavHovered = hovered;

		if (contentsNavHovered)
			applyContentsNavVisual(true);
	}

	function layoutContentsNavButton():Void
	{
		if (!shouldShowContentsNav())
		{
			contentsNavHovered = false;
			contentsNavButton.visible = false;
			contentsNavLabel.visible = false;
			contentsNavButton.clipRect = null;
			contentsNavLabel.clipRect = null;
			return;
		}

		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var linkFontSize = Std.int(Math.max(7, frameHeight * sy * CONTENTS_BUTTON_FONT_RATIO));
		var borderSize = Std.int(Math.max(1, sx));
		var buttonW = Std.int(Math.max(1, halfW * (CONTENTS_BUTTON_NX1 - CONTENTS_BUTTON_NX0) * sx));
		var rowH = frameHeight * (NAV_ROW_NY1 - NAV_ROW_NY0) * sy;
		var textButtonH = linkFontSize + linkFontSize * (CONTENTS_BUTTON_PAD_TOP_RATIO + CONTENTS_BUTTON_PAD_BOTTOM_RATIO);
		var buttonH = Std.int(Math.max(1, Math.max(textButtonH, rowH * CONTENTS_BUTTON_MIN_ROW_RATIO)));
		buttonH = Std.int(Math.min(rowH, buttonH));
		var cornerRadius = Std.int(Math.min(buttonH * 0.42, Math.max(3, linkFontSize * 0.45)));
		contentsNavLayout = {w: buttonW, h: buttonH, radius: cornerRadius, border: borderSize};

		var boxX = x + halfW * CONTENTS_BUTTON_NX0 * sx;
		var rowY = y + frameHeight * NAV_ROW_NY0 * sy;
		var boxY = rowY + (rowH - buttonH) * 0.5;

		applyContentsNavVisual(contentsNavHovered);
		contentsNavButton.visible = overlaysShown;
		contentsNavButton.setPosition(boxX, boxY);
		contentsNavButton.angle = angle;
		syncBookOverlayClip(contentsNavButton);

		contentsNavLabel.text = CONTENTS_BUTTON_LABEL;
		contentsNavLabel.setFormat(null, linkFontSize, contentsNavHovered ? TOC_LINK_TEXT_HOVER : TOC_LINK_TEXT_COLOR, "center");
		contentsNavLabel.setBorderStyle(NONE, 0x00000000, 0);
		contentsNavLabel.bold = false;
		contentsNavLabel.wordWrap = false;
		contentsNavLabel.autoSize = false;
		contentsNavLabel.fieldWidth = buttonW;
		contentsNavLabel.width = buttonW;
		contentsNavLabel.height = buttonH;
		contentsNavLabel.updateHitbox();
		contentsNavLabel.visible = overlaysShown;
		contentsNavLabel.setPosition(boxX, boxY + (buttonH - linkFontSize) * 0.5);
		syncBookOverlayClip(contentsNavLabel);
	}

	function layoutForwardArrow():Void
	{
		layoutPageArrow(forwardArrow, true, RIGHT_ARROW_NX0, RIGHT_ARROW_NX1, canGoForward());
	}

	function layoutPageArrow(arrow:FlxSprite, rightPage:Bool, nx0:Float, nx1:Float, visible:Bool):Void
	{
		if (!visible)
		{
			arrow.visible = false;
			arrow.clipRect = null;
			return;
		}

		arrow.visible = overlaysShown;
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		var halfW = frameWidth * 0.5;
		var pageX0 = rightPage ? halfW : 0.0;
		var maxW = halfW * (nx1 - nx0) * sx;
		var maxH = frameHeight * (NAV_ROW_NY1 - NAV_ROW_NY0) * sy;
		var aspect = arrow.frameHeight > 0 ? arrow.frameWidth / arrow.frameHeight : 1.0;
		var targetW = maxW;
		var targetH = targetW / aspect;
		if (targetH > maxH)
		{
			targetH = maxH;
			targetW = targetH * aspect;
		}
		arrow.setGraphicSize(Std.int(Math.max(1, targetW)), Std.int(Math.max(1, targetH)));
		arrow.updateHitbox();
		var boxX = x + (pageX0 + halfW * nx0) * sx;
		var boxY = y + frameHeight * NAV_ROW_NY0 * sy;
		arrow.setPosition(
			boxX + (rightPage ? maxW - targetW : 0.0),
			boxY + (maxH - targetH) * 0.5
		);
		arrow.angle = angle;
		syncBookOverlayClip(arrow);
	}

	function ensureOverlaysOnTop():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		var overlays:Array<FlxSprite> = [
			cast leftPageLabel,
			cast rightPageLabel,
			coverEmblem,
			cast coverTitlePrimary,
			cast coverTitleSecondary,
			cast coverSubtitle,
			cast coverSponsor,
			cast tocHeading
		];
		for (subtitle in tocSubtitleLabels)
			overlays.push(cast subtitle);
		for (button in tocLinkButtons)
			overlays.push(button);
		for (link in tocLinks)
			overlays.push(cast link);
		for (pageLabel in tocLinkPageLabels)
			overlays.push(cast pageLabel);
		overlays.push(cast leftIntroTitle);
		overlays.push(cast leftIntroBody);
		overlays.push(cast leftIntroCaption);
		overlays.push(leftIntroImage);
		overlays.push(cast rightIntroTitle);
		overlays.push(cast rightIntroBody);
		overlays.push(cast rightIntroCaption);
		overlays.push(rightIntroImage);
		for (bullet in leftBulletTexts)
			overlays.push(cast bullet);
		for (bullet in rightBulletTexts)
			overlays.push(cast bullet);
		overlays.push(backArrow);
		overlays.push(forwardArrow);
		overlays.push(contentsNavButton);
		overlays.push(cast contentsNavLabel);
		for (overlay in overlays)
		{
			var overlayIndex = textLayer.members.indexOf(overlay);
			if (overlayIndex < 0)
				continue;
			if (overlayIndex <= spriteIndex)
			{
				textLayer.remove(overlay, true);
				textLayer.add(overlay);
			}
		}
	}

	function syncOverlayCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [FlxG.camera];
		leftPageLabel.cameras = cams.copy();
		rightPageLabel.cameras = cams.copy();
		coverEmblem.cameras = cams.copy();
		coverTitlePrimary.cameras = cams.copy();
		coverTitleSecondary.cameras = cams.copy();
		coverSubtitle.cameras = cams.copy();
		coverSponsor.cameras = cams.copy();
		tocHeading.cameras = cams.copy();
		for (subtitle in tocSubtitleLabels)
			subtitle.cameras = cams.copy();
		for (button in tocLinkButtons)
			button.cameras = cams.copy();
		for (link in tocLinks)
			link.cameras = cams.copy();
		for (pageLabel in tocLinkPageLabels)
			pageLabel.cameras = cams.copy();
		leftIntroTitle.cameras = cams.copy();
		leftIntroBody.cameras = cams.copy();
		leftIntroCaption.cameras = cams.copy();
		leftIntroImage.cameras = cams.copy();
		rightIntroTitle.cameras = cams.copy();
		rightIntroBody.cameras = cams.copy();
		rightIntroCaption.cameras = cams.copy();
		rightIntroImage.cameras = cams.copy();
		for (bullet in leftBulletTexts)
			bullet.cameras = cams.copy();
		for (bullet in rightBulletTexts)
			bullet.cameras = cams.copy();
		backArrow.cameras = cams.copy();
		forwardArrow.cameras = cams.copy();
		contentsNavButton.cameras = cams.copy();
		contentsNavLabel.cameras = cams.copy();
	}
}
