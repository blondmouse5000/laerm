package laerm;

import js.Browser.document;
import js.Browser.window;
import js.html.AudioElement;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.html.InputElement;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.lib.Promise;
import js.lib.Uint8Array;
import om.FetchTools;
import om.audio.VolumeMeter;

class Radio {

    static var SOURCES = ["laerm-live","laerm"];

    public final host : String;

    //public var started(default,null) = false;
    public var sources(default,null) : Array<Dynamic>;
    public var audio(default,null) : AudioElement;
    public var canvas(default,null) : CanvasElement;
    public var volume(default,null) : VolumeMeter;
    public var analyser(default,null) : AnalyserNode;
    public var timeData(default,null) : Uint8Array;
	public var freqData(default,null) : Uint8Array;

    var info : DivElement;
    var animationFrameId : Int;
    var spectrum : Spectrum2D;
    var status : DivElement;
    var volumeControl : InputElement;

    public function new( host : String ) {

        this.host = host;

        var mainElement = document.body.querySelector("main");

        canvas = cast mainElement.querySelector('canvas.spectrum');
        info = cast mainElement.querySelector('.info');
        status = cast mainElement.querySelector('.status');
        volumeControl = cast mainElement.querySelector('input.volume');

        spectrum = new Spectrum2D( this );
        
        fitCanvas();

        mainElement.onmouseenter = e -> {
			if( audio != null && !audio.paused )
				volumeControl.classList.remove('hidden');
		}
		mainElement.onmouseleave = e -> {
			volumeControl.classList.add('hidden');
		}
		canvas.onclick = function(){
            togglePlay();
		}
		info.onclick = function(){
			//info.classList.add('hidden');
			info.textContent = '///';
            togglePlay();
            //playSource();
        }

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

		volumeControl.addEventListener( 'input', e -> {
			audio.volume = Std.parseFloat( volumeControl.value );
		}, false );
        
        window.addEventListener( 'resize', e -> {
            fitCanvas( mainElement );
        }, false );
    }

    public function fetchStatus() : Promise<Dynamic> {
        return FetchTools.fetchJson( '$host/status-json.xsl' ).then( data -> {
            var stats = data.icestats;
            var fetchedSources : Array<Dynamic> = cast stats.source;
            sources = fetchedSources.filter( s -> {
                for( ws in SOURCES ) {
                    if( ws == s.server_name )
                        return true;
                }
                return false;
            });
            return data.icestats;
        });
    }

    public function togglePlay() {
        //trace("togglePlay");
		if( audio == null ) {
            playSource();
			return;
        }
		if( audio.paused ) {
			info.textContent = '///';
			info.style.pointerEvents = "none";
			audio.play();
		} else {
			audio.pause();
		}
	}

    public function playSource( ?source : Dynamic ) {

        if( source == null ) {
            for( s in sources ) {
                for( ws in SOURCES ) {
                    if( ws == s.server_name ) {
                        source = s;
                        break;
                    }
                }
            }
        }

        trace('playSource', source );

        audio = document.createAudioElement();
        audio.preload = "none";
		audio.crossOrigin = "anonymous";
        audio.controls = false;

        audio.onplaying = e -> {

            if( analyser == null ) {
           
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
    
                var media = audioContext.createMediaElementSource( audio );
                media.connect( analyser );
                
                volume = new VolumeMeter( audioContext );
                media.connect( volume.processor );
                
               // status.textContent = '${source.title} / ${source.listeners}|${source.listener_peak} USERS';
            }
            
            canvas.classList.remove('hidden');
            info.classList.add('hidden');
            ///volumeControl.classList.remove('hidden');

            animationFrameId = window.requestAnimationFrame( update );
            //started = true;

            fitCanvas();
        }
        audio.onpause = e -> {
            //trace(e);
            //started = false;
            canvas.classList.add('hidden');
            info.textContent = 'LAERM';
			info.classList.remove('hidden');
			info.style.pointerEvents = null;
            window.cancelAnimationFrame( animationFrameId );
        }

        var sourceElement = document.createSourceElement();
		sourceElement.type = source.server_type;
		sourceElement.src = source.listenurl;
		audio.appendChild( sourceElement );

        audio.play();

        status.textContent = '${source.title} / ${source.listeners}|${source.listener_peak} USERS';
        
        if( source.server_name == "laerm-live" ) {
            spectrum.color_bg = '#ff0000';
            spectrum.color_fg = '#000';
        } else {
            spectrum.color_bg = spectrum.color_fg = null;
        }
    }

    function update( time : Float ) {
        animationFrameId = window.requestAnimationFrame( update );
		fitCanvas();
		analyser.getByteTimeDomainData( timeData );
		analyser.getByteFrequencyData( freqData );
		spectrum.render( timeData );
    }

    function fitCanvas( ?parent : Element ) {
		if( parent == null ) parent = document.body.querySelector("main");
		var r = parent.getBoundingClientRect();
		canvas.width = Std.int( r.width );
		canvas.height = Std.int( r.height+2 ); // Hack to hide bottom border
		///spectrum.renderer.setSize( Std.int( r.width ), Std.int( r.height ) );
	}

}