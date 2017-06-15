package leafs.macros;

import haxe.Resource;
import haxe.io.Bytes;
import leafs.FSTree.FSEntry;
import leafs.FSTree.FSFilter;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end


// very similar to AutoComplete
class Embedder {
  
  /** If true a report log will be printed to stdout. */
  static public var LOG:Bool = true;
  
  #if !macro macro #end
  static public function createFields(names:Array<String>, ?varName:String):Array<Field> {

    var headerDoc = "Embedder-generated:";
    
    var validIds = (varName == null) ? names.map(AutoComplete.toValidHaxeId) : names;
    var duplicates = [];
    if (AutoComplete.hasDuplicates(validIds, duplicates)) {
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
          doc: '$headerDoc \n' + toDocKeyValue(validIds[i], names[i], ""),
          access: [Access.APublic, Access.AStatic, Access.AInline],
          kind: FieldType.FVar(macro :EmbeddedResource, macro null),
          pos: Context.currentPos()
        });
      }
    } else { // create Map<String, EmbeddedResource>
      var map:Array<Expr> = [];
      for (name in names) {
        map.push(macro $v{name} => null);
      }
      
      var field:Field = {
        name: varName,
        doc: '$headerDoc \n' + [for (i in 0...validIds.length) toDocKeyValue(validIds[i], "")].join("\n"),
        access: [Access.AStatic, Access.APublic],
        kind: FieldType.FVar(macro :Map<String, EmbeddedResource>, macro $a{map}),
        pos: Context.currentPos(),
      };
      fields.push(field);
    }
    
    if (LOG) {
      var classPath = Context.getLocalClass().toString();
      var injectedAs = varName == null ? 'static vars in `$classPath`' : 'anon object in `$classPath.$varName`';
      Sys.println("[Embedder.generate] " + validIds.length + " entries injected (as " + injectedAs + ")");
      Sys.println([for (i in 0...validIds.length) '  ${validIds[i]}: "${names[i]}"'].join("\n"));
    }
    
    return fields;
  }
}


/** Represents a named embedded resource, with lazy loading from haxe.Resource when accessed `asString` or `asBytes`. */
class EmbeddedResource {
  
  public var name(default, null):String;
  
  public var asString(get, null):String;
  var _asString:String;
  inline function get_asString():String {
    if (_asString == null) {
      trace("was null");
      _asString = Resource.getString(name);
    }
    return _asString;
  }
  
  public var asBytes(get, null):Bytes;
  var _asBytes:Bytes;
  inline function get_asBytes():Bytes {
    if (_asBytes == null) {
      trace("was null");
      _asBytes = Resource.getBytes(name);
    }
    return _asBytes;
  }
  
  
  public function new(name:String) {
    this.name = name;
  }
}