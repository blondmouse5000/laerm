package laerm;

import js.lib.Uint8Array;

abstract class Spectrum {

    var radio : Radio;

    function new( radio : Radio ) {
        this.radio = radio;
    }

    abstract public function render( timeData : Uint8Array ) : Void;
}