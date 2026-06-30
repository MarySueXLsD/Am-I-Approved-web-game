package;

import flixel.FlxG;
import flixel.group.FlxGroup;

class MainMenuTraffic extends FlxGroup
{
	static inline var TOP_LANE_Y_RATIO = 0.825;
	static inline var BOTTOM_LANE_Y_RATIO = 0.910;
	static inline var CAR_HEIGHT_RATIO = 0.142;
	static inline var BOTTOM_CAR_SCALE = 1.12;
	static inline var SPAWN_MARGIN = 28.0;
	static inline var MIN_SPEED = 800.0;
	static inline var MAX_SPEED = 1000.0;
	static inline var MIN_SPAWN_INTERVAL = 0.55;
	static inline var MAX_SPAWN_INTERVAL = 1.45;
	static inline var MIN_CAR_GAP = 1.65;
	static inline var TRAIL_GAP = 1.75;
	static inline var DOUBLE_SPAWN_CHANCE = 0.24;

	static var CAR_PATHS:Array<String> = [
		"static/Main_Menu/blue_car.png",
		"static/Main_Menu/red_car.png",
		"static/Main_Menu/green_car.png",
	];

	var cars:Array<MainMenuTrafficCar> = [];
	var topLaneLayer:FlxGroup;
	var bottomLaneLayer:FlxGroup;
	var sceneW = 800.0;
	var sceneH = 600.0;
	var running = false;
	var fading = false;
	var fadeElapsed = 0.0;
	var fadeDuration = 0.0;
	var fadeOnComplete:Void->Void;
	var spawnTimer = 0.0;
	var nextSpawnIn = 0.0;

	public function new()
	{
		super();

		topLaneLayer = new FlxGroup();
		bottomLaneLayer = new FlxGroup();
		add(topLaneLayer);
		add(bottomLaneLayer);
	}

	public function layout(w:Float, h:Float):Void
	{
		sceneW = w;
		sceneH = h;
		for (car in cars)
		{
			car.resize(carHeightFor(car.lane));
			placeCarOnLane(car, car.lane);
		}
	}

	public function startTraffic():Void
	{
		running = true;
		visible = true;
		spawnTimer = 0;
		scheduleNextSpawn(0.15, 0.55);
	}

	public function stopTraffic():Void
	{
		cancelFade();
		fading = false;
		running = false;
		visible = false;
		clearCars();
		spawnTimer = 0;
	}

	public function beginFadeOut(duration:Float, ?onComplete:Void->Void):Void
	{
		if (!running && !fading)
		{
			if (onComplete != null)
				onComplete();
			return;
		}

		running = false;
		fading = true;
		fadeElapsed = 0;
		fadeDuration = duration;
		fadeOnComplete = onComplete;
		visible = true;
		applyCarAlpha(1);
	}

	public function resetFadeState():Void
	{
		cancelFade();
		fading = false;
		applyCarAlpha(1);
	}

	function finishFadeOut():Void
	{
		fading = false;
		fadeOnComplete = null;
		clearCars();
		running = false;
		visible = false;
		spawnTimer = 0;
	}

	function cancelFade():Void
	{
		fadeOnComplete = null;
		fadeElapsed = 0;
		fadeDuration = 0;
		applyCarAlpha(1);
	}

	function applyCarAlpha(value:Float):Void
	{
		for (car in cars)
			car.alpha = value;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (fading)
		{
			fadeElapsed += elapsed;
			var t = fadeDuration > 0 ? fadeElapsed / fadeDuration : 1;
			applyCarAlpha(Math.max(0, 1 - t));

			if (fadeElapsed >= fadeDuration)
			{
				var cb = fadeOnComplete;
				finishFadeOut();
				if (cb != null)
					cb();
			}
		}

		if (!running)
			return;

		spawnTimer += elapsed;
		if (spawnTimer >= nextSpawnIn)
		{
			spawnTimer = 0;
			scheduleNextSpawn(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL);
			trySpawnRandom();
		}

		var i = cars.length - 1;
		while (i >= 0)
		{
			var car = cars[i];

			if (car.vx < 0 && car.x + car.getTravelWidth() < -SPAWN_MARGIN)
				removeCarAt(i);
			else if (car.vx > 0 && car.x > sceneW + SPAWN_MARGIN)
				removeCarAt(i);

			i--;
		}
	}

	function scheduleNextSpawn(min:Float, max:Float):Void
	{
		nextSpawnIn = FlxG.random.float(min, max);
	}

	function trySpawnRandom():Void
	{
		var lane = FlxG.random.int(0, 1);
		var dir = defaultDirForLane(lane);

		var path = randomCarPath(null);
		var speed = FlxG.random.float(MIN_SPEED, MAX_SPEED);
		if (!spawnCar(path, lane, dir, speed, 0))
			return;

		if (FlxG.random.float(0, 1) < DOUBLE_SPAWN_CHANCE)
		{
			var trailPath = randomCarPath(path);
			spawnCar(trailPath, lane, dir, speed, TRAIL_GAP);
		}
	}

	function defaultDirForLane(lane:Int):Int
	{
		return lane == 0 ? -1 : 1;
	}

	function randomCarPath(?exclude:String):String
	{
		if (CAR_PATHS.length == 1)
			return CAR_PATHS[0];

		var path = CAR_PATHS[FlxG.random.int(0, CAR_PATHS.length - 1)];
		while (exclude != null && path == exclude && CAR_PATHS.length > 1)
			path = CAR_PATHS[FlxG.random.int(0, CAR_PATHS.length - 1)];

		return path;
	}

	function spawnCar(path:String, lane:Int, dir:Int, speed:Float, trailGap:Float):Bool
	{
		var height = carHeightFor(lane);
		var car = new MainMenuTrafficCar(path, dir, lane, speed, height);
		var carWidth = car.getTravelWidth();

		if (!canSpawn(lane, dir, carWidth, trailGap))
		{
			car.destroy();
			return false;
		}

		placeCarOnLane(car, lane);

		var trailOffset = trailGap * carWidth;
		if (dir < 0)
			car.x = sceneW + SPAWN_MARGIN + trailOffset;
		else
			car.x = -carWidth - SPAWN_MARGIN - trailOffset;

		laneLayer(lane).add(car);
		cars.push(car);
		return true;
	}

	function carHeightFor(lane:Int):Float
	{
		return sceneH * CAR_HEIGHT_RATIO * (lane == 1 ? BOTTOM_CAR_SCALE : 1.0);
	}

	function laneLayer(lane:Int):FlxGroup
	{
		return lane == 0 ? topLaneLayer : bottomLaneLayer;
	}

	function canSpawn(lane:Int, dir:Int, carWidth:Float, trailGap:Float):Bool
	{
		var minGap = MIN_CAR_GAP * carWidth;
		var trailOffset = trailGap * carWidth;
		var spawnX = dir < 0 ? sceneW + SPAWN_MARGIN + trailOffset : -carWidth - SPAWN_MARGIN - trailOffset;

		for (car in cars)
		{
			if (car.lane != lane)
				continue;

			if ((dir < 0 && car.vx >= 0) || (dir > 0 && car.vx <= 0))
				continue;

			if (dir < 0)
			{
				if (car.x + car.getTravelWidth() > spawnX - minGap)
					return false;
			}
			else if (car.x < spawnX + carWidth + minGap)
				return false;
		}

		return true;
	}

	function placeCarOnLane(car:MainMenuTrafficCar, lane:Int):Void
	{
		var laneY = sceneH * (lane == 0 ? TOP_LANE_Y_RATIO : BOTTOM_LANE_Y_RATIO);
		car.setLaneY(laneY);
	}

	function removeCarAt(index:Int):Void
	{
		var car = cars[index];
		car.destroy();
		cars.splice(index, 1);
	}

	function clearCars():Void
	{
		for (car in cars)
			car.destroy();
		cars = [];
		topLaneLayer.clear();
		bottomLaneLayer.clear();
	}
}
