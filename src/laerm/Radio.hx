package laerm;

import js.Browser.document;
import js.Browser.window;
import js.html.Element;
import js.html.DivElement;
import js.html.AudioElement;
import js.html.CanvasElement;
import js.html.InputElement;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.lib.Uint8Array;
import om.FetchTools;
import om.audio.VolumeMeter;

class Radio {

	public final server : String;
	public final mount : String;
	public final statusPath : String;

	public var audio(default,null) : AudioElement;
    public var started(default,null) = false;
	public var canvas(default,null) : CanvasElement;
	public var volume(default,null) : om.audio.VolumeMeter;
	public var analyser(default,null) : AnalyserNode;
	public var metadata(default,null) : Dynamic;

	var timeData : Uint8Array;
	var freqData : Uint8Array;
	var animationFrameId : Int;
	var spectrum : Spectrum2D;
	//var spectrum : Spectrum3D;
	var info : DivElement;
	var status : DivElement;
	var volumeControl : InputElement;

    public function new( server : String, mount : String, statusPath : String ) {

		this.server = server;
		this.mount = mount;
		this.statusPath = statusPath;
	
		var mainElement = document.body.querySelector("main");

		canvas = cast mainElement.querySelector('canvas.spectrum');
		info = cast mainElement.querySelector('.info');
		status = cast mainElement.querySelector('.status');
		volumeControl = cast mainElement.querySelector('input.volume');

		audio = document.createAudioElement();
		audio.preload = "none";
		audio.crossOrigin = "anonymous";
		audio.controls = false;

		audio.onplaying = e -> {
			
			started = true;
			
			refreshMetadata();
			fitCanvas();

			canvas.classList.remove('hidden');
			info.classList.add('hidden');
			volumeControl.classList.remove('hidden');

			animationFrameId = window.requestAnimationFrame( update );

		}
		audio.onpause = e -> {
			started = false;
			canvas.classList.add('hidden');
			info.classList.remove('hidden');
			volumeControl.classList.add('hidden');
			window.cancelAnimationFrame( animationFrameId );
		}

		var sourceElement = document.createSourceElement();
		sourceElement.type = 'application/ogg';
		sourceElement.src = '$server/$mount';
		audio.appendChild( sourceElement );

		var audioContext = new AudioContext();
		if( audioContext == null ) audioContext = js.Syntax.code( 'new window.webkitAudioContext()' );
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

		volume = new VolumeMeter( audioContext );
		source.connect( volume.processor );

		spectrum = new Spectrum2D( this );

		refreshMetadata();

		canvas.onclick = function(){
            togglePlay();
		}
		mainElement.onmouseenter = e -> {
			if( !audio.paused )
				volumeControl.classList.remove('hidden');
		}
		mainElement.onmouseleave = e -> {
			volumeControl.classList.add('hidden');
		}
		info.onclick = function(){
            togglePlay();
        }

		volumeControl.addEventListener( 'input', e -> {
			audio.volume = Std.parseFloat( volumeControl.value );
		}, false );

		canvas.addEventListener('wheel', e -> {
			if( e.deltaY > 0 ) {
				var v = audio.volume - 0.1; 
				if( v < 0 ) v = 0;
				audio.volume = v; 
			} else {
				var v = audio.volume + 0.1; 
				if( v > 1.0 ) v = 1;
				audio.volume = v; 
			}
			volumeControl.value = Std.string( audio.volume );
		}, false );

		window.addEventListener( 'resize', e -> {
			fitCanvas( mainElement );
        }, false );
    }

	public function togglePlay() {
		if( audio == null )
			return;
		if( audio.paused ) {
			audio.play();
		} else {
			audio.pause();
		}
	}

	public function refreshMetadata() {
		/* for( c in status.children ) c.remove();
		function addRow( text : String ) {
			var e = document.createDivElement();
			e.textContent = text;
			status.append( e );
		} */
		FetchTools.fetchJson( '$server/$statusPath' ).then( data -> {
			//trace(data.icestats);
			this.metadata = data;
			for( source in cast(data.icestats.source,Array<Dynamic>) ) {
				if( source.server_name == "Laerm" ) {
					//trace(source.metadata);
					status.textContent = '${source.title} / ${source.listeners}|${source.listener_peak} USERS';
					//addRow( source.title );
					//addRow( '${source.listeners}/${source.listener_peak} USERS' );
					fitCanvas();
					break;
				}
			}
		} );
	}

	public function fitCanvas( ?parent : Element ) {
		if( parent == null ) parent = document.body.querySelector("main");
		var r = parent.getBoundingClientRect();
		canvas.width = Std.int( r.width );
		canvas.height = Std.int( r.height+2 ); // Hack to hide bottom border
		///spectrum.renderer.setSize( Std.int( r.width ), Std.int( r.height ) );
	}

    function update( time : Float ) {
		animationFrameId = window.requestAnimationFrame( update );
		//fitCanvas();
		analyser.getByteTimeDomainData( timeData );
		analyser.getByteFrequencyData( freqData );
		spectrum.render( timeData );
    }
}
