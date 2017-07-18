package;

import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;


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
    
    // convert to pretty Json string
    var prettyJson = root.toJson();
    
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
    
    trace("\n" + root.toDebugString());
    
    // search for entries using a regex
    var deepFile = FSTree.findEntries(root, ~/.*deep.file.*/i)[0];
    trace('contents of "${deepFile.fullName}":');
    trace(File.getContent(deepFile.fullName));
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