package leafs;

import leafs.FSTree.FSEntry;
import leafs.FSTree.FSFilter;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end


class AutoComplete {
  
  static public var LOG:Bool = true;
  
  static public var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  
  #if !macro macro #end
  static public function build(ids:Array<String>, ?values:Array<String>, ?varName:String):Array<Field> {
    var fields = Context.getBuildFields();
    return fields.concat(generate(ids, values, varName));
  }
  
  #if !macro macro #end
  static public function fromFS(rootPath:String, recurse:Bool, ?varName:String, ?fsFilter:FSFilter, ?regexFilter:String, ?regexOptions:String):Array<Field> {
    var includedPaths:Array<String> = FSTree.getFilteredPaths(rootPath, recurse, fsFilter, regexFilter, regexOptions);
    
    var fields = Context.getBuildFields();
    return fields.concat(generate(includedPaths, null, varName));
  }
  
  // adapted from HaxeFlixel FlxAssets/FlxAssetPaths
  #if !macro macro #end
  static public function generate(ids:Array<String>, ?values:Array<String>, ?varName):Array<Field> {

    var headerDoc = "AutoComplete-generated:";
    
    if (values == null) values = [].concat(ids);
    else if (values.length != ids.length) {
      Context.fatalError('values.length != ids.length (${ids.length} != ${values.length}).', Context.currentPos());
    }
    
    var validIds = ids.map(toValidId);
    var duplicates = [];
    if (hasDuplicates(validIds, duplicates)) {
      Context.fatalError("Found colliding id names (" + duplicates + ").", Context.currentPos());
    }

    inline function toDocKeyValue(key:String, value:String, indent:String = "  "):String {
      return '<b>' + indent + key + '</b>: <code>"' + value + '"</code> ';
    }
    
    var fields = [];
    if (varName == null) { // create static fields
      for (i in 0...validIds.length) {
        fields.push({
          name: validIds[i],
          doc: '$headerDoc \n' + toDocKeyValue(validIds[i], values[i], ""),
          access: [Access.APublic, Access.AStatic, Access.AInline],
          kind: FieldType.FVar(macro :String, macro $v{values[i]}),
          pos: Context.currentPos()
        });
      }
    } else { // create anon struct
      var objType:ComplexType = TAnonymous([for (i in 0...validIds.length) { 
        name: validIds[i], 
        pos: Context.currentPos(), 
        kind: FVar(macro :String) 
      }]);
      
      var objExpr:Expr = {
        expr: EObjectDecl([
          for (i in 0...validIds.length) {
            field: validIds[i],
            expr: macro $v{values[i]}
          }
        ]),
        pos: Context.currentPos()
      }
      
      var field:Field = {
        name: varName,
        doc: '$headerDoc \n' + [for (i in 0...validIds.length) toDocKeyValue(validIds[i], values[i])].join("\n"),
        access: [Access.AStatic, Access.APublic],
        kind: FieldType.FVar(objType, objExpr),
        pos: Context.currentPos(),
      };
      fields.push(field);
    }
    
    if (LOG) {
      var classPath = Context.getLocalClass().toString();
      var injectedAs = varName == null ? 'static vars in `$classPath`' : 'anon object in `$classPath.$varName`';
      Sys.println("[AutoComplete.generate] " + validIds.length + " entries injected (as " + injectedAs + ")");
      Sys.println([for (i in 0...validIds.length) '  ${validIds[i]}: ${values[i]}'].join("\n"));
    }
    
    return fields;
  }
  
  /** 
   * Transform `id` into a valid haxe identifier by replacing forbidden characters. 
   * 
   * NOTE: this mainly addresses transforming filenames/paths into valid haxe identifiers
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