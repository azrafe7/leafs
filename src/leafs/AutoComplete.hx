package leafs;

import leafs.FSTree.FSEntry;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

@:enum abstract FSFilter(String) from String to String {
  var Any = "ANY";
  var DirsOnly = "DIRS_ONLY";
  var FilesOnly = "FILES_ONLY";
}

class AutoComplete {
  
  static public var LOG:Bool = true;
  
  static public var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  
  #if !macro macro #end
  static public function build(ids:Array<String>, ?values:Array<String>, ?varName:String):Array<Field> {
    var fields = Context.getBuildFields();
    return fields.concat(generate(ids, values, varName));
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

    var fields = [];
    var keyValuePairs = [for (i in 0...validIds.length) '  ${validIds[i]}: "${values[i]}"'];
    
    if (varName == null) { // create static fields
      for (i in 0...validIds.length) {
        fields.push({
          name: validIds[i],
          doc: '$headerDoc "<code>${values[i]}</code>".',
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
        doc: '$headerDoc \n<pre>${keyValuePairs.map(function(s) return "<code>" + s + "</code>").join("\n")}</pre>',
        access: [Access.AStatic, Access.APublic],
        kind: FieldType.FVar(objType, objExpr),
        pos: Context.currentPos(),
      };
      fields.push(field);
    }
    
    if (LOG) {
      var injectedAs = varName == null ? 'static vars' : 'anon object `$varName`';
      Sys.println("[AutoComplete.generate] " + validIds.length + " entries injected (as " + injectedAs + ")");
      Sys.println(keyValuePairs.join("\n"));
    }
    
    return fields;
  }
  
  #if !macro macro #end
  static public function fromFS(root:String, recurse:Bool, ?varName:String, ?fsFilter:FSFilter, ?regexFilter:String, ?regexOptions:String):Array<Field> {
    var entries = new FSTree(root).populate(recurse).toFlatArray();
    
    if (fsFilter == null) fsFilter = FSFilter.Any;
    if (regexOptions == null) regexOptions = "";
    if (regexFilter == null) regexFilter = ".*";
    
    var regex = new EReg(regexFilter, regexOptions);
    
    function include(entry:FSTree):Bool {
      var satisfiesRegex = regex.match(entry.fullName);
      if (!satisfiesRegex) return false;
      return switch (fsFilter) {
        case FSFilter.Any:
          return satisfiesRegex;
        case FSFilter.DirsOnly:
          return satisfiesRegex && entry.isDir;
        case FSFilter.FilesOnly:
          return satisfiesRegex && entry.isFile;
        default:
          Context.fatalError('Invalid `fsFilter` parameter ("$fsFilter"). Must be compatible with AutoComplete.FSFilter enum.', Context.currentPos());
      }
    }
    
    var includedEntries:Array<FSTree> = entries.filter(include);
    var includedPaths:Array<String> = [for (e in includedEntries) e.fullName];
    
    var fields = Context.getBuildFields();
    return fields.concat(generate(includedPaths, null, varName));
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