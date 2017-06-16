package;

import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;


class Example {
  
  static public function main() {
    
    // set custom policy for error handling
    FSTree.errorPolicy = FSErrorPolicy.CUSTOM(customErrorHandler);
    
    var root = new FSTree("assets"); 
    
    trace("Root entry:");
    Sys.println(root);
    Sys.print("\n");
    
    trace("FullName: " + new Path(root.fullName));
    Sys.print("\n");
    
    root.populate(true); // passing false will do a shallow scan
    
    var prettyJson = root.toJson();
    trace("toJson:");
    Sys.println(prettyJson);
    Sys.print("\n");
    
    trace("toFlatArray:");
    Sys.println(root.toFlatArray().join('\n'));
    Sys.print("\n");
    
    trace("toStringArray:");
    Sys.println(root.toStringArray().join('\n'));
    Sys.print("\n");
    
    trace("Using iterator:");
    for (e in root) {
      if (e.isDir) Sys.println("[" + e.name + "]");
      else Sys.println(e.name);
    }
    Sys.print("\n");
    
    var deepFile = FSTree.findEntries(~/.*deep.file.*/i, root)[0];
    trace('Contents of "${deepFile.fullName}":');
    Sys.println(File.getContent(deepFile.fullName));
    Sys.print("\n");
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