package;

import flixel.FlxG;
import flixel.group.FlxGroup;

class MainMenuClouds extends FlxGroup
{
	static inline var LANE_COUNT = 3;
	static inline var CLOUD_HEIGHT_RATIO = 0.1;
	static inline var SPAWN_MARGIN = 36.0;
	static inline var MIN_SPAWN_INTERVAL = 2.2;
	static inline var MAX_SPAWN_INTERVAL = 4.8;
	static inline var MIN_CLOUD_GAP = 2.1;
	static inline var TRAIL_GAP = 1.8;
	static inline var DOUBLE_SPAWN_CHANCE = 0.06;
	static inline var OPPOSITE_DIR_CHANCE = 0.08;
	static inline var FRONT_DEPTH_CHANCE = 0.32;
	static inline var INITIAL_CLOUDS_PER_LANE_MIN = 2;
	static inline var INITIAL_CLOUDS_PER_LANE_MAX = 3;
	static inline var FAST_CLOUD_CHANCE = 0.24;

	static inline var BACK_MIN_SPEED = 4.0;
	static inline var BACK_MAX_SPEED = 9.0;
	static inline var FRONT_MIN_SPEED = 8.0;
	static inline var FRONT_MAX_SPEED = 16.0;
	static inline var FAST_MIN_SPEED = 20.0;
	static inline var FAST_MAX_SPEED = 38.0;

	static inline var BACK_SCALE = 0.52;
	static inline var FRONT_SCALE = 0.92;
	static inline var BACK_MIN_ALPHA = 0.48;
	static inline var BACK_MAX_ALPHA = 0.68;
	static inline var FRONT_MIN_ALPHA = 0.84;
	static inline var FRONT_MAX_ALPHA = 1.0;

	static var LANE_Y_RATIOS:Array<Float> = [0.03, 0.07, 0.11];
	static var CLOUD_PATHS:Array<String> = [
		"static/Main_Menu/Cloud1.png",
		"static/Main_Menu/Cloud2.png",
		"static/Main_Menu/Cloud3.png",
		"static/Main_Menu/Cloud4.png",
		"static/Main_Menu/Cloud5.png",
		"static/Main_Menu/Cloud6.png",
		"static/Main_Menu/Cloud7.png",
		"static/Main_Menu/Cloud8.png",
		"static/Main_Menu/Cloud9.png",
		"static/Main_Menu/Cloud10.png",
	];

	var backLayer:FlxGroup;
	var frontLayer:FlxGroup;
	var clouds:Array<MainMenuTrafficCloud> = [];
	var sceneW = 800.0;
	var sceneH = 600.0;
	var baseCloudHeight = 66.0;
	var running = false;
	var spawnTimer = 0.0;
	var nextSpawnIn = 0.0;

	public function new()
	{
		super();

		backLayer = new FlxGroup();
		frontLayer = new FlxGroup();
		add(backLayer);
		add(frontLayer);
	}

	public function layout(w:Float, h:Float):Void
	{
		sceneW = w;
		sceneH = h;
		baseCloudHeight = h * CLOUD_HEIGHT_RATIO;

		for (cloud in clouds)
		{
			cloud.resize(cloudHeightFor(cloud.depth));
			placeCloudOnLane(cloud, cloud.lane);
		}
	}

	public function startClouds():Void
	{
		running = true;
		visible = true;
		spawnTimer = 0;
		seedInitialClouds();
		scheduleNextSpawn(1.0, 2.2);
	}

	public function stopClouds():Void
	{
		running = false;
		visible = false;
		clearClouds();
		spawnTimer = 0;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!running)
			return;

		spawnTimer += elapsed;
		if (spawnTimer >= nextSpawnIn)
		{
			spawnTimer = 0;
			scheduleNextSpawn(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL);
			trySpawnRandom();
		}

		var i = clouds.length - 1;
		while (i >= 0)
		{
			var cloud = clouds[i];

			if (cloud.vx < 0 && cloud.x + cloud.getTravelWidth() < -SPAWN_MARGIN)
				removeCloudAt(i);
			else if (cloud.vx > 0 && cloud.x > sceneW + SPAWN_MARGIN)
				removeCloudAt(i);

			i--;
		}
	}

	function scheduleNextSpawn(min:Float, max:Float):Void
	{
		nextSpawnIn = FlxG.random.float(min, max);
	}

	function seedInitialClouds():Void
	{
		for (lane in 0...LANE_COUNT)
		{
			var count = FlxG.random.int(INITIAL_CLOUDS_PER_LANE_MIN, INITIAL_CLOUDS_PER_LANE_MAX);
			for (_ in 0...count)
				tryPlaceInitialCloudForLane(lane);
		}
	}

	function tryPlaceInitialCloudForLane(lane:Int):Void
	{
		var depth = pickDepthForLane(lane);
		var dir = defaultDirForLane(lane);
		if (FlxG.random.float(0, 1) < OPPOSITE_DIR_CHANCE)
			dir = -dir;

		placeInitialCloud(randomCloudPath(null), lane, depth, dir, randomSpeedFor(depth), randomAlphaFor(depth));
	}

	function placeInitialCloud(path:String, lane:Int, depth:CloudDepth, dir:Int, speed:Float, alpha:Float):Bool
	{
		var height = cloudHeightFor(depth);
		var cloud = new MainMenuTrafficCloud(path, dir, lane, depth, speed, height, alpha);
		var cloudWidth = cloud.getTravelWidth();

		placeCloudOnLane(cloud, lane);

		var minX = 12.0;
		var maxX = Math.max(minX, sceneW - cloudWidth - 12.0);
		for (_ in 0...16)
		{
			var x = FlxG.random.float(minX, maxX);
			if (!canPlaceAt(lane, x, cloudWidth))
				continue;

			cloud.x = x;
			var layer = depth == Front ? frontLayer : backLayer;
			layer.add(cloud);
			clouds.push(cloud);
			return true;
		}

		cloud.destroy();
		return false;
	}

	function canPlaceAt(lane:Int, x:Float, cloudWidth:Float):Bool
	{
		var minGap = MIN_CLOUD_GAP * cloudWidth;
		var newLeft = x;
		var newRight = x + cloudWidth;

		for (cloud in clouds)
		{
			if (cloud.lane != lane)
				continue;

			var otherLeft = cloud.x;
			var otherRight = cloud.x + cloud.getTravelWidth();
			if (newRight + minGap >= otherLeft && newLeft <= otherRight + minGap)
				return false;
		}

		return true;
	}

	function trySpawnRandom():Void
	{
		var lane = FlxG.random.int(0, LANE_COUNT - 1);
		var depth = pickDepthForLane(lane);
		var dir = defaultDirForLane(lane);
		if (FlxG.random.float(0, 1) < OPPOSITE_DIR_CHANCE)
			dir = -dir;

		var path = randomCloudPath(null);
		var speed = randomSpeedFor(depth);
		var alpha = randomAlphaFor(depth);
		if (!spawnCloud(path, lane, depth, dir, speed, alpha, 0))
			return;

		if (FlxG.random.float(0, 1) < DOUBLE_SPAWN_CHANCE)
		{
			var trailPath = randomCloudPath(path);
			spawnCloud(trailPath, lane, depth, dir, speed, alpha, TRAIL_GAP);
		}
	}

	function pickDepthForLane(lane:Int):CloudDepth
	{
		var frontBias = lane >= LANE_COUNT - 2 ? 0.72 : lane <= 1 ? 0.18 : FRONT_DEPTH_CHANCE;
		return FlxG.random.float(0, 1) < frontBias ? Front : Back;
	}

	function defaultDirForLane(lane:Int):Int
	{
		return lane % 2 == 0 ? -1 : 1;
	}

	function randomCloudPath(?exclude:String):String
	{
		if (CLOUD_PATHS.length == 1)
			return CLOUD_PATHS[0];

		var path = CLOUD_PATHS[FlxG.random.int(0, CLOUD_PATHS.length - 1)];
		while (exclude != null && path == exclude && CLOUD_PATHS.length > 1)
			path = CLOUD_PATHS[FlxG.random.int(0, CLOUD_PATHS.length - 1)];

		return path;
	}

	function randomSpeedFor(depth:CloudDepth):Float
	{
		if (FlxG.random.float(0, 1) < FAST_CLOUD_CHANCE)
			return FlxG.random.float(FAST_MIN_SPEED, FAST_MAX_SPEED);

		return depth == Front
			? FlxG.random.float(FRONT_MIN_SPEED, FRONT_MAX_SPEED)
			: FlxG.random.float(BACK_MIN_SPEED, BACK_MAX_SPEED);
	}

	function randomAlphaFor(depth:CloudDepth):Float
	{
		return depth == Front
			? FlxG.random.float(FRONT_MIN_ALPHA, FRONT_MAX_ALPHA)
			: FlxG.random.float(BACK_MIN_ALPHA, BACK_MAX_ALPHA);
	}

	function cloudHeightFor(depth:CloudDepth):Float
	{
		return baseCloudHeight * (depth == Front ? FRONT_SCALE : BACK_SCALE);
	}

	function spawnCloud(path:String, lane:Int, depth:CloudDepth, dir:Int, speed:Float, alpha:Float, trailGap:Float):Bool
	{
		var height = cloudHeightFor(depth);
		var cloud = new MainMenuTrafficCloud(path, dir, lane, depth, speed, height, alpha);
		var cloudWidth = cloud.getTravelWidth();

		if (!canSpawn(lane, dir, cloudWidth, trailGap))
		{
			cloud.destroy();
			return false;
		}

		placeCloudOnLane(cloud, lane);

		var trailOffset = trailGap * cloudWidth;
		if (dir < 0)
			cloud.x = sceneW + SPAWN_MARGIN + trailOffset;
		else
			cloud.x = -cloudWidth - SPAWN_MARGIN - trailOffset;

		var layer = depth == Front ? frontLayer : backLayer;
		layer.add(cloud);
		clouds.push(cloud);
		return true;
	}

	function canSpawn(lane:Int, dir:Int, cloudWidth:Float, trailGap:Float):Bool
	{
		var minGap = MIN_CLOUD_GAP * cloudWidth;
		var trailOffset = trailGap * cloudWidth;
		var spawnX = dir < 0 ? sceneW + SPAWN_MARGIN + trailOffset : -cloudWidth - SPAWN_MARGIN - trailOffset;

		for (cloud in clouds)
		{
			if (cloud.lane != lane)
				continue;

			if ((dir < 0 && cloud.vx >= 0) || (dir > 0 && cloud.vx <= 0))
				continue;

			if (dir < 0)
			{
				if (cloud.x + cloud.getTravelWidth() > spawnX - minGap)
					return false;
			}
			else if (cloud.x < spawnX + cloudWidth + minGap)
				return false;
		}

		return true;
	}

	function placeCloudOnLane(cloud:MainMenuTrafficCloud, lane:Int):Void
	{
		var laneY = sceneH * LANE_Y_RATIOS[lane];
		cloud.setLaneY(laneY);
	}

	function removeCloudAt(index:Int):Void
	{
		var cloud = clouds[index];
		cloud.destroy();
		clouds.splice(index, 1);
	}

	function clearClouds():Void
	{
		for (cloud in clouds)
			cloud.destroy();
		clouds = [];
		backLayer.clear();
		frontLayer.clear();
	}
}
