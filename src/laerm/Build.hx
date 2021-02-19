package laerm;

#if macro
import haxe.Json;
import haxe.macro.Expr;
import sys.io.File;
#end

class Build {

    macro public static function getSemver() : ExprOf<String> {
        var pkg = Json.parse( File.getContent( 'package.json' ) );
        return macro $v{pkg.version};
    }
}
