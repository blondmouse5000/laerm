package laerm;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;

inline var BORDER_WIDTH = 8;

function main() {

    console.info('%c⸸ LAUTER LAERM ⸸', 'background:#fff000;color:#050505;padding:4px;font-size:23px;');

    window.addEventListener( 'load', e -> {

        var mainElement = document.body.querySelector('main');
        
        var radio = new Radio( "https://rrr.disktree.net:8443", "laerm" );
        mainElement.append( radio.canvas );
        radio.fitCanvas( mainElement );
        
        /*
        window.addEventListener( 'resize', e -> {
            ///radio.fitElement( mainElement );
        }, false );
        */
        
    }, false );
}
