package laerm;

import om.FetchTools;
import js.html.Element;
import js.html.DivElement;
import js.Browser.document;
import js.Browser.window;
import js.html.AudioElement;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.InputElement;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.lib.Uint8Array;
import om.audio.VolumeMeter;
import laerm.App.BORDER_WIDTH;

class Radio {

	static var STATUS_PATH = "server_version-json.xsl";

	public final server : String;
	public final mount : String;

	public var colorStroke = "#050505";
	public var colorFill = "#fff000";

	public var audio(default,null) : AudioElement;
    public var started(default,null) = false;
	public var canvas(default,null) : CanvasElement;

	var ctx : CanvasRenderingContext2D;
	var volumeMeter : om.audio.VolumeMeter;
	var analyser : AnalyserNode;
	var timeData : Uint8Array;
	var freqData : Uint8Array;
	
	var animationFrameId : Int;
	var info : DivElement;
	var status : DivElement;
	//var volume : InputElement;

    public function new( server : String, mount : String ) {

		this.server = server;
		this.mount = mount;

		var mainElement = document.body.querySelector("main");

        canvas = document.createCanvasElement();

		ctx = canvas.getContext("2d");
		ctx.strokeStyle = colorStroke;
		ctx.fillStyle = colorFill;

		// canvas2 = document.createCanvasElement();
		// canvas2.classList.add();

		info = cast mainElement.querySelector('.info');
		status = cast mainElement.querySelector('.status');
		
		/* volume = cast document.body.querySelector('main>input.volume');
		volume.addEventListener( 'input', e -> {
			audio.volume = Std.parseFloat(volume.value);
			trace(audio.volume);
		}); */
		
		audio = document.createAudioElement();
		audio.preload = "none";
		audio.crossOrigin = "anonymous";
		audio.controls = false;
		//audio.autoplay = true;

		var sourceElement = document.createSourceElement();
		sourceElement.type = 'application/ogg';
		sourceElement.src = '$server/$mount';
		audio.appendChild( sourceElement );

		var audioContext = new AudioContext();
		analyser = audioContext.createAnalyser();
		analyser.fftSize = 2048;
		//analyser.smoothingTimeConstant = 0.8;
		//analyser.minDecibels = -140;
		//analyser.maxDecibels = 0;
		analyser.connect( audioContext.destination );

		freqData = new Uint8Array( analyser.frequencyBinCount );
		timeData = new Uint8Array( analyser.frequencyBinCount );

		var source = audioContext.createMediaElementSource( audio );
		source.connect( analyser );

		volumeMeter = new VolumeMeter( audioContext );
		source.connect( volumeMeter.processor );

		audio.onplaying = function() {
			started = true;
			canvas.classList.add('play');
			info.classList.add('hidden');
			animationFrameId = window.requestAnimationFrame( update );
		}

		/* audio.onloadstart = e -> {
			//info.textContent = "…";
		} */

		audio.onpause = e -> {
			started = false;
			canvas.classList.remove('play');
			info.classList.remove('hidden');
			//canvas.classList.add('hidden');
			// button.textContent = "LAERM";
			// button.classList.remove('hidden');
			window.cancelAnimationFrame( animationFrameId );
			ctx.clearRect( 0, 0, canvas.width, canvas.height );
		}

		canvas.onclick = function() {
			if( started ) {
				started = false;
				audio.pause();
			} else {
				//info.textContent = "…";
				info.classList.add('hidden');
				audio.play();
			}
		}
		
		window.addEventListener( 'resize', e -> {
			fitCanvas( mainElement );
        }, false );

		refreshMetadata();
    }

	public function refreshMetadata() {
		for( c in info.children ) c.remove();
		FetchTools.fetchJson( '$server/$STATUS_PATH' ).then( data -> {
			trace(data.icestats);
			for( source in cast(data.icestats.source,Array<Dynamic>) ) {
				if( source.server_name == "Laerm" ) {
					trace(source.metadata);
					function addRow( text : String ) {
						var e = document.createDivElement();
						e.textContent = text;
						status.append( e );
					}
					addRow( source.title );
					addRow( '${source.listeners}/${source.listener_peak} USERS' );
					break;
				}
			}
		} );
	}

	public function fitCanvas( ?parent : Element ) {
		if( parent == null ) parent = document.body.querySelector("main");
		var r = parent.getBoundingClientRect();
		canvas.width = Std.int( r.width );
		canvas.height = Std.int( r.height );
	}

    function update( time : Float ) {

		animationFrameId = window.requestAnimationFrame( update );

		//fitCanvas();

		analyser.getByteTimeDomainData( timeData );
		analyser.getByteFrequencyData( freqData );
		
		ctx.clearRect( 0, 0, canvas.width, canvas.height );
		
		var v : Float, x : Float, y : Float;
		var hw = canvas.width/2, hh = canvas.height/2;
		
		//lineWidth = Std.int( (volumeMeter.volume)*1000 );

		//ctx.fillStyle = colorFill;
		//ctx.strokeStyle = color;
		ctx.fillStyle = colorFill;
		ctx.strokeStyle = colorStroke;

		ctx.lineWidth = Std.int( (volumeMeter.volume)*1000 );
		ctx.beginPath();
		for( i in 0...analyser.frequencyBinCount ) {
			v = (Math.PI/2)/180*i;
			x = Math.cos(v) * (timeData[i] );
			y = Math.sin(v) * (timeData[i] );
			ctx.lineTo( hw + x, hh + y );
		}
		ctx.stroke(); 
 
		var width = 24;
		var height = 24;
		var ox = BORDER_WIDTH;
		var oy = BORDER_WIDTH;
		//var oy = canvas.height - height - 8;
		ctx.lineWidth = 1;
		// ctx.fillStyle = '#050505';
		// ctx.strokeStyle = '#fff000';
		ctx.fillRect( ox, oy, width, height );
		ctx.rect( ox, oy, width, height );
		ctx.stroke();
		ctx.beginPath();
		var sliceWidth = width * 1.0 / analyser.frequencyBinCount;
  		x = 0.0;
		for( i in 0...analyser.frequencyBinCount ) {
            v = timeData[i] / 128.0;
			y = v * height / 2;
			if (i == 0) {
				ctx.moveTo( ox+x, oy+y);
			} else {
				ctx.lineTo( ox+x, oy+y);
			}
			x += sliceWidth;
		}
		ctx.moveTo(canvas.width, canvas.height / 2);
		ctx.stroke();
    }
}
