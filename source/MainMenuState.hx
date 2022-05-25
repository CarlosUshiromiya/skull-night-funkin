package;

import flixel.util.FlxTimer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.2h'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	public var iconBG:FlxSprite;
	public var icon:HealthIcon;
	public static var lastRoll:String = "bf";

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var thisShit:Bool = false;

	var bg:FlxSprite;
	var logoBl:FlxSprite;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(FlxG.width + 0, (i * 140) + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 3)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			FlxTween.tween(menuItem, {y: 30 + (i * 120)}, 1 + (i * 0.25), {
				ease: FlxEase.expoInOut,
				onComplete: function(flxTween:FlxTween)
				{
					changeItem();
					thisShit = true;
				}
			});
			menuItem.updateHitbox();
		}

		if (!ClientPrefs.lowQuality)
		{
			logoBl = new FlxSprite(-100, -100);

			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
			logoBl.scrollFactor.set();
			logoBl.antialiasing = ClientPrefs.globalAntialiasing;
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.setGraphicSize(Std.int(logoBl.width * 0.5));
			logoBl.animation.play('bump');
			logoBl.alpha = 0;
			logoBl.angle = -4;
			logoBl.updateHitbox();
			add(logoBl);
			FlxTween.tween(logoBl, {
				y: logoBl.y + 64,
				x: logoBl.x + 112,
				angle: -4,
				alpha: 1
			}, 1.4, {ease: FlxEase.expoInOut});
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 64, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.screenCenter(X);
		versionShit.setFormat("vcr.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.screenCenter(X);
		versionShit.setFormat("vcr.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		if (!ClientPrefs.lowQuality)
		{
			iconBG = new FlxSprite().loadGraphic(Paths.image('iconbackground'));
			iconBG.scrollFactor.set();
			iconBG.updateHitbox();
			iconBG.antialiasing = ClientPrefs.globalAntialiasing;
			add(iconBG);

			switch (FlxG.random.int(1, 5))
			{
				case 1:
					icon = new HealthIcon('bf');
					icon.setGraphicSize(Std.int(icon.width * 2));
					iconBG.color = FlxColor.CYAN;
				case 2:
					icon = new HealthIcon('gf');
					icon.setGraphicSize(Std.int(icon.width * 2));
					iconBG.color = FlxColor.RED;
				case 3:
					icon = new HealthIcon('dad');
					icon.setGraphicSize(Std.int(icon.width * 1.7));
					iconBG.color = FlxColor.PURPLE;
				case 4:
					icon = new HealthIcon('mom');
					icon.setGraphicSize(Std.int(icon.width * 1.8));
					iconBG.color = FlxColor.PURPLE;
				case 5:
					icon = new HealthIcon('spooky');
					icon.setGraphicSize(Std.int(icon.width * 2));
					switch (FlxG.random.int(1, 2))
					{
						case 1:
							iconBG.color = FlxColor.ORANGE;
						case 2:
							iconBG.color = FlxColor.WHITE;
					}
			} // YES, I WILL PUT THE HAXE COLORS INSTEAD THE NORMAL ONES

			// icon = new HealthIcon('bf');
			// icon.setGraphicSize(Std.int(icon.width * 2));
			icon.antialiasing = ClientPrefs.globalAntialiasing;
			icon.x = 70;
			icon.y = FlxG.height - 180;
			icon.scrollFactor.set();
			icon.updateHitbox();
			add(icon);
			trace(iconBG.color);
			trace(icon);
		}

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		Conductor.songPosition = FlxG.sound.music.time;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin && thisShit)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (-1 * Math.floor(FlxG.mouse.wheel) != 0)
			{
				changeItem(-1 * Math.floor(FlxG.mouse.wheel));
				FlxG.sound.play(Paths.sound('scrollMenu'));
				trace('lol ' + curSelected);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
				// Main Menu Back Animations
				FlxTween.tween(FlxG.camera, {zoom: 5}, 0.8, {ease: FlxEase.expoIn});
				FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
				FlxTween.tween(bg, {alpha: 0}, 0.8, {ease: FlxEase.expoIn});
				if (!ClientPrefs.lowQuality)
				{
					FlxTween.tween(logoBl, {
						alpha: 0,
						x: -100,
						y: -100,
						angle: 4
					}, 0.5, {ease: FlxEase.quadOut});
					FlxTween.tween(icon, {x: icon.x - 20, y: icon.y + 20}, 0.5, {ease: FlxEase.quadOut});
				}
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				// Main Menu Select Animations
				FlxTween.tween(FlxG.camera, {zoom: 5}, 0.8, {ease: FlxEase.expoIn});
				FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
				if (!ClientPrefs.lowQuality)
				{
					FlxTween.tween(logoBl, {
						alpha: 0,
						x: logoBl.x - 30,
						y: logoBl.y - 30,
						angle: 4
					}, 0.8, {ease: FlxEase.quadOut});
					FlxTween.tween(icon, {x: icon.x - 10, y: icon.y + 10}, 0.8, {ease: FlxEase.quadOut});
				}
				new FlxTimer().start(0.2, function(tmr:FlxTimer)
				{
					hideit(0.6);
				});

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						FlxTween.tween(spr, {alpha: 0.1, x: 1500}, 1, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
						FlxTween.tween(spr, {x: 1500}, 1, {
							ease: FlxEase.quadOut
						});
					}
					else
					{
						spr.updateHitbox();
						// spr.x += -300;
						FlxTween.tween(spr, {x: spr.x - 240, y: 260}, 0.5, {ease: FlxEase.quadOut});
						FlxTween.tween(spr.scale, {x: 1.2, y: 1.2}, 0.8, {ease: FlxEase.quadOut});

						new FlxTimer().start(1, function(tmr:FlxTimer)
						{
							goToState();
						});
					}
				});
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		if (!selectedSomethin)
		{
			menuItems.forEach(function(spr:FlxSprite)
			{
				spr.screenCenter(X);
				spr.x += 240;
			});
		}
	}

	function goToState()
	{
		var daChoice:String = optionShit[curSelected];

		switch (daChoice)
		{
			case 'story_mode':
				MusicBeatState.switchState(new StoryMenuState());
			case 'freeplay':
				MusicBeatState.switchState(new FreeplayState());
			#if MODS_ALLOWED
			case 'mods':
				MusicBeatState.switchState(new ModsMenuState());
			#end
			case 'awards':
				MusicBeatState.switchState(new AchievementsMenuState());
			case 'credits':
				MusicBeatState.switchState(new CreditsState());
			case 'options':
				MusicBeatState.switchState(new options.OptionsState());
		}
	}

	function hideit(time:Float)
	{
		menuItems.forEach(function(spr:FlxSprite)
		{
			FlxTween.tween(spr, {alpha: 0.0}, time, {ease: FlxEase.quadOut});
		});
		FlxTween.tween(bg, {alpha: 0}, time, {ease: FlxEase.expoIn});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4)
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();

				if (curSelected == 3)
				{
					if (spr.y != 30)
					{
						spr.y == 30;
					}
				}
				else
					spr.y == 0;
			}
		});
	}

	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null)
			logoBl.animation.play('bump', true);
	}
}
