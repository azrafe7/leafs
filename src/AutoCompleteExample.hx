package;

import leafs.AutoComplete;
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
    
    trace(AssetIds.assets);
    trace(AssetIds.assets.test);
    trace(AssetIds.assets2.test);
  }
}

@:build(leafs.AutoComplete.fromFS("assets", null, null, "FILES_ONLY"))
@:build(leafs.AutoComplete.fromFS("assets", true, "dirs", "DIRS_ONLY"))
@:build(leafs.AutoComplete.build([".ONE", "two\\"], "custom"))
@:build(leafs.AutoComplete.build(["1", "2"], ["1", "2"], "numbers"))
class AssetIds {
  public static var assets = { test: "ASSETS" };
  public static var assets2 = { test: "ASSETS2" };
}