package laerm;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;

typedef Theme = {
    var background : String;
    var f_med : String;
    var b_med : String;
}

inline var BORDER_WIDTH = 8;

var theme(default,null) : Theme;

function main() {

    console.info('%c⸸ LAUTER LAERM ⸸', 'background:#fff000;color:#050505;padding:4px;font-size:23px;');

    window.addEventListener( 'load', e -> {
        
        var style = window.getComputedStyle( document.documentElement );
        theme = {
            background: style.getPropertyValue('--background'),
            f_med: style.getPropertyValue('--f_med'),
            b_med: style.getPropertyValue('--b_med')
        };

        var radio = new Radio( "https://rrr.disktree.net:8443" );
        radio.fetchStatus().then( stats -> {
            //trace(stats);
        });

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