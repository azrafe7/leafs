package;

import leafs.AutoComplete;
import leafs.AutoComplete.FSFilter;
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
    
    //var x = AutoComplete.fromFS("assets", true, "all", FSFilter.FileOnly);
    //trace(x.join('\n'));
    //trace(AssetIds.all);
    
    trace(AssetIds);
  }
}

@:build(leafs.AutoComplete.fromFS("assets", null, null, "FILES_ONLY"))
@:build(leafs.AutoComplete.fromFS("assets", true, "dirs", "DIRS_ONLY"))
@:build(leafs.AutoComplete.build([".ONE", "2"], "custom"))
class AssetIds {
}