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

	static var STATUS_PATH = "server_version-json.xsl";

	public final server : String;
	public final mount : String;

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
	//var volume : InputElement;

    public function new( server : String, mount : String ) {

		this.server = server;
		this.mount = mount;

		var mainElement = document.body.querySelector("main");

        canvas = document.createCanvasElement();

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

		volume = new VolumeMeter( audioContext );
		source.connect( volume.processor );

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
			//ctx.clearRect( 0, 0, canvas.width, canvas.height );
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

		spectrum = new Spectrum2D( this );
    }

	public function refreshMetadata() {
		for( c in info.children ) c.remove();
		FetchTools.fetchJson( '$server/$STATUS_PATH' ).then( data -> {
			trace(data.icestats);
			this.metadata = data;
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
