package;

import leafs.AutoComplete;
import leafs.Embedder;
import leafs.FSTree;
import haxe.Json;
import haxe.format.JsonPrinter;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;


class AutoCompleteExample {

  static public function main() {
    
    var root = new FSTree("assets").populate(true); 
    
    //var x = AutoComplete.fromFS("assets", true, "all", FSFilter.FileOnly);
    //trace(x.join('\n'));
    //trace(AssetIds.all);
    
    //trace(AssetIds.assets);
    //trace(AssetIds.assets.test);
    //trace(AssetIds.assets2.test);
    //trace(AssetIds.dirs);
    
    /*for (k in Res.map.keys()) {
      trace(k + " : " + Res.map[k]);
    };*/
    
    //trace(Res.one__.asString);
    trace(Res.all[Res.assets__subdir__subsubdir__deep_file].asString);
    trace(Res.all[Res.assets__subdir__subsubdir__deep_file].asString);
  }
}

//@:build(leafs.macros.AutoComplete.fromFS("assets", null, null, "FILES_ONLY"))
//@:build(leafs.macros.AutoComplete.fromFS("assets", true, "dirs", "DIRS_ONLY"))
//@:build(leafs.macros.AutoComplete.build([".ONE", "two\\"], "custom"))
//@:build(leafs.macros.AutoComplete.build(["1", "2"], ["1", "2"], "numbers"))
class AssetIds {
  public static var assets = { test: "ASSETS" };
  public static var assets2 = { test: "ASSETS2" };
}

@:build(leafs.AutoComplete.fromFS("assets", true))
@:build(leafs.Embedder.embedFromFS("assets", true, "all"))
class Res {
  
}