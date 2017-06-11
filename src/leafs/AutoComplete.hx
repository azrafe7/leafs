package leafs;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end


// adapted from http://code.haxe.org/category/macros/completion-from-url.html
class AutoComplete {
  
  public static var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  macro public static function build(root:String, recurse:Bool, varName:String):Array<Field> {
    var root = new FSTree(root).populate(recurse);

    var entries = root.toStringArray();

    var validIds = entries.map(toValidId);
    var duplicates = [];
    if (hasDuplicates(validIds, duplicates)) {
      Context.error("Found colliding id names (" + duplicates + ")");
    }

    var fields = Context.getBuildFields();
    var gtype = TAnonymous([for (i in 0...entries.length) { 
      name: validIds[i], 
      pos: Context.currentPos(), 
      kind: FVar(macro:String, entries[i]) 
    }]);
    
    var gids:Field = {
      name: varName,
      pos: Context.currentPos(),
      kind: FVar(gtype),
      access: [AStatic],
    };
    fields.push(gids);
    
    return fields;
  }
  
  /** Transform `id` into a valid haxe identifier by replacing forbidden characters. */ 
  public static function toValidId(id:String):String {
    var startingDigitRegex:EReg = ~/^[0-9]/g;
    var dirSepRegex:EReg = ~/[\/\\]/g;
    var invalidCharsRegex:EReg = INVALID_CHARS_REGEX;
    
    var res = id;
    if (startingDigitRegex.match(res)) res = "_" + res;
    res = dirSepRegex.replace(res, "__");
    res = invalidCharsRegex.replace(res, "_");
    return res;
  }
  
  public static function hasDuplicates(array:Array<String>, ?duplicates:Array<String>):Bool {
    if (array.length <= 1) return false;
    
    var hasDups = false;
    var sortedCopy = [].concat(array);
    sortedCopy.sort(function(a, b):Int {
      return a < b ? -1 : (a > b ? 1 : 0); 
    });
    
    for (i in 0...array.length - 1) {
      if (array[i] == array[i + 1]) {
        hasDups = true;
        if (duplicates != null) duplicates.push(array[i]);
      }
    }
    return hasDups;
  }
}