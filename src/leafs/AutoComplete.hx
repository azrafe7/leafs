package leafs;

import leafs.FSTree.FSEntry;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

@:enum abstract FSFilter(String) to String {
  var All = "ALL";
  var DirOnly = "DIR_ONLY";
  var FileOnly = "FILES_ONLY";
}

// adapted from http://code.haxe.org/category/macros/completion-from-url.html
class AutoComplete {
  
  static public var LOG:Bool = true;
  
  static public var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  
  macro static public function build(entries:Array<String>, varName:String):Array<Field> {

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
    
    if (LOG) {
      Sys.println("[AutoComplete.build] " + validIds.length + " entries processed");
      for (i in 0...entries.length) {
        Sys.println('  ${validIds[i]}: "${entries[i]}"');
      }
    }
    return fields;
  }
  
  macro static public function fromFS(root:String, recurse:Bool, varName:String, ?fsFilter:String, ?regexFilter:String, ?regexOptions:String):Array<Field> {
    var entries = new FSTree(root).populate(recurse).toFlatArray();
    
    if (fsFilter == null) fsFilter = FSFilter.All;
    if (regexOptions == null) regexOptions = "";
    if (regexFilter == null) regexFilter = ".*";
    
    var regex = new EReg(regexFilter, regexOptions);
    
    function include(entry:FSTree):Bool {
      var satisfiesRegex = regex.match(entry.fullName);
      if (!satisfiesRegex) return false;
      return switch (fsFilter) {
        case FSFilter.All:
          return satisfiesRegex;
        case FSFilter.DirOnly:
          return satisfiesRegex && entry.isDir;
        case FSFilter.FileOnly:
          return satisfiesRegex && entry.isFile;
        default:
          throw ("Invalid fsFilter (must be compatible with FSFilter enum)");// , Context.currentPos());
      }
    }
    
    //var includedEntries:Array<FSTree> = entries.filter(include);
    //var includedPaths:Array<String> = [for (e in includedEntries) e.fullName];
    
    //return includedPaths;
    var fields = build(["qwrqr"], "qwer");
    return fields;
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