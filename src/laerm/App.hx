package laerm;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;

inline var BORDER_WIDTH = 8;

function main() {

    console.info('%c⸸ LAUTER LAERM ⸸', 'background:#fff000;color:#050505;padding:4px;font-size:23px;');

    window.addEventListener( 'load', e -> {

        var radio = new Radio( "https://rrr.disktree.net:8443", "laerm", "server_version-json.xsl" );
       
        var body = document.body;
        var headerElement = body.querySelector('header');
        var mainElement = body.querySelector('main');
        var footerElement = body.querySelector('footer');
        
        var semver = document.createDivElement();
        semver.id = "semver";
        semver.classList.add( 'meta' );
        semver.textContent = 'v'+Build.getSemver();
        headerElement.append( semver );

        headerElement.onclick = function(){
            radio.togglePlay();
        }
        
    }, false );
}