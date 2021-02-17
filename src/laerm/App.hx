package laerm;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;

function main() {

    console.info('%c⸸ LAUTER LAERM ⸸', 'background:#fff000;color:#050505;padding:4px;font-size:23px;');

    window.addEventListener( 'load', e -> {

        final mainElement = document.body.querySelector('main');
    
        var radio = new Radio();
        mainElement.append( radio.canvas );
        radio.fitElement( mainElement );
        
        var intro = mainElement.querySelector(':first-child');
        intro.style.cursor = 'pointer';
        intro.onclick = e -> {
            intro.remove();
            radio.play();
            mainElement.style.cursor = 'default';
        }
    
        window.addEventListener( 'resize', e -> {
            radio.fitElement( mainElement );
        }, false );

    }, false );
}
