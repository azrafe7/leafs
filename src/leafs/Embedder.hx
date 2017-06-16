package leafs;

import haxe.Resource;
import haxe.io.Bytes;
import leafs.FSTree.FSEntry;
import leafs.FSTree.FSFilter;
import sys.FileSystem;
import sys.io.File;

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
  static public function embedFromFS(rootPath:String, recurse:Bool, ?varName:String, ?regexFilter:String, ?regexOptions:String):Array<Field> {
    var includedPaths:Array<String> = FSTree.getFilteredPaths(rootPath, recurse, FSFilter.FILES_ONLY, regexFilter, regexOptions);
    
    var headerDoc = "Embedder-generated:";
    
    var validIds = (varName == null) ? includedPaths.map(Utils.toValidHaxeId) : includedPaths;
    var duplicates = [];
    if (Utils.hasDuplicates(validIds, duplicates)) {
      Context.fatalError("Found colliding id names (" + duplicates + ").", Context.currentPos());
    }

    inline function toDocKeyValue(key:String, value:String, indent:String = "  "):String {
      return '<b>' + indent + key + '</b>: <code>"' + value + '"</code> ';
    }
    
    var resources:Array<EmbeddedResource> = [];
    for (p in includedPaths) {
      resources.push(new EmbeddedResource(p));
      Context.addResource(p, File.getBytes(p));
    }
    
    var fields = [];
    if (varName == null) { // create static fields
      for (i in 0...validIds.length) {
        fields.push({
          name: validIds[i],
          doc: '$headerDoc \n' + toDocKeyValue(validIds[i], "EmbeddedResource from '" + includedPaths[i] + "'", ""),
          access: [Access.APublic, Access.AStatic],
          kind: FieldType.FVar(macro :EmbeddedResource, macro new EmbeddedResource($v{includedPaths[i]})),
          pos: Context.currentPos()
        });
      }
    } else { // create Map<String, EmbeddedResource>
      var map:Array<Expr> = [];
      for (i in 0...includedPaths.length) {
        map.push(macro $v{includedPaths[i]} => new EmbeddedResource($v{includedPaths[i]}));
      }
      
      var field:Field = {
        name: varName,
        doc: '$headerDoc \n' + [for (i in 0...validIds.length) '<b>  "${validIds[i]}"</b>: EmbeddedResource'].join("\n"),
        access: [Access.AStatic, Access.APublic],
        kind: FieldType.FVar(macro :Map<String, EmbeddedResource>, macro $a{map}),
        pos: Context.currentPos(),
      };
      fields.push(field);
    }
    
    if (LOG) {
      var classPath = Context.getLocalClass().toString();
      var injectedAs = varName == null ? 'static vars in `$classPath`' : 'map in `$classPath.$varName`';
      Sys.println("[Embedder.generate] " + validIds.length + " entries injected (as " + injectedAs + ")");
      Sys.println([for (i in 0...validIds.length) '  ${validIds[i]}: "${includedPaths[i]}"'].join("\n"));
    }
    
    return Context.getBuildFields().concat(fields);
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