package com.game;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Vector;

/**
 * ...
 * @author Colapsydo
 */	
class Engine extends Sprite 
{
	//defined in Constructor
	private var _auto:Bool;
	
	//Movement
	private var _speed:Float; //m.s-1
	private var _acceleration:Float; //m.s-2
	
	//Forces
	private var _forceTraction:Float; //N
	private var _forceDrag:Float; //N
	private var _forceFriction:Float; //N
	private var _forceBrake:Float; //N
	
	//Engine Var
	private var _RPM:Int;
	private var _RPMbreak:Bool;
	private var _RPMredLine:Int;
	private var _RPMcurve:Point;
	
	//Car Spec
	private var _carMass:Float; //kg
	private var _carWheel:Float; //m
	private var _cBrake:Float;
	
	//Gears
	private var _gearActual:Int; 
	private var _gearRatio:Vector<Float>;
		
	//Relative to FrameRate
	private var _deltaT:Float; //s
	
	//Keyboard action
	private var _up:Bool;
	private var _brake:Bool;
	private var _handBrake:Bool;
	
	//Connstants
	private var _diffRatio:Float = 4.46;
	private var _cDrag:Float = 0.38;
	private var _cFric:Float = 0.02;
	private var _transEfficiency:Float = 0.7;
	private var _convertion:Float;
		
	//Text on screen
	private var _textSpeed:TextField;
	private var _textTraction:TextField;
	private var _textFrict:TextField;
	private var _textDrag:TextField;
	private var _textBrake:TextField;
	private var _textRPM:TextField;
	private var _textGear:TextField;
	private var _textAXL:TextField;
	private var _textFrame:Shape;
	
		
	public function new():Void {
		super();
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
		
	private function init(e:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		_auto = true;
		_convertion = 60 / (2 * Math.PI);
		
		//Spec Car
		//_gearRatio = Vector.ofArray([4.1, 4.37, 2.71, 1.93, 1.50, 1.24, 1.04]);
		_gearRatio = Vector.ofArray([4.1, 3.37, 2.0, 1.60, 1.50, 1.24, 1.04]);
		_carMass = 1600;
		_carWheel = 0.66;
		_RPMredLine = 8000;
		
		//init var
		_RPMcurve = new Point();
		_handBrake = false;
		_speed = 0;
		_cBrake = 0;
		_RPM = 1000;
		_RPMbreak = false;
		_deltaT = 1 / stage.frameRate;
		_gearActual = 1;
		
		//init Forces
		_forceTraction = 0;
		_forceFriction = 0;
		_forceDrag = 0;
		_forceBrake = 0;
		
		//text
		_textFrame = new Shape();
		_textFrame.graphics.lineStyle(2, 0);
		_textFrame.graphics.drawRect(0, 0, 220, 90);
		addChild(_textFrame);
		
		var textFormat:TextFormat = new TextFormat("lucida console", 12, 0xFFFFFF);
		
		_textSpeed = new TextField();
		_textSpeed.defaultTextFormat = textFormat;
		addChild(_textSpeed);
		
		_textTraction = new TextField();
		_textTraction.defaultTextFormat = textFormat;
		_textTraction.y = 20;
		addChild(_textTraction);
		
		_textFrict = new TextField();
		_textFrict.defaultTextFormat = textFormat;
		_textFrict.y = 35;
		addChild(_textFrict);
		
		_textDrag = new TextField();
		_textDrag.defaultTextFormat = textFormat;
		_textDrag.y = 50;
		addChild(_textDrag);
		
		_textBrake = new TextField();
		_textBrake.defaultTextFormat = textFormat;
		_textBrake.y = 65;
		addChild(_textBrake);
		
		_textRPM = new TextField();
		_textRPM.defaultTextFormat = textFormat;
		_textRPM.x = 150;
		addChild(_textRPM);
		
		_textGear = new TextField();
		_textGear.defaultTextFormat = textFormat;
		_textGear.x = 150;
		_textGear.y = 20;
		addChild(_textGear);
		
		_textAXL = new TextField();
		_textAXL.defaultTextFormat = textFormat;
		_textAXL.x = 150;
		_textAXL.y = 35;
		addChild(_textAXL);
	}
		
	//HANDLERS
	
	private function kdHandler(e:KeyboardEvent):Void {	
		switch (e.keyCode) {
			case 40:
				if (_gearActual > 1 && _auto == false) {
					_gearActual--;
				}
			
			case 39:
				if (_RPMbreak == false) {
					_up = true;
				}
			
			case 38:
				if (_gearActual < (_gearRatio.length-1)  && _auto == false) {
					_gearActual++;
				}
			
			case 37:
				_cBrake = 12.4*(1+ 2*0.1); // BRAKE + UPGRADE BRAKE
				_brake = true;
			
			case 32:
				_handBrake = true;
		}
	}
		
	private function kuHandler(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 39:
				_up = false;
			
			case 37:
				_cBrake = 0;
				_brake = false;
			
			case 32:
				_handBrake = false;
		}
	}
	
	//PRIVATE FUNCTIONS
	
	private function tractionCalculate():Void {
		_RPMcurve = engineR8(_RPM);
		_forceTraction = ((_RPMcurve.x * _RPM + _RPMcurve.y + 40) * _gearRatio[_gearActual] * (_diffRatio*(1+2*0.1)) * _transEfficiency) / (_carWheel * 0.5); //UPGRADE SPEED sum in force traction and UPGRADE AXL  + %Diffratio
	}
	
	private function opponentCalculate():Void {
		_forceBrake = - _cBrake;
		_forceDrag = - (0.5*_cDrag * 1.94* 1.29 *_speed * _speed);
		_forceFriction = - (_cFric *9.81*_carMass);
	}
	
	private function engineR8(rpm:Int):Point {
		if (rpm >6500) {
			return(new Point( -0.065, 972));
		}else {
			if (rpm >4000) {
				return(new Point(0.02, 420));
			}else {
				if (rpm > 3000) {
					return(new Point(0.04, 280));
				}else {
					if (rpm > 1000) {
						return(new Point(0.03, 370));
					}else {
						return(new Point(0.025, 60));
					}
				}
			}
		}
	}
		
	//PUBLIC FUNCTIONS
	
	public function update(left:Bool, up:Bool, right:Bool, down:Bool) {
		if (left == true) {
			if (_brake == false) {
				_cBrake = 12.4*(1+ 2*0.1); // BRAKE + UPGRADE BRAKE
				_brake = true;
			}
		}else {
			if (_brake == true) {
				_cBrake = 0;
				_brake = false;
			}
		}		
		if (up == true) {
			if (_gearActual < (_gearRatio.length-1)  && _auto == false) {
				_gearActual++;
			}
		}	
		if (right == true) {
			if (_RPMbreak == false) {
				_up = true;
			}
		}else {
			_up = false;
		}		
		if (down == true) {
			if (_gearActual > 1 && _auto == false) {
				_gearActual--;
			}
		}
		
		//ENGINE UPDATE
		
		if (_RPM < 0.95 * _RPMredLine) { //Retrigger of RPMBreak
			_RPMbreak = false;
		}
		
		if (_up == true && _RPM < _RPMredLine && _RPMbreak == false ) { //Gaz must be on and rpm under redline
			tractionCalculate(); 
		}else {
			if (_RPM >= _RPMredLine) { //avoid a subit acceleration
				_RPMbreak = true;
			}
			_forceTraction = -0.70* _RPM *0.166; //EngineBrake
		}
		opponentCalculate();
		
		if (_handBrake == false) { // Avoid a null gear position
			_acceleration = ((((_forceTraction + _forceFriction + _forceDrag) / _carMass) + _forceBrake ) * _deltaT);
			_speed += _acceleration;
			if (_speed < 0) { _speed = 0; }
			_RPM = Std.int((_speed / (_carWheel * 0.5)) * _gearRatio[_gearActual] * (_diffRatio*(1-2*0.05)) * _convertion); //UPGRADE SPEED - %Diffratio
		}else {
			_acceleration = (( ((_forceTraction) / _carMass) - 1 + _forceBrake)* _deltaT);
			_RPM += Std.int(_acceleration*1300);
		}
			
		if (_RPM < 1000) { _RPM = 1000;}
		if (_RPM > _RPMredLine) { _RPM = _RPMredLine; }
		
		//AUTO MODE
		if (_auto == true) {
			if (_RPM > 0.95 * _RPMredLine && _gearActual < (_gearRatio.length - 1) ) {
				_gearActual++;
			}
			if (_up == false && _gearActual > 1) {
				if (_RPM < (0.94*_RPMredLine * _gearRatio[_gearActual] / _gearRatio[_gearActual-1])) {
					_gearActual--;
				}
			}
		}
		
		//text
			_textSpeed.text = "Speed: " + Math.round(_speed*3.6) + " km/h";
			_textTraction.text = "Traction: " + Math.round(_forceTraction) + " N";
			_textFrict.text = "Friction: " + Math.round(_forceFriction) +" N";
			_textDrag.text = "Drag: " + Math.round(_forceDrag) +" N";
			_textBrake.text = "Brake: " + _forceBrake*_carMass*0.001 + " kN";
			_textRPM.text = "RPM: " + _RPM;
			_textGear.text = "Gear: " + _gearActual;
			_textAXL.text = "AXL: " + _acceleration + " ms-2";
			_textAXL.width = 500;
		//text
	}
	
	public function setStartRPM():Void {
		_RPM = 1000;
	}
	
	public function stopEngine():Void {
		_up = false;
		_cBrake = 20;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, kdHandler);
	}
		
	//GETTERS && SETTERS
	
	public function getRPM():Int { return(_RPM); }
	public function getSpeed():Float { return(_speed); }
	public function getAxl():Float { return(_acceleration); }
	public function getBrake():Bool { return (_brake); }
	public function getGear():Int { 
		if (_handBrake == false) {
			return(_gearActual);
		}else {
			return(1);
		}
	}
		
	public function setSpeed(axl:Int):Void {
		_speed += axl;
	}
}