package;

import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;


class Example {

  static public function customErrorHandler(path:String, error:Dynamic):Bool {
    if (path.indexOf("hiberfil.sys") >= 0) {
      trace("halt");
      return true;
    }
    else {
      trace("Error encountered and skipped " + path);
      return false;
    }
  }
  
  
  static public function main() {
    
    FSTree.errorPolicy = FSErrorPolicy.Custom(customErrorHandler);
    
    var entry = new FSTree("assets/");
    
    trace(entry);
    trace("path: " + new Path(entry.fullName));
    
    entry.populate(true);
    
    entry.children[0].populate(true);
    
    var prettyJson = entry.toJson();
    trace(prettyJson);
    
    trace(entry.toFlatArray().join('\n'));
    trace(entry.toStringArray().join('\n'));
    
    for (e in entry) {
      trace(e.name);
    }
  }
  
}