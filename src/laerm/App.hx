package laerm;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;

inline var BORDER_WIDTH = 8;

function main() {

    console.info('%c⸸ LAUTER LAERM ⸸', 'background:#fff000;color:#050505;padding:4px;font-size:23px;');

    window.addEventListener( 'load', e -> {

        var radio = new Radio( "https://rrr.disktree.net:8443", "laerm", "server_version-json.xsl" );
       
        var headerElement = document.body.querySelector('header');
        var mainElement = document.body.querySelector('main');
        
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