package com.game;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;

/**
 * ...
 * @author Colapsydo
 */

class Control extends Sprite
{
	var _engine:Engine;
	var _engineSound:EngineSound;
	
	var _left:Bool;
	var _up:Bool;
	var _right:Bool;
	var _down:Bool;
	
	var _rpm:Int;
	var _gear:Int;
	var _minRpm:Int;
	
	var _startOver:Bool;
	var _state:String;
	
	static inline var STDBY:String = "stdby";
	static inline var START:String = "start";
	static inline var FIRSTUP:String = "firstup";
	static inline var SECUP:String = "secup";
	static inline var FIRSTDOWN:String = "firstdown";
	
	public function new():Void {
		super();
		
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	private function init(e:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		addEventListener(Event.REMOVED_FROM_STAGE, dispose);
		
		_engine = new Engine();
		addChild(_engine);
		
		_engineSound = new EngineSound();
		_rpm = 1000;
		_minRpm = 1000;
		_state = STDBY;
		_engineSound.playStatic(0, true, 0, 0);
		addEventListener(Event.ENTER_FRAME, efHandler);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, kdHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, kuHandler);
	}
	
	//HANDLERS
	
	private function efHandler(e:Event):Void {
		_engine.update(_left, _up, _right, _down);
		
		_rpm = _engine.getRPM();
		_gear = _engine.getGear();
		
		//if (_minRpm > _rpm) {
			//trace(_gear, _rpm);
		//}
		_minRpm = _rpm;
		
		switch(_state) {
			case STDBY:
				if (_right == true) {
					if (_rpm > 1000) {
						_engineSound.playEngineSound(_rpm,_gear);
						_state = FIRSTUP;
					}
					//_engineSound.playStatic(1, false);
					//_engineSound.addEventListener(EngineSound.STARTOVER, startOverHandler);
					//_startOver = false;
					//_state = START;
				}
			case START:
				if (_right == true) {
					if (_startOver == true) {
						_rpm = 1000;
						_engine.setStartRPM();
						_engineSound.playEngineSound(_rpm,1);
						_state = FIRSTUP;
					}
				}else {
					_engineSound.removeEventListener(EngineSound.STARTOVER, startOverHandler);
					_engineSound.playStatic(0, true, 0, 0);
					_state = STDBY;
				}
				
			case FIRSTUP:
				_engineSound.setRpm(_rpm, _gear);
				if (_rpm == 1000) {
					_state = STDBY;
					_engineSound.playStatic(0, true, 0, 0);
				}
		}
		
	}
	
	private function startOverHandler(e:Event):Void {
		_engineSound.removeEventListener(EngineSound.STARTOVER, startOverHandler);
		_startOver = true;
	}
	
	private function kdHandler(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 37:
				_left = true;
			case 38:
				_up = true;
			case 39:
				_right = true;
			case 40:
				_down = true;
		}
	}
	
	private function kuHandler(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 37:
				_left = false;
			case 38:
				_up = false;
			case 39:
				_right = false;
			case 40:
				_down = false;
		}
	}
	
	//PRIVATE FUNCTIONS
	
	//PUBLIC FUNCTIONS
	
	//GETTERS && SETTERS
	
	//DISPOSE

	private function dispose(e:Event):Void {
		removeEventListener(Event.REMOVED_FROM_STAGE, dispose);
		
		while (numChildren > 0) {removeChildAt(0);}
		
	}
}