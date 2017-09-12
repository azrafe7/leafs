package;

import leafs.AutoComplete;
import leafs.FSTree;


class AutoCompleteExample {

  static public function main() {
    trace(AllAssets + "\n");
    trace(AllAssetsAnon + "\n");
  }
}


@:build(leafs.AutoComplete.fromFS("assets", true))
class AllAssets { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true))
class AllAssetsAnon { }

