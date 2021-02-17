package laerm;

import om.FetchTools;
import js.html.Element;
import js.html.DivElement;
import js.Browser.document;
import js.Browser.window;
import js.html.AudioElement;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.lib.Uint8Array;
import om.audio.VolumeMeter;

class Radio {

	//static var SERVER = "https://rrr.disktree.net:8443";
	//static var MOUNT = "laerm";
	static var STATUS_PATH = "server_version-json.xsl";

	public final server : String;
	public final mount : String;

	public var color = "#050505";
	public var lineWidth = 100;
	public var audio(default,null) : AudioElement;
    public var started(default,null) = false;
	public var canvas(default,null) : CanvasElement;

	var ctx : CanvasRenderingContext2D;
	var volume : om.audio.VolumeMeter;
	var analyser : AnalyserNode;
	var timeData : Uint8Array;
	//var freqData : Uint8Array;
	
	var animationFrameId : Int;
	var info : DivElement;
	var status : DivElement;

    public function new( server : String, mount : String ) {

		this.server = server;
		this.mount = mount;

        //canvas = cast document.body.querySelector("main>.radio>canvas");
        canvas = document.createCanvasElement();

		info = cast document.body.querySelector('main>.info');
		status = cast document.body.querySelector('main>.status');

		ctx = canvas.getContext("2d");

		ctx.strokeStyle = color;
		ctx.fillStyle = color;

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

		//freqData = new Uint8Array( analyser.frequencyBinCount );
		timeData = new Uint8Array( analyser.frequencyBinCount );

		var source = audioContext.createMediaElementSource( audio );
		source.connect( analyser );

		volume = new VolumeMeter( audioContext );
		source.connect( volume.processor );

		audio.onplaying = function() {

			//if( started ) return;
			started = true;

			info.classList.add('hidden');
			//canvas.classList.remove('hidden');
			
			animationFrameId = window.requestAnimationFrame( update );
		}

		/* audio.onloadstart = e -> {
			//info.textContent = "…";
		} */

		audio.onpause = e -> {
			started = false;
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

		var mainElement = document.body.querySelector("main");
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
					var e = document.createDivElement();
					e.textContent = source.metadata.title;
					status.append( e );
					/* e = document.createDivElement();
					e.textContent = source.metadata.tracknumber+"/"+source.playlist.trackList.length;
					status.append( e ); */
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

		// ctx.fillStyle = "#000";
		// ctx.font = '50px Title';
		// ctx.fillText('LAERRRRRRRRRRRM', 50, 90);

		/* trace(volume.volume);
		if( volume.rms > 0.3 ) {
			color = '#fff000';
		} else {
			color = '#000';
		} */

		lineWidth = Std.int( (volume.volume)*1000 );

		//analyser.getByteFrequencyData( freqData );
		analyser.getByteTimeDomainData( timeData );

		ctx.clearRect( 0, 0, canvas.width, canvas.height );

		var v : Float, x : Float, y : Float;
		var hw = canvas.width/2, hh = canvas.height/2;

		ctx.strokeStyle = color;
		ctx.lineWidth = lineWidth;
		ctx.beginPath();
		for( i in 0...analyser.frequencyBinCount ) {
			v = (Math.PI/2)/180*i;
			x = Math.cos(v) * (timeData[i] ) ;
			y = Math.sin(v) * (timeData[i] ) ;
			ctx.lineTo( hw + x, hh + y );
		}
		ctx.stroke();
    }
}
