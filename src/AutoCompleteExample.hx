package;

import leafs.AutoComplete;
import leafs.FSTree;


class AutoCompleteExample {

  static public function main() {
    trace(AllAssets + "\n");
    trace(AllAssetsAnon + "\n");
    trace(Msg + "\n");
    trace(Other + "\n");
    trace(Multi + "\n");
  }
}


@:build(leafs.AutoComplete.fromFS("assets", true))
class AllAssets { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true))
class AllAssetsAnon { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]txt$", regexOptions:"gi"}, "messages"))
class Msg { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"ANY", regexPattern:"other", regexOptions:"gi"}, "other"))
class Other { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]zip$", regexOptions:"gi"}, "zip"))
@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"DIRS_ONLY"}, "dirs"))
@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]txt$", regexOptions:"gi"}, "txt"))
class Multi { }

