package leafs;

import haxe.Resource;
import haxe.io.Bytes;


/** Represents a named embedded resource, with lazy loading from haxe.Resource when accessed `asString` or `asBytes`. */
class EmbeddedResource {
  
  public var name(default, null):String;
  
  public var asString(get, null):String;
  var _asString:String;
  inline function get_asString():String {
    if (_asString == null) {
      trace("was null");
      _asString = Resource.getString(name);
    }
    return _asString;
  }
  
  public var asBytes(get, null):Bytes;
  var _asBytes:Bytes;
  inline function get_asBytes():Bytes {
    if (_asBytes == null) {
      trace("was null");
      _asBytes = Resource.getBytes(name);
    }
    return _asBytes;
  }
  
  
  public function new(name:String) {
    this.name = name;
  }
}