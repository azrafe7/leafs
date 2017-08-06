package;

import haxe.DynamicAccess;
import haxe.Resource;
import haxe.macro.Context;
import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import leafs.Macros;
import leafs.Utils;
import sys.FileSystem;
import sys.io.File;
import leafs.Embedder;

class BasicExample {
  
  static public function main() {
    
    // set custom policy for error handling
    FSTree.errorPolicy = FSErrorPolicy.CUSTOM(customErrorHandler);
    
    var root = new FSTree("assets/subdir"); 
    
    trace("root entry: " + root);
    // root entry: { isDir => true, name => subdir, parentId => -1, fullName => assets/subdir, isFile => false, parentPath => assets, children => [] }
    
    trace("fullName: " + root.fullName); // fullName: assets/subdir
    trace("name: " + root.name); // name: subdir
    trace("absolute path: " + sys.FileSystem.fullPath(root.fullName)); // absolute path: d:\Dev\Haxe\leafs_git\assets\subdir
    
    // populate structure by reading entries from disk
    root.populate(true); // passing false (default) will do a shallow scan instead of a deep one
    trace("immediate children: " + root.children.length); // 3
    
    trace("\n" + root.toDebugString());
    //[subdir]
    //  [empty-dir]
    //  [subsubdir]
    //    deep.file
    //  subfile.zip
    
    // convert to pretty Json string
    var prettyJson = root.toJson();
    trace(prettyJson);
    
    // flatten the tree structure into an array of FSTree
    var flatArray = root.toFlatArray();
    trace("all children: " + (flatArray.length - 1)); // 4
    
    // flatten the tree structure into an array of path strings
    var pathArray = root.toPathArray();
    
    // iterate the tree
    var repr = "";
    for (e in root) {
      if (e.isDir) repr += "\n[" + e.name + "]";
      else repr += "\n" + e.name;
    }
    trace(repr);
    
    // search for entries using a regex
    var deepFile = FSTree.findEntries(root, ~/.*deep\.file\.*/i)[0];
    trace('contents of "${deepFile.fullName}":');
    trace(File.getContent(deepFile.fullName));
    
    // use a filter to retrieve files
    var txtFilter:FSFilterOptions = {
      fsFilter: FSFilter.FILES_ONLY, // files only, skip dirs
      regexPattern: ".*\\.txt", // only with ".txt" extension
      regexOptions: "i" // ignore case
    };
    var txtFiles = FSTree.getFilteredPaths("assets", true, txtFilter);
    trace(txtFiles);
    
    root = new FSTree(root.parentPath).populate(true);
    var anon = { };
    for (e in root) {
      var dotPath = Utils.toValidDotPath(e.fullName);
      if (e.isDir) Utils.setAnonField(anon, dotPath, { });
      else Utils.setAnonField(anon, dotPath, e.fullName);
    }
    trace(Json.stringify(anon, null, "  "));
    trace((anon:Dynamic).assets.subdir);
    trace(Json.stringify((anon:Dynamic).assets.subdir, null, "  "));
    var parsed = Json.parse(Json.stringify((anon:Dynamic).assets.subdir, null, "  "));
    trace(parsed);
    
    var customAssets = CustomAssets.customAssets;
    trace(Json.stringify(customAssets, null, "  "));
    
    trace("\n" + root.toDebugString());
    trace(Json.stringify(root.toAnon(), null, "  "));
    trace(root.toJson());
    
    trace(AutoCompleted.ASSETS__FILE_TXT);
    
    trace(Resource.listNames());
    //trace(Embedded.resources.otherdir.other_sub_dir.CAPS_TXT.asString);
    //trace(Embedded.fileResCompressed);
    //trace(Embedded.fileResUncompressed);
    trace(Embedded.EMBEDDED_RES);
    for (k in Embedded.EMBEDDED_RES.keys()) trace(k);
    trace(AutoCompleted.ASSETS__FILE_TXT);
    trace(Embedded.EMBEDDED_RES[AutoCompleted.ASSETS__FILE_TXT].asString);
    
    trace(Embedded.fileResStringUncompressed.asString == Embedded.fileResStringCompressed.asString);
    //trace(Embedded.fileResStringCompressed.asString);
    //trace(Embedded.fileResStringUncompressed.asString);
  }
  

  static public function customErrorHandler(path:String, error:Dynamic):Bool {
    if (path.indexOf("hiberfil.sys") >= 0) {
      trace("halt");
      return true;
    }
    else {
      trace("Error encountered. Skipping " + path);
      return false;
    }
  }
}


@:build(CustomMacros.customBuild({varName:"customAssets", dir:"assets/subdir/.."}))
@:build(CustomMacros.customBuild({varName:"customAssets", dir:"src"}))
class CustomAssets {
  static public var customAssets = {custom:"added"};
}

@:build(leafs.AutoComplete.fromFS("assets", true, {fsFilter:"FILES_ONLY"}))
class AutoCompleted {
  
}

@:build(leafs.Embedder.embedFromFS("assets/", true, { anonName: "anon", compress:true }, { regexPattern:".*\\.txt", regexOptions:"i" } ))
@:build(leafs.Embedder.embedFromFS("assets/", true, { mapName:"EMBEDDED_RES" }, { regexPattern:".*\\.txt", regexOptions:"i" } ))
@:build(leafs.Embedder.embedFileResource("fileResCompressed", "fileResCompressed", "assets/Bytes.hx", {compressed: true}, true))
@:build(leafs.Embedder.embedFileResource("fileResUncompressed", "fileResUncompressed", "assets/Bytes.hx", {compressed: false}, false))
@:build(leafs.Embedder.embedFileResource("fileResStringCompressed", "fileResStringCompressed", "assets/Bytes.hx", {compressed: true}, true))
@:build(leafs.Embedder.embedFileResource("fileResStringUncompressed", "fileResStringUncompressed", "assets/Bytes.hx", {compressed: false}, false))
class Embedded {
  
}