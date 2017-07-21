package leafs;

import haxe.Resource;
import haxe.io.Bytes;


/** 
 * Represents a named embedded resource, with optional metadata.
 * 
 * It will be lazy loaded using `haxe.Resource.getString/Bytes()` when accessing the `asString` and `asBytes` props,
 * and cached from there on. 
 */
class EmbeddedResource {
  
  public var name(default, null):String;
  
  public var metadata:{} = null;
  public var compressed(default, null):Bool;
  
  var _asString:String;
  public var asString(get, null):String;
  inline function get_asString():String {
    if (_asString == null) {
      if (compressed) _asString = haxe.zip.Uncompress.run(Resource.getBytes(name)).toString();
      else _asString = Resource.getString(name);
    }
    return _asString;
  }
  
  var _asBytes:Bytes;
  public var asBytes(get, null):Bytes;
  inline function get_asBytes():Bytes {
    if (_asBytes == null) {
      if (compressed) _asBytes = haxe.zip.Uncompress.run(Resource.getBytes(name));
      else _asBytes = Resource.getBytes(name);
    }
    return _asBytes;
  }
  
  
  public function new(name:String, ?metadata:{}, compressed = false) {
    this.name = name;
    this.metadata = metadata;
    this.compressed = compressed;
  }
  
  /** Dispose of this resource (just sets `asString` and `asBytes` to null). */
  public function dispose():Void {
    this._asString = null;
    this._asBytes = null;
  }
}