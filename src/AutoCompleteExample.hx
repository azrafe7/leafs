package;

import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;


class AutoCompleteExample {
#if macro
  static public function arr():Array<String> return ["on", ".two"];
#end

static public function main() {
    
    var root = new FSTree("assets").populate(true); 
    
    trace(AssetIds.all);
  }
}

@:build(leafs.AutoComplete.fromFS("assets", true, "all"))
class AssetIds {
}