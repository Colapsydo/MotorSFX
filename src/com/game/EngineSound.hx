package com.game;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.utils.ByteArray;
import flash.Vector;
import openfl.Assets;

/**
 * ...
 * @author Colapsydo
 */

class EngineSound extends EventDispatcher
{
	//PLAYING VAR
	var _soundChannel:SoundChannel;
	var _transform:SoundTransform;
	var _volume:Float;
	var _mute:Bool;
	var _cueStart:Int;
	var _cueStop:Int;
	
	//STATIC SOUNDS
	var _soundPlayingNum:Int;
	var _staticSounds:Vector<Sound>;
	var _playedSound:Sound;
	
	//PITCHCHANGE VAR
	var _playbackSpeed:Float = 1;
	var _loadedSample:ByteArray;
	var _dynamicSound:Sound;
	var _phase:Float;
	var _numSamples:Int;
	var _pan:Float;
	
	//DYNAMIC SOUNDS
	var _actualSampleNum:Int;
	var _byteList:Vector<ByteArray>;
	var _lengthList:Vector<Int>;
	var _offsetRpm:Vector<Int>;
	var _ratioList:Vector<Float>;
	
	var _firstPhase:Float;
	
	static public inline var STARTOVER:String = "startover";
	
	public function new():Void {
		super();
		init();
	}
	
	function init():Void {
		//_numFilesLoaded = 0;	
		
		_staticSounds = Vector.ofArray([Assets.getSound("stdby"),Assets.getSound("start")]);
		
		//PITCHED SFX
		_byteList = new Vector<ByteArray>();
		_lengthList = new Vector<Int>();
		_offsetRpm = new Vector<Int>();
		_ratioList = new Vector<Float>();
		
		var sound:Sound = Assets.getSound("first");
		var byte1:ByteArray = new ByteArray();
		sound.extract(byte1, Std.int(sound.length * 44.1));
		_byteList.push(byte1);
		_lengthList.push(byte1.length);
		_offsetRpm.push(1000);
		//_ratioList.push((_lengthList[0] - 2048 * 8) / (8000+_offsetRpm[0]));
		_ratioList.push((8000-_offsetRpm[0])*2048*8/_lengthList[0]); // how much sample rpm I've got in each sample of 2048 databytes
		
		sound = Assets.getSound("second");
		var byte2:ByteArray = new ByteArray();
		sound.extract(byte2, Std.int(sound.length * 44.1));
		_byteList.push(byte2);
		_lengthList.push(byte2.length);
		_offsetRpm.push(4500);
		//_ratioList.push((_lengthList[1] - 2048 * 8) / (8000 - _offsetRpm[1]));
		_ratioList.push((8000-_offsetRpm[1])*2048*8/_lengthList[1]); // how much sample rpm I've got in each sample of 2048 databytes
		
		sound = Assets.getSound("third");
		var byte3:ByteArray = new ByteArray();
		sound.extract(byte3, Std.int(sound.length * 44.1));
		_byteList.push(byte3);
		_lengthList.push(byte3.length);
		_offsetRpm.push(5457);
		//_ratioList.push((_lengthList[2] - 2048 * 8) / (8000 - _offsetRpm[2]));
		_ratioList.push((8000 - _offsetRpm[2]) * 2048 * 8 / _lengthList[2]); // how much sample rpm I've got in each sample of 2048 databytes
		
		
		sound = Assets.getSound("fourth");
		var byte4:ByteArray = new ByteArray();
		sound.extract(byte4, Std.int(sound.length * 44.1));
		_byteList.push(byte4);
		_lengthList.push(byte4.length);
		_offsetRpm.push(5929);
		//_ratioList.push((_lengthList[3] - 2048 * 8) / (8000 - _offsetRpm[3]));
		_ratioList.push((8000-_offsetRpm[3])*2048*8/_lengthList[3]); // how much sample rpm I've got in each sample of 2048 databytes
		
		sound = Assets.getSound("fifth");
		var byte5:ByteArray = new ByteArray();
		sound.extract(byte5, Std.int(sound.length * 44.1));
		_byteList.push(byte5);
		_lengthList.push(byte5.length);
		_offsetRpm.push(6295);
		//_ratioList.push((_lengthList[4]-2048*8) / (8000-_offsetRpm[4]));
		_ratioList.push((8000-_offsetRpm[4])*2048*8/_lengthList[4]); // how much sample rpm I've got in each sample of 2048 databytes
		
		sound = Assets.getSound("sixth");
		var byte6:ByteArray = new ByteArray();
		sound.extract(byte6, Std.int(sound.length * 44.1));
		_byteList.push(byte6);
		_lengthList.push(byte6.length);
		_offsetRpm.push(6384);
		//_ratioList.push((_lengthList[5] - 2048 * 8) / (8000 - _offsetRpm[5]));
		_ratioList.push((8000-_offsetRpm[5])*2048*8/_lengthList[5]); // how much sample rpm I've got in each sample of 2048 databytes
		
		//trace(_ratioList);
		
		//CHANNEL SETTINGS
		
		//_numFiles = _sfxlist.length;
			
		_mute = false;
		_volume = 0.5;
		_pan = 0;
		_transform = new SoundTransform();
		_transform.volume = _volume;
	}
	
	//TEST IDEA TO CUT EACH BIG_SAMPLE IN USEABLE MINI LOOP
		// DETERMINE WHICH MINIMAL LENGTH IS NEEDED TO OBTAIN THE SMALLEST NICE AND AUDIBLE MINILOOP 
		// SCREEN THE BYTE ARRAY USING THE bytesAvailable PROPERTY TO GO FROM START TO END
			//ADDING THE MINIMAL DURATION OF A MINI LOOP
			// SEARCH FOR THE NEXT POSITION WHERE VALUES LEFT AND RIGHT ARE CLOSE TO 0 (SEAMLESS LOOP)
			// WRITING THE POSITION IN A LIST
	
		// WHILE PLAYING THE SOUND, WE LOOK FOR THE ABSOLUTE POSITION (FROM THE RPM)
		// WE TOOK THE CLOSEST POSITION PRESENT IN THE CORRESPONDING LIST (ALGO TO THINK)
		// PLAYING THE LOOP
	
	//this should be the best way to read samples on the fly 
	//but I still need to found a pretty way to determine the correspondance between the sample rpm and its position
	//the linear assumption seems correct enough but I need to be sure of the limit for each sample
	//not sure gears are shifted at 8000 each time.
	//also I should try the real data and the crisis car data...
	
	function stopDynamic():Void {
		if (_dynamicSound!=null) {
			_dynamicSound.removeEventListener(SampleDataEvent.SAMPLE_DATA, SampleDataHandler);
			_dynamicSound.removeEventListener(SampleDataEvent.SAMPLE_DATA, SampleLoopDataHandler);
			_dynamicSound = null;
		 }
	}
	
	function playDynamic(bytes:ByteArray):Void {
		stopDynamic();
		_dynamicSound = new Sound();
		_dynamicSound.addEventListener(SampleDataEvent.SAMPLE_DATA, SampleDataHandler);
	
		_loadedSample = bytes;
		_numSamples = Std.int(_lengthList[_actualSampleNum]*0.125);
		
		_phase = 0;
		_dynamicSound.play();
	}
	
	function SampleDataHandler(e:SampleDataEvent):Void {
		var l:Float;
		var r:Float;
		var outputLength:Int = 0;
		while (outputLength < 2048) {
			// until we have filled up enough output buffer
		   
			// move to the correct location in our loaded samples ByteArray
			_loadedSample.position = Std.int(_phase) * 8; // 4 bytes per float and two channels so the actual position in the ByteArray is 8 times the phase
			   
			// read out the left and right channels at this position
			l = _loadedSample.readFloat()*_volume*(1+_pan)*.5;
			r = _loadedSample.readFloat()*_volume*(1-_pan)*.5;
			  
			// write the samples to our output buffer
			e.data.writeFloat(l);
			e.data.writeFloat(r);
			   
			outputLength++;
			   
			// advance the phase by the speed...
			_phase += _playbackSpeed;
			   
			// and deal with looping (including looping back past the beginning when playing in reverse)
			 if (_phase < 0) {
               _phase += _numSamples;
            } else if (_phase >= _numSamples) {
               _phase -= _numSamples;
            }
			
			//if (_phase > _numSamples-8) {
				//stopDynamic();
				//return(null);
			//}
			
		 }
	}
	
	function playMovingLoop(bytes:ByteArray):Void{
		_dynamicSound = new Sound();
		_dynamicSound.addEventListener(SampleDataEvent.SAMPLE_DATA, SampleLoopDataHandler);
		
		_loadedSample = bytes;
		_numSamples = 2048;
		
		_phase = _firstPhase;
		_dynamicSound.play();
	}
	
	private function SampleLoopDataHandler(e:SampleDataEvent):Void {
		var l:Float;
		var r:Float;
		var outputLength:Int = 0;
		while (outputLength < 2048) {
			// until we have filled up enough output buffer
		   
			// move to the correct location in our loaded samples ByteArray
			_loadedSample.position = Std.int(_phase) * 8; // 4 bytes per float and two channels so the actual position in the ByteArray is 8 times the phase
			   
			// read out the left and right channels at this position
			l = _loadedSample.readFloat()*_volume*(1+_pan)*.5;
			r = _loadedSample.readFloat()*_volume*(1-_pan)*.5;
			  
			// write the samples to our output buffer
			e.data.writeFloat(l);
			e.data.writeFloat(r);
			   
			outputLength++;
			   
			// advance the phase by the speed...
			_phase += _playbackSpeed;
			   
			// and deal with looping
			if (_phase >= _firstPhase+_numSamples) {
               _phase -= _numSamples;
            }
		}
	}
	
	
	private function loopHandler(e:Event):Void { //TO LOOP SOUND
		_soundChannel.removeEventListener(Event.SOUND_COMPLETE , loopHandler);
		_soundChannel = _playedSound.play(_cueStart,0,_transform);
		_soundChannel.addEventListener(Event.SOUND_COMPLETE , loopHandler);
	}
	
	private function loopStopHandler(e:Event):Void {
		if (_soundChannel.position >= _cueStop) {
			_soundChannel = _playedSound.play(_cueStart, 0, _transform);			
		}
	}
	
	private function stopSoundHandler(e:Event):Void {
		e.target.removeEventListener(Event.SOUND_COMPLETE, stopSoundHandler);
		(e.target).stop();
		
		switch(_soundPlayingNum) {
			case 1:
				dispatchEvent(new Event(STARTOVER));
		}
	}
	
	
	//PUBLIC FUNCTIONS
	
	public function playStatic (soundNum:Int, loop:Bool=true, cueStart:Int=0, cueStop:Int=0, start:Int=0):Void {
		_soundPlayingNum = soundNum;
		
		if (soundNum < _staticSounds.length) {
				stopDynamic();
			if (_soundChannel!=null) {
				stopSound();
			}
			
			_playedSound = _staticSounds[soundNum];
			start = start == 0 ? cueStart : start;
			_soundChannel = _playedSound.play(start, 0, _transform);
			
			if (loop) {
				_cueStart = cueStart;
				_cueStop = cueStop;
				if (_cueStop == 0) {
					_soundChannel.addEventListener(Event.SOUND_COMPLETE, loopHandler);
				}else {
					addEventListener(Event.ENTER_FRAME, loopStopHandler);
				}
				
			}else {
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, stopSoundHandler);
			}
		}
	}
	
	public function playEngineSound(rpm:Float,gear:Int):Void {
		stopSound();
		stopDynamic();
		
		_actualSampleNum = gear-1;
		var offset:Int = _offsetRpm[_actualSampleNum];
		if (rpm >= offset && rpm < 8000) {
			_playbackSpeed = 1;
			//_firstPhase = (rpm-offset) * _ratioList[_actualSampleNum]*.125;
			_firstPhase = Std.int((rpm - offset) / _ratioList[_actualSampleNum]) * 2048;
			if ((_firstPhase+_numSamples)*8 >= _lengthList[_actualSampleNum]){ _firstPhase -=_numSamples;}
		}else {
			if (rpm < offset) {
				_firstPhase = 0;
				_playbackSpeed = rpm / offset;
			}
		}
		
		var bytes:ByteArray = _byteList[_actualSampleNum];
		playMovingLoop(bytes);
	}
	
	public function setRpm(rpm:Int, gear:Int):Void {
		var offset:Int = _offsetRpm[_actualSampleNum];
		if (_actualSampleNum != gear - 1) {
			_actualSampleNum = gear - 1;
			_loadedSample = _byteList[_actualSampleNum];
			//trace(gear, rpm);
		}
		
		
		if (rpm >= offset && rpm < 8000) {
			_playbackSpeed = 1;
			//_firstPhase = (rpm - offset) * _ratioList[_actualSampleNum] * .125;
			_firstPhase = Std.int(((rpm - offset) / _ratioList[_actualSampleNum])) * 2048;
			if ((_firstPhase+_numSamples)*8 >= _lengthList[_actualSampleNum]){ _firstPhase -=_numSamples;}
		}else {
			if (rpm < offset) {
				_firstPhase = 0;
				_playbackSpeed = rpm/offset;
			}else {
				_firstPhase = _lengthList[_actualSampleNum] - 2048 * 8;
				_playbackSpeed = rpm/8000;
			}
		}
	}
	
	public function stopSound():Void {
		_soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSoundHandler);
		_soundChannel.removeEventListener(Event.COMPLETE, loopHandler);		
		removeEventListener(Event.ENTER_FRAME, loopStopHandler);
		_soundChannel.stop();
		_soundChannel = null;
	}
	
	public function getVolume():Float { return(_volume); }
	
	public function setVolume(vol:Float):Void {
		if (_mute == false) {
			_volume = vol;
			_transform.volume = _volume;
			if (_soundChannel!=null) {
				_soundChannel.soundTransform = _transform;
			}
		}
	}
	
	public function setMute(mute:Bool):Void {
		_mute = mute;
		if (_mute == true) {
			_volume = 0;
			_transform.volume = _volume;
			if (_soundChannel!=null) {
				_soundChannel.soundTransform = _transform;
			}
		}else {
			setVolume(0.3);
		}
	}
	
}