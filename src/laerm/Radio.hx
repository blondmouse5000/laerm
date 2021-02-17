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

	static var SERVER = "https://rrr.disktree.net:8443";
	static var MOUNT = "laerm";
	static var STATUS_PATH = "server_version-json.xsl";

	public var canvas(default,null) : CanvasElement;
    public var started(default,null) = false;
	public var color = "#050505";
	public var lineWidth = 100;

	var audioElement : AudioElement;
	var ctx : CanvasRenderingContext2D;
	var analyser : AnalyserNode;
	var timeData : Uint8Array;
	//var freqData : Uint8Array;
	var volume : om.audio.VolumeMeter;

    public function new() {

        canvas = cast document.body.querySelector("main>.radio>canvas");
        //canvas = document.createCanvasElement();
		///canvas.classList.add('radio');
		//canvas.width = window.innerWidth;
		//canvas.height = window.innerHeight;
		canvas.style.position = "absolute";
		canvas.style.display = "none";
		//canvas.style.backgroundColor = "green";
        //element.append( canvas );

		// var button = document.createButtonElement();
		// button.textContent = "LAERM";
		// canvas.append( button );

		ctx = canvas.getContext("2d");

		ctx.strokeStyle = color;
		ctx.fillStyle = color;

		// ctx.fillStyle = "#00ff00";
		// ctx.font = '50px serif';
		// ctx.fillText('LAERRRRRRRRRRRM', 50, 90, 140);

		audioElement = document.createAudioElement();
		audioElement.preload = "none";
		audioElement.crossOrigin = "anonymous";
		audioElement.controls = false;
		//audioElement.autoplay = true;

		var sourceElement = document.createSourceElement();
		sourceElement.type = 'application/ogg';
		sourceElement.src = '$SERVER/$MOUNT';
		audioElement.appendChild( sourceElement );

		audioElement.onplaying = function() {

			if( started )
				return;

			canvas.style.display = "block";

			started = true;

			var audio = new AudioContext();
			analyser = audio.createAnalyser();
			//analyser.fftSize = 2048;
			analyser.fftSize = 2048;
			//analyser.smoothingTimeConstant = 0.8;
			//analyser.minDecibels = -140;
			//analyser.maxDecibels = 0;
			analyser.connect( audio.destination );

			//freqData = new Uint8Array( analyser.frequencyBinCount );
			timeData = new Uint8Array( analyser.frequencyBinCount );

			var source = audio.createMediaElementSource( audioElement );
			source.connect( analyser );

			volume = new VolumeMeter( audio );
			source.connect( volume.processor );

			window.requestAnimationFrame( update );

		}

		//audioElement.play();

		refreshMetadata();
    }

	public function refreshMetadata() {
		var infoElement = document.body.querySelector('main>.radio>.info');
		for( c in infoElement.children ) c.remove();
		FetchTools.fetchJson( '$SERVER/$STATUS_PATH' ).then( data -> {
			trace(data.icestats);
			for( source in cast(data.icestats.source,Array<Dynamic>) ) {
				if( source.server_name == "Laerm" ) {
					trace(source.metadata);

					var e = document.createDivElement();
					e.textContent = source.metadata.title;
					infoElement.append( e );
					
					e = document.createDivElement();
					e.textContent = source.metadata.tracknumber+"/"+source.playlist.trackList.length;
					infoElement.append( e );



					break;
				}

			}
		} );
	}

	public function fitElement( ?element : Element ) {
		//if( element == null ) element = canvas.parentElement;
		var r = element.getBoundingClientRect();
		canvas.width = Std.int( r.width );
		canvas.height = Std.int( r.height );
	}

	public function play() {
		audioElement.play();
	}

    function update( time : Float ) {

		window.requestAnimationFrame( update );

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
			//v = i / 180 * Math.PI;
			v = (Math.PI/2)/180*i;
			x = Math.cos(v) * (timeData[i] ) ;
			y = Math.sin(v) * (timeData[i] ) ;
			ctx.lineTo( hw + x, hh + y );
		}
		ctx.stroke();

		/* ctx.beginPath();
		for( i in 0...analyser.frequencyBinCount ) {
			v = i / 180 * Math.PI;
			x = Math.sin(v) * (timeData[i] );
			y = Math.cos(v) * (timeData[i] );
			ctx.lineTo( hw + x, hh + y );
		}
		ctx.stroke(); */
    }
}
