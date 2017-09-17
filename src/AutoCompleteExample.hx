package;

import leafs.AutoComplete;
import leafs.FSTree;


class AutoCompleteExample {

  static public function main() {
    trace(ShallowLoAssets + "\n");
    trace(AllAssets + "\n");
    trace(AllAssetsAnon + "\n");
    trace(Msg + "\n");
    trace(Other + "\n");
    trace(Multi + "\n");
  }
}


@:build(leafs.AutoComplete.fromFS("assets", false, null, false))
class ShallowLoAssets { }

@:build(leafs.AutoComplete.fromFS("assets", true))
class AllAssets { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true))
class AllAssetsAnon { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]Txt$", regexOptions:"i"}, "messages"))
class Msg { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"ANY", regexPattern:"other", regexOptions:"i"}, "other"))
class Other { }

@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]zip$", regexOptions:"i"}, "zip"))
@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"DIRS_ONLY"}, "dirs"))
@:build(leafs.AutoComplete.fromFSIntoAnon("assets", true, {fsFilter:"FILES_ONLY", regexPattern:"[.]txt$"}, "txt"))
class Multi { }

