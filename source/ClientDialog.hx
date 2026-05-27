package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class ClientDialog extends FlxGroup
{
	static inline var MAX_BUBBLES:Int = 6;
	static inline var NUM_CHOICES:Int = 3;
	static inline var CHAR_DELAY:Float = 0.045;
	static inline var MSG_PAUSE:Float = 1.0;
	static inline var DISMISS_TIME:Float = 3.0;
	static inline var FADE_DURATION:Float = 0.3;
	static inline var SLIDE_SPEED:Float = 8.0;
	static inline var PING_HEIGHT:Float = 5.0;
	static inline var PING_DURATION:Float = 0.25;
	static inline var BUBBLE_PAD:Int = 8;
	static inline var BUBBLE_MARGIN:Int = 4;
	static inline var SLOT_GAP:Int = 3;
	static inline var BORDER_W:Int = 2;
	static inline var CONV_PAUSE_TIME:Float = 1.5;
	static inline var CHOICE_PAD:Int = 3;
	static inline var CHOICE_GAP:Int = 2;
	static inline var DONE_LINGER:Float = 5.0;

	static inline var ST_UNUSED:Int = 0;
	static inline var ST_TYPING:Int = 1;
	static inline var ST_LAST:Int = 2;
	static inline var ST_DISMISS:Int = 3;
	static inline var ST_FADE:Int = 4;

	static inline var CONV_NONE:Int = 0;
	static inline var CONV_CLIENT_TALK:Int = 1;
	static inline var CONV_CHOICES:Int = 2;
	static inline var CONV_STEP_TYPE:Int = 3;
	static inline var CONV_STEP_PAUSE:Int = 4;
	static inline var CONV_DONE:Int = 5;

	static inline var STEP_PLAYER:Int = 0;
	static inline var STEP_CLIENT:Int = 1;
	static inline var STEP_CHOICES:Int = 2;
	static inline var STEP_PASSPORT:Int = 3;

	var areaRight:Float;
	var areaTop:Float;
	var areaBottom:Float;
	var maxW:Int;
	var maxTextW:Int;
	var fontSize:Int;
	var avgCharW:Float;
	var lineH:Int;
	var minBubbleW:Int;
	var topY:Float;
	var choiceFontSize:Int;

	var clientRef:FlxSprite;
	var clientBaseY:Float;
	var pinging:Bool = false;
	var pingTimer:Float = 0;

	var messages:Array<String>;
	var nextMsgIdx:Int = 0;
	var msgsDone:Bool = false;
	var pauseActive:Bool = false;
	var pauseTimer:Float = 0;

	var typingSlot:Int = -1;
	var typeTimer:Float = 0;

	var bgArr:Array<FlxSprite>;
	var txtArr:Array<FlxText>;
	var stArr:Array<Int>;
	var tmArr:Array<Float>;
	var msgArr:Array<String>;
	var chArr:Array<Int>;
	var yArr:Array<Float>;
	var bwArr:Array<Int>;
	var bhArr:Array<Int>;
	var order:Array<Int>;

	var choiceBg:Array<FlxSprite>;
	var choiceTxt:Array<FlxText>;
	var choiceAvail:Array<Bool>;
	var choicesVisible:Bool = false;
	var choiceRowH:Int = 0;

	var playerBg:FlxSprite;
	var playerTxt:FlxText;
	var playerActive:Bool = false;
	var playerVisible:Bool = false;
	var playerMsg:String = "";
	var playerChars:Int = 0;
	var playerTimer:Float = 0;
	var playerFadeTimer:Float = -1;

	var convPhase:Int = CONV_NONE;
	var convTimer:Float = 0;
	var convSteps:Array<{type:Int, text:String}>;
	var convStepIdx:Int = 0;
	var citizenName:String = "";
	var doneTimer:Float = 0;
	var passportPending = false;
	var passportDelivered = false;

	public var consumedClick(default, null):Bool = false;
	public var onPassportRequest:Void->Void;

	public function new(areaRight:Float, areaTop:Float, areaBottom:Float, maxW:Int, clientSprite:FlxSprite, clientBaseY:Float)
	{
		super();
		this.areaRight = areaRight;
		this.areaTop = areaTop;
		this.areaBottom = areaBottom;
		this.maxW = maxW;
		this.clientRef = clientSprite;
		this.clientBaseY = clientBaseY;

		fontSize = Std.int(Math.max(7, FlxG.height / 65));
		maxTextW = maxW - BUBBLE_PAD * 2;
		avgCharW = fontSize * 0.6;
		lineH = fontSize + 4;
		minBubbleW = BUBBLE_PAD * 2 + Std.int(avgCharW * 2);
		topY = areaTop + BUBBLE_MARGIN;
		choiceFontSize = Std.int(Math.max(6, fontSize - 1));

		bgArr = [];
		txtArr = [];
		stArr = [];
		tmArr = [];
		msgArr = [];
		chArr = [];
		yArr = [];
		bwArr = [];
		bhArr = [];
		order = [];
		messages = [];
		convSteps = [];

		for (i in 0...MAX_BUBBLES)
		{
			var bg = new FlxSprite();
			bg.visible = false;
			var txt = new FlxText(0, 0, maxTextW, "");
			txt.setFormat(null, fontSize, FlxColor.fromRGB(220, 230, 245), "left");
			txt.wordWrap = true;
			txt.visible = false;
			add(bg);
			add(txt);
			bgArr.push(bg);
			txtArr.push(txt);
			stArr.push(ST_UNUSED);
			tmArr.push(0);
			msgArr.push("");
			chArr.push(0);
			yArr.push(0);
			bwArr.push(0);
			bhArr.push(0);
		}

		choiceBg = [];
		choiceTxt = [];
		choiceAvail = [true, true, true];

		for (i in 0...NUM_CHOICES)
		{
			var cbg = new FlxSprite();
			cbg.visible = false;
			var ctxt = new FlxText(0, 0, 0, "");
			ctxt.setFormat(null, choiceFontSize, FlxColor.fromRGB(180, 195, 140), "center");
			ctxt.wordWrap = true;
			ctxt.visible = false;
			add(cbg);
			add(ctxt);
			choiceBg.push(cbg);
			choiceTxt.push(ctxt);
		}

		playerBg = new FlxSprite();
		playerBg.visible = false;
		playerTxt = new FlxText(0, 0, maxTextW, "");
		playerTxt.setFormat(null, fontSize, FlxColor.fromRGB(210, 235, 210), "left");
		playerTxt.wordWrap = true;
		playerTxt.visible = false;
		add(playerBg);
		add(playerTxt);
	}

	public function setCitizenName(name:String):Void
	{
		citizenName = name;
	}

	public function startDialog(msgs:Array<String>):Void
	{
		for (i in 0...MAX_BUBBLES)
		{
			bgArr[i].visible = false;
			txtArr[i].visible = false;
			stArr[i] = ST_UNUSED;
		}
		order = [];
		hideChoices();
		playerBg.visible = false;
		playerTxt.visible = false;
		playerVisible = false;
		playerActive = false;
		playerFadeTimer = -1;

		messages = msgs;
		nextMsgIdx = 0;
		msgsDone = false;
		pauseActive = false;
		typingSlot = -1;
		convPhase = CONV_CLIENT_TALK;
		convSteps = [];
		convStepIdx = 0;
		choiceAvail = [true, true, true];
		passportPending = false;
		passportDelivered = false;

		beginNextMessage();
	}

	function findOpenBubbleSlot():Int
	{
		for (i in 0...MAX_BUBBLES)
		{
			if (stArr[i] == ST_UNUSED)
				return i;
		}

		// Reuse the oldest bubble so required client replies are never dropped.
		if (order.length > 0)
		{
			var idx = order[0];
			stArr[idx] = ST_UNUSED;
			bgArr[idx].visible = false;
			txtArr[idx].visible = false;
			order.splice(0, 1);
			return idx;
		}

		return -1;
	}

	function typeMessage(text:String, withPing:Bool):Void
	{
		hidePlayerBubble();

		for (idx in order)
		{
			if (stArr[idx] == ST_LAST)
			{
				stArr[idx] = ST_DISMISS;
				tmArr[idx] = 0;
			}
		}

		var slot = findOpenBubbleSlot();
		if (slot == -1)
			return;

		stArr[slot] = ST_TYPING;
		tmArr[slot] = 0;
		msgArr[slot] = text;
		chArr[slot] = 0;
		txtArr[slot].text = "";

		sizeBubble(slot, 0);
		yArr[slot] = stackTargetY(order.length);
		placeBubble(slot);
		bgArr[slot].visible = true;
		txtArr[slot].visible = true;
		bgArr[slot].alpha = 1.0;
		txtArr[slot].alpha = 1.0;

		order.push(slot);
		typingSlot = slot;
		typeTimer = 0;

		if (withPing)
		{
			pinging = true;
			pingTimer = 0;
		}
	}

	function typePlayerMessage(text:String):Void
	{
		for (idx in order)
		{
			if (stArr[idx] == ST_LAST)
			{
				stArr[idx] = ST_DISMISS;
				tmArr[idx] = 0;
			}
		}

		playerMsg = text;
		playerChars = 0;
		playerTimer = 0;
		playerActive = true;
		playerVisible = true;
		playerFadeTimer = -1;

		playerTxt.text = "";
		sizePlayerBubble(0);
		placePlayerBubble();
		playerBg.visible = true;
		playerTxt.visible = true;
		playerBg.alpha = 1.0;
		playerTxt.alpha = 1.0;
	}

	function beginNextMessage():Void
	{
		if (nextMsgIdx >= messages.length)
		{
			msgsDone = true;
			return;
		}
		var msg = messages[nextMsgIdx];
		nextMsgIdx++;
		typeMessage(msg, true);
	}

	function stackTargetY(activeIdx:Int):Float
	{
		var y = topY;
		for (i in 0...activeIdx)
			y += bhArr[order[i]] + SLOT_GAP;
		return y;
	}

	function sizeBubble(slot:Int, chars:Int):Void
	{
		var estW = chars * avgCharW;
		var bw = Std.int(Math.min(estW + BUBBLE_PAD * 3, maxW));
		if (bw < minBubbleW)
			bw = minBubbleW;

		var wrapW = maxTextW * 0.78;
		var numLines = Std.int(Math.max(1, Math.ceil(estW / wrapW)));
		var bh = numLines * lineH + BUBBLE_PAD * 2;

		bwArr[slot] = bw;
		bhArr[slot] = bh;

		bgArr[slot].makeGraphic(bw, bh, FlxColor.fromRGB(12, 18, 28), true);
		drawBorder(bgArr[slot], bw, bh, FlxColor.BLACK);
	}

	function sizePlayerBubble(chars:Int):Void
	{
		var estW = chars * avgCharW;
		var bw = Std.int(Math.min(estW + BUBBLE_PAD * 3, maxW));
		if (bw < minBubbleW)
			bw = minBubbleW;

		var wrapW = maxTextW * 0.78;
		var numLines = Std.int(Math.max(2, Math.ceil(estW / wrapW)));
		var bh = numLines * lineH + BUBBLE_PAD * 2;

		playerBg.makeGraphic(bw, bh, FlxColor.fromRGB(14, 28, 18), true);
		drawBorder(playerBg, bw, bh, FlxColor.BLACK);
	}

	function placeBubble(slot:Int):Void
	{
		var bx = Std.int(areaRight - bwArr[slot] - BUBBLE_MARGIN);
		bgArr[slot].x = bx;
		bgArr[slot].y = yArr[slot];
		txtArr[slot].x = bx + BUBBLE_PAD;
		txtArr[slot].y = yArr[slot] + BUBBLE_PAD;
	}

	function placePlayerBubble():Void
	{
		var bw = Std.int(playerBg.width);
		var bh = Std.int(playerBg.height);
		var bx = Std.int(areaRight - bw - BUBBLE_MARGIN);
		var by = Std.int(areaBottom - bh - BUBBLE_MARGIN);
		playerBg.x = bx;
		playerBg.y = by;
		playerTxt.x = bx + BUBBLE_PAD;
		playerTxt.y = by + BUBBLE_PAD;
	}

	function drawBorder(spr:FlxSprite, w:Int, h:Int, c:FlxColor):Void
	{
		var s = BORDER_W;
		var bmd = spr.pixels;
		bmd.fillRect(new Rectangle(0, 0, w, s), c);
		bmd.fillRect(new Rectangle(0, h - s, w, s), c);
		bmd.fillRect(new Rectangle(0, 0, s, h), c);
		bmd.fillRect(new Rectangle(w - s, 0, s, h), c);
		spr.dirty = true;
	}

	override public function update(elapsed:Float):Void
	{
		consumedClick = false;
		super.update(elapsed);
		if (MonitorOverlay.pausesDialogue())
			return;

		updatePing(elapsed);
		updateTyping(elapsed);
		updatePlayerTyping(elapsed);
		updatePause(elapsed);
		updateLifecycles(elapsed);
		updatePlayerLifecycle(elapsed);
		slideBubbles(elapsed);
		updateConversation(elapsed);
		updateChoiceHover();
	}

	function updatePing(elapsed:Float):Void
	{
		if (!pinging)
			return;
		pingTimer += elapsed;
		var t = pingTimer / PING_DURATION;
		if (t >= 1.0)
		{
			pinging = false;
			clientRef.y = clientBaseY;
		}
		else
		{
			clientRef.y = clientBaseY - Math.sin(t * Math.PI) * PING_HEIGHT;
		}
	}

	function updateTyping(elapsed:Float):Void
	{
		if (typingSlot == -1)
			return;

		typeTimer += elapsed;
		var msg = msgArr[typingSlot];
		var target = Std.int(typeTimer / CHAR_DELAY);
		if (target > msg.length)
			target = msg.length;

		if (target > chArr[typingSlot])
		{
			chArr[typingSlot] = target;
			txtArr[typingSlot].text = msg.substr(0, target);
			sizeBubble(typingSlot, target);
			placeBubble(typingSlot);
		}

		if (chArr[typingSlot] >= msg.length)
		{
			if (convPhase == CONV_CLIENT_TALK)
			{
				if (nextMsgIdx >= messages.length)
					stArr[typingSlot] = ST_LAST;
				else
				{
					stArr[typingSlot] = ST_DISMISS;
					tmArr[typingSlot] = 0;
				}
				typingSlot = -1;
				pauseActive = true;
				pauseTimer = 0;
			}
			else
			{
				stArr[typingSlot] = ST_LAST;
				typingSlot = -1;
			}
		}
	}

	function updatePlayerTyping(elapsed:Float):Void
	{
		if (!playerActive)
			return;

		playerTimer += elapsed;
		var target = Std.int(playerTimer / CHAR_DELAY);
		if (target > playerMsg.length)
			target = playerMsg.length;

		if (target > playerChars)
		{
			playerChars = target;
			playerTxt.text = playerMsg.substr(0, target);
			sizePlayerBubble(target);
			placePlayerBubble();
		}

		if (playerChars >= playerMsg.length)
			playerActive = false;
	}

	function updatePause(elapsed:Float):Void
	{
		if (!pauseActive)
			return;
		pauseTimer += elapsed;
		if (pauseTimer >= MSG_PAUSE)
		{
			pauseActive = false;
			if (convPhase == CONV_CLIENT_TALK)
				beginNextMessage();
		}
	}

	function updateLifecycles(elapsed:Float):Void
	{
		var i = order.length - 1;
		while (i >= 0)
		{
			var idx = order[i];
			if (stArr[idx] == ST_DISMISS)
			{
				tmArr[idx] += elapsed;
				if (tmArr[idx] >= DISMISS_TIME)
				{
					stArr[idx] = ST_FADE;
					tmArr[idx] = 0;
				}
			}
			else if (stArr[idx] == ST_FADE)
			{
				tmArr[idx] += elapsed;
				var t = Math.min(tmArr[idx] / FADE_DURATION, 1.0);
				bgArr[idx].alpha = 1.0 - t;
				txtArr[idx].alpha = 1.0 - t;

				if (t >= 1.0)
				{
					bgArr[idx].visible = false;
					txtArr[idx].visible = false;
					stArr[idx] = ST_UNUSED;
					order.splice(i, 1);
				}
			}
			i--;
		}
	}

	function updatePlayerLifecycle(elapsed:Float):Void
	{
		if (!playerVisible)
			return;
		if (playerFadeTimer < 0)
			return;

		playerFadeTimer += elapsed;
		var t = Math.min(playerFadeTimer / FADE_DURATION, 1.0);
		playerBg.alpha = 1.0 - t;
		playerTxt.alpha = 1.0 - t;

		if (t >= 1.0)
		{
			playerBg.visible = false;
			playerTxt.visible = false;
			playerVisible = false;
			playerFadeTimer = -1;
		}
	}

	function hidePlayerBubble():Void
	{
		if (!playerVisible)
			return;
		playerActive = false;
		if (playerFadeTimer < 0)
			playerFadeTimer = 0;
	}

	function slideBubbles(elapsed:Float):Void
	{
		var targetY = topY;
		for (i in 0...order.length)
		{
			var idx = order[i];
			var diff = targetY - yArr[idx];
			if (Math.abs(diff) < 0.5)
				yArr[idx] = targetY;
			else
				yArr[idx] += diff * Math.min(1.0, elapsed * SLIDE_SPEED);

			placeBubble(idx);
			targetY += bhArr[idx] + SLOT_GAP;
		}
	}

	function updateConversation(elapsed:Float):Void
	{
		switch (convPhase)
		{
			case CONV_CLIENT_TALK:
				if (msgsDone && typingSlot == -1 && !pauseActive)
				{
					convPhase = CONV_CHOICES;
					showChoices();
				}
			case CONV_CHOICES:
				checkChoiceClicks();
			case CONV_STEP_TYPE:
				if (typingSlot == -1 && !playerActive)
				{
					convPhase = CONV_STEP_PAUSE;
					convTimer = 0;
				}
			case CONV_STEP_PAUSE:
				convTimer += elapsed;
				if (convTimer >= CONV_PAUSE_TIME)
					executeNextStep();
			case CONV_DONE:
				tryDeliverPassport();
				doneTimer += elapsed;
				if (doneTimer >= DONE_LINGER)
				{
					for (idx in order)
					{
						if (stArr[idx] == ST_LAST)
						{
							stArr[idx] = ST_DISMISS;
							tmArr[idx] = 0;
						}
					}
					hidePlayerBubble();
					convPhase = CONV_NONE;
				}
			default:
		}
	}

	function enterDone():Void
	{
		convPhase = CONV_DONE;
		doneTimer = 0;
	}

	function onChoiceSelected(idx:Int):Void
	{
		choiceAvail[idx] = false;
		hideChoices();

		switch (idx)
		{
			case 0:
				convSteps = [
					{type: STEP_PLAYER, text: "Yeah, the weather is lovely today!"},
					{type: STEP_CHOICES, text: ""}
				];
			case 1:
				choiceAvail[0] = false;
				convSteps = [
					{type: STEP_PLAYER, text: "Excuse me, what is your name?"},
					{type: STEP_CLIENT, text: "It's " + citizenName + "."},
					{type: STEP_CHOICES, text: ""}
				];
			case 2:
				passportPending = true;
				passportDelivered = false;
				convSteps = [
					{type: STEP_PLAYER, text: "Could I see your passport, please?"},
					{type: STEP_CLIENT, text: "Oh, sorry."},
					{type: STEP_PASSPORT, text: ""}
				];
			default:
		}

		convStepIdx = 0;
		executeNextStep();
	}

	function executeNextStep():Void
	{
		if (convStepIdx >= convSteps.length)
		{
			enterDone();
			return;
		}

		var step = convSteps[convStepIdx];
		convStepIdx++;

		switch (step.type)
		{
			case STEP_PLAYER:
				typePlayerMessage(step.text);
				convPhase = CONV_STEP_TYPE;
			case STEP_CLIENT:
				typeMessage(step.text, true);
				convPhase = CONV_STEP_TYPE;
			case STEP_CHOICES:
				if (hasAvailableChoices())
				{
					showChoices();
					convPhase = CONV_CHOICES;
				}
				else
					enterDone();
			case STEP_PASSPORT:
				tryDeliverPassport();
				enterDone();
			default:
				enterDone();
		}
	}

	function tryDeliverPassport():Void
	{
		if (!passportPending || passportDelivered || onPassportRequest == null)
			return;
		passportDelivered = true;
		onPassportRequest();
	}

	function hasAvailableChoices():Bool
	{
		for (a in choiceAvail)
			if (a)
				return true;
		return false;
	}

	function showChoices():Void
	{
		hidePlayerBubble();
		choicesVisible = true;
		layoutChoices();
	}

	function hideChoices():Void
	{
		choicesVisible = false;
		for (i in 0...NUM_CHOICES)
		{
			choiceBg[i].visible = false;
			choiceTxt[i].visible = false;
		}
	}

	function layoutChoices():Void
	{
		var labels = ["Yeah, that's right", "What is your name?", "Passport, please."];
		var numVisible = 0;
		for (i in 0...NUM_CHOICES)
			if (choiceAvail[i])
				numVisible++;

		if (numVisible == 0)
		{
			hideChoices();
			return;
		}

		var totalW = Std.int(areaRight) - BUBBLE_MARGIN * 2;
		var choiceW = Std.int((totalW - CHOICE_GAP * (numVisible - 1)) / numVisible);
		var txtW = choiceW - CHOICE_PAD * 2;
		if (txtW < 10)
			txtW = 10;

		var cAvgW = choiceFontSize * 0.55;
		var cLineH = choiceFontSize + 2;
		var maxH = cLineH * 2 + CHOICE_PAD * 2;
		choiceRowH = maxH;

		var baseY = areaBottom - maxH - BUBBLE_MARGIN;
		var cx = BUBBLE_MARGIN;
		for (i in 0...NUM_CHOICES)
		{
			if (!choiceAvail[i])
			{
				choiceBg[i].visible = false;
				choiceTxt[i].visible = false;
				continue;
			}

			choiceBg[i].makeGraphic(choiceW, maxH, FlxColor.fromRGB(12, 18, 28), true);
			drawBorder(choiceBg[i], choiceW, maxH, FlxColor.BLACK);
			choiceBg[i].x = cx;
			choiceBg[i].y = baseY;
			choiceBg[i].visible = true;
			choiceBg[i].alpha = 1.0;

			choiceTxt[i].fieldWidth = txtW;
			choiceTxt[i].text = toTwoLineChoice(labels[i], txtW, cAvgW);
			choiceTxt[i].setFormat(null, choiceFontSize, FlxColor.fromRGB(180, 195, 140), "center");
			choiceTxt[i].x = cx + CHOICE_PAD;
			choiceTxt[i].y = baseY + CHOICE_PAD;
			choiceTxt[i].visible = true;
			choiceTxt[i].alpha = 1.0;

			cx += choiceW + CHOICE_GAP;
		}
	}

	function toTwoLineChoice(raw:String, maxWidth:Float, avgCharW:Float):String
	{
		var maxChars = Std.int(Math.max(3, Math.floor(maxWidth / avgCharW)));
		var words = raw.split(" ");

		if (words.length <= 1)
		{
			if (raw.length <= maxChars)
				return raw + "\n ";
			var first = raw.substr(0, maxChars);
			var second = raw.substr(maxChars);
			if (second.length > maxChars)
				second = second.substr(0, Std.int(Math.max(0, maxChars - 1))) + "…";
			return first + "\n" + second;
		}

		var bestIdx = 1;
		var bestDelta = 1e9;
		for (i in 1...words.length)
		{
			var left = words.slice(0, i).join(" ");
			var right = words.slice(i, words.length).join(" ");
			var delta = Math.abs(left.length - right.length);
			if (delta < bestDelta)
			{
				bestDelta = delta;
				bestIdx = i;
			}
		}

		var line1 = words.slice(0, bestIdx).join(" ");
		var line2 = words.slice(bestIdx, words.length).join(" ");

		if (line1.length > maxChars)
			line1 = line1.substr(0, Std.int(Math.max(0, maxChars - 1))) + "…";
		if (line2.length > maxChars)
			line2 = line2.substr(0, Std.int(Math.max(0, maxChars - 1))) + "…";

		if (line2.length == 0)
			line2 = " ";
		return line1 + "\n" + line2;
	}

	function checkChoiceClicks():Void
	{
		if (MonitorOverlay.blocksWorldInput())
			return;

		if (!choicesVisible || !FlxG.mouse.justPressed)
			return;

		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;

		for (i in 0...NUM_CHOICES)
		{
			if (!choiceAvail[i] || !choiceBg[i].visible)
				continue;

			var bg = choiceBg[i];
			if (mx >= bg.x && mx < bg.x + bg.width && my >= bg.y && my < bg.y + bg.height)
			{
				consumedClick = true;
				onChoiceSelected(i);
				return;
			}
		}
	}

	function updateChoiceHover():Void
	{
		if (!choicesVisible)
			return;

		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;

		for (i in 0...NUM_CHOICES)
		{
			if (!choiceAvail[i] || !choiceTxt[i].visible)
				continue;
			var bg = choiceBg[i];
			var hovered = mx >= bg.x && mx < bg.x + bg.width && my >= bg.y && my < bg.y + bg.height;
			choiceTxt[i].color = hovered ? FlxColor.fromRGB(255, 255, 180) : FlxColor.fromRGB(180, 195, 140);
		}
	}

	public function setCameras(cams:Array<FlxCamera>):Void
	{
		for (i in 0...MAX_BUBBLES)
		{
			bgArr[i].cameras = cams;
			txtArr[i].cameras = cams;
		}
		for (i in 0...NUM_CHOICES)
		{
			choiceBg[i].cameras = cams;
			choiceTxt[i].cameras = cams;
		}
		playerBg.cameras = cams;
		playerTxt.cameras = cams;
	}
}
