package leafs;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end


// adapted from http://code.haxe.org/category/macros/completion-from-url.html
class AutoComplete {
  
  public static var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  macro public static function build(entries:Array<String>, varName:String):Array<Field> {

    var validIds = entries.map(toValidId);
    var duplicates = [];
    if (hasDuplicates(validIds, duplicates)) {
      Context.error("Found colliding id names (" + duplicates + ")", Context.currentPos());
    }

    var fields = Context.getBuildFields();
    var objType:ComplexType = TAnonymous([for (i in 0...entries.length) { 
      name: validIds[i], 
      pos: Context.currentPos(), 
      kind: FVar(macro :String) 
    }]);
    
    var objExpr:Expr = {
      expr: EObjectDecl([
        for (i in 0...entries.length) {
          field: entries[i],
          expr: macro $v{validIds[i]}
        }
      ]),
      pos: Context.currentPos()
    }
    
    var field:Field = {
      name: varName,
      pos: Context.currentPos(),
      kind: FVar(objType),
      access: [AStatic, APublic],
    };
    fields.push(field);
    
    Context.warning("AutoComplete.build: " + validIds.length + " entries processed.", Context.currentPos());
    return fields;
  }
  
  macro static public function fromFS(root:String, recurse:Bool, varName:String, ?filter:FSTree->Bool):Array<Field> {
    var fsRoot = new FSTree(root).populate(recurse);
    var entries = fsRoot.toFlatArray();
    if (filter != null) entries = entries.filter(filter);
    var paths = entries.map(function (e) { return e.fullName; });
    
    return build(paths, varName);
  }
  
  /** 
   * Transform `id` into a valid haxe identifier by replacing forbidden characters. 
   * 
   * NOTE; this mainly addresses transforming filenames/paths into valid haxe identifiers
   *       (like haxeFlixel does), but doesn't guarantee to have a valid id back 
   *       (f.e. doesn't take into account reserved words).
   */ 
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
    
    for (i in 0...sortedCopy.length - 1) {
      if (sortedCopy[i] == sortedCopy[i + 1]) {
        hasDups = true;
        if (duplicates != null) duplicates.push(sortedCopy[i]);
      }
    }
    return hasDups;
  }
}