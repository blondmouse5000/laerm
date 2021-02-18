package laerm;

import js.lib.Uint8Array;
import js.html.CanvasRenderingContext2D;
import laerm.App.BORDER_WIDTH;

class Spectrum2D {
    
    public var colorStroke = "#050505";
	public var colorFill = "#fff000";

	var radio : Radio;
    var graphics : CanvasRenderingContext2D;
    
    public function new( radio : Radio ) {
        this.radio = radio;
        graphics = radio.canvas.getContext("2d");
		graphics.strokeStyle = colorStroke;
		graphics.fillStyle = colorFill;
    }

    public function render( timeData : Uint8Array ) {

        graphics.clearRect( 0, 0, radio.canvas.width, radio.canvas.height );
		
		var v : Float, x : Float, y : Float;
		var hw = radio.canvas.width/2, hh = radio.canvas.height/2;
		
		graphics.fillStyle = colorFill;
		graphics.strokeStyle = colorStroke;

		graphics.lineWidth = Std.int( (radio.volume.volume*10)*100 );
		// var c = Std.int(100-radio.volume.rms*255);
		// graphics.strokeStyle = 'rgba($c,$c,0,1.0)';
		graphics.beginPath();
		for( i in 0...radio.analyser.fftSize ) {
			v = (Math.PI/2)/180*i;
			x = Math.cos(v) * (timeData[i] );
			y = Math.sin(v) * (timeData[i] );
			graphics.lineTo( hw + x, hh + y );
		}
		graphics.stroke(); 
 
		var width = 24;
		var height = 24;
		var ox = BORDER_WIDTH;
		var oy = BORDER_WIDTH;
		//var oy = canvas.height - height - 8;
		graphics.lineWidth = 1;
		graphics.fillRect( ox, oy, width, height );
		graphics.rect( ox, oy, width, height );
		graphics.stroke();
		graphics.beginPath();
		var sliceWidth = width * 1.0 / radio.analyser.frequencyBinCount; //(radio.analyser.fftSize/2);
  		x = 0.0;
		for( i in 0...radio.analyser.fftSize ) {
            v = timeData[i] / 128.0;
			y = v * height / 2;
			if (i == 0) {
				graphics.moveTo( ox+x, oy+y);
			} else {
				graphics.lineTo( ox+x, oy+y);
			}
			x += sliceWidth;
		}
		graphics.moveTo(radio.canvas.width, radio.canvas.height / 2);
		graphics.stroke();
    }


}