package leafs;

import haxe.Resource;
import haxe.io.Bytes;
import haxe.io.Path;
import leafs.EmbeddedResource;
import leafs.FSTree;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

typedef EmbedOptions = {
  @:optional var compress:Bool;
  @:optional var anonName:String;
  @:optional var mapName:String;
}


class Embedder {
  
  static public var EMBED_DEFAULTS:EmbedOptions = {
    compress: false,
    anonName: null,
    mapName: null
  };
  
  /** If true a report log will be printed to stdout. */
  static public var LOG:Bool = true;
  
  /** See Context.addResource(). */
  #if !macro macro #end
  inline static public function addResource(name:String, data:Bytes):Void {
    Context.addResource(name, data);
  }
  
  #if !macro macro #end
  static function createEmbeddedResourceExpr(name:String, ?metadata:{}, compress = false):Expr {
    return macro new leafs.EmbeddedResource($v{name}, $v{metadata}, $v{compress});
  }
  
  #if !macro macro #end
  static public function addFileResource(resourceName:String, filePath:String, ?metadata:{}, compress = false):Expr {
    var resourceExpr = createEmbeddedResourceExpr(resourceName, metadata, compress);
    var data = sys.io.File.getBytes(filePath);
    
    if (compress) {
      data = haxe.zip.Compress.run(data, 9);
    }
    
    Context.registerModuleDependency(Context.getLocalModule(), filePath);
    addResource(resourceName, data);
    
    return resourceExpr;
  }
  
  #if !macro macro #end
  static public function addStringResource(resourceName:String, data:String, ?metadata:{}, compress = false):Expr {
    var resourceExpr = createEmbeddedResourceExpr(resourceName, metadata, compress);
    var data = Bytes.ofString(data);
    
    if (compress) {
      data = haxe.zip.Compress.run(data, 9);
    }
    
    addResource(resourceName, data);
    
    return resourceExpr;
  }
  
  /** Build macro. */
  #if !macro macro #end
  static public function embedFileResource(fieldName:String, resourceName:String, filePath:String, ?metadata:{}, compress = false):Array<Field> {
    var fields = Context.getBuildFields();
    
    filePath = Path.normalize(filePath);
    var resourceExpr = addFileResource(resourceName, filePath, metadata, compress);
    var field:Field = Macros.makeVarFieldFromExpr(fieldName, resourceExpr);
    Macros.setFieldAccess(field, [Access.AStatic, Access.APublic]);
    field.doc = Macros.autoDocString("resourceName: " + resourceName + "\nfilePath: " + filePath); // set doc comments
    fields.push(field);
    
    return fields;
  }
  
  /** Build macro. */
  #if !macro macro #end
  static public function embedStringResource(fieldName:String, resourceName:String, data:String, ?metadata:{}, compress = false):Array<Field> {
    var fields = Context.getBuildFields();
    
    var resourceExpr = addStringResource(resourceName, data, metadata, compress);
    var field:Field = Macros.makeVarFieldFromExpr(fieldName, resourceExpr);
    Macros.setFieldAccess(field, [Access.AStatic, Access.APublic]);
    field.doc = Macros.autoDocString("resourceName: " + resourceName); // set doc comments
    fields.push(field);
    
    return fields;
  }
  
  /** Build macro. */
  #if !macro macro #end
  static public function embedFromFS(rootPath:String, recurse:Bool = false, ?embedOptions:EmbedOptions, ?filterOptions:FSFilterOptions):Array<Field> {
    var fields = Context.getBuildFields();
    
    if (embedOptions == null) embedOptions = { };
    Utils.mergeAnons([EMBED_DEFAULTS, embedOptions], false, embedOptions);
    //if (embedOptions.anonName == null && embedOptions.mapName == null) {
    //  embedOptions.anonName = "resources";
    //  trace("Using default anon '" + embedOptions.anonName + "'.");
    //}
    
    var access = [Access.AStatic, Access.APublic];
    
    // (since we cannot do `macro $v{new EmbeddedResource}`, we store ENew exprs and use them later)
    // populate the map with exprs of new EmbeddedResources
    var resMap = new Map<String, Expr>();
    for (entry in FSTree.getFilteredEntries(rootPath, recurse, filterOptions)) {
      if (entry.isFile) {
        var metadata = {
          ext: Path.extension(entry.fullName).toLowerCase()
        }
        var expr:Expr = addFileResource(entry.fullName, entry.fullName, metadata, embedOptions.compress); // add as haxe resource and get the expr back
        resMap[entry.fullName] = expr;
      }
    }
    
    var field:Field = null;
    if (embedOptions.anonName != null) { // create anon field
      trace("Embedding into anon '" + embedOptions.anonName + "'.");
      var anon = { };
      var PLACEHOLDER = "_placeholder_";
      for (k in resMap.keys()) {
        var resourceExpr = resMap[k];
        Utils.setAnonField(anon, Utils.toValidDotPath(k), PLACEHOLDER + k, true); // use a PLACEHOLDER that will be replaced with the correct Expr
      }
      
      anon = Utils.findAnonField(anon, Utils.toValidDotPath(Path.normalize(rootPath))).value; // extract content of anon referenced by `rootPath`
      var anonExpr = macro $v{anon};
      
      function replaceWithENewExprs(e:ExprOf<{}>):Expr {
        switch(e.expr) {
          case EConst(CString(s)) if (StringTools.startsWith(s, PLACEHOLDER)):
            return resMap[s.substr(PLACEHOLDER.length)];
          case _:
            return ExprTools.map(e, replaceWithENewExprs);
        }
      }
      
      anonExpr = replaceWithENewExprs(anonExpr);
      //trace(new Printer().printExpr(anonExpr));
      field = Macros.makeVarFieldFromExpr(embedOptions.anonName, anonExpr);
      //trace(anon);
    } else if (embedOptions.mapName != null) { // create map field
      trace("Embedding into map '" + embedOptions.mapName + "'.");
      var exprs:Array<Expr> = [];
      for (k in resMap.keys()) {
        exprs.push(macro $v{k} => ${resMap[k]});
      }
      field = Macros.makeVarFieldFromExpr(embedOptions.mapName, macro $a{exprs});
    } else {
      throw "ERROR: `embedOptions` must specify `anonName` or `mapName`.";
    }
    
    Macros.setFieldAccess(field, access);
    field.doc = Macros.autoDocString("rootPath: " + rootPath); // set doc comments
    fields.push(field);
    
    return fields;
  }
}
