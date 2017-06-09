package leafs;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;


enum FSErrorPolicy {
  Quiet;
  Throw;
  Log;
  Custom(handler:/*path:*/String->/*error:*/FSError->/*halt:*/Bool);
}


class FSTree extends FSEntry {
  
  static public var errorPolicy:FSErrorPolicy = FSErrorPolicy.Log;
  
  public var children:Array<FSTree> = [];
  
  public function new(path:String) {
    try {
      super(path);
    } catch (e:Dynamic) {
      handleError(path, e);
    }
  }

  public function populate(recurse:Bool = false):FSTree {
  
    if (this.isDir) _populate(this, recurse);
    
    return this;
  }
  
  inline public function toJson(?replacer:Dynamic->Dynamic->Dynamic, space:String = "  "):String {
    return Json.stringify(this, replacer, space);
  }
  
  public function toFlatArray():Array<FSTree> {
    var entries = [];
    traverse(entries.push, this);
    return entries;
  }
  
  public function toStringArray():Array<String> {
    var entries = [];
    function pushFullName(e) {
      entries.push(e.fullName);
    }
    traverse(pushFullName, this);
    return entries;
  }
  
  inline public function iterator():Iterator<FSTree> {
    return toFlatArray().iterator();
  }
  
  static public function traverse(fn:FSTree->Void, parentEntry:FSTree):Void {
    fn(parentEntry);
    
    for (e in parentEntry.children) {
      if (e.isDir) traverse(fn, e);
      else fn(e);
    }
  }
  
  function _populate(parentEntry:FSTree, recurse:Bool):Void {
    
    var entries = FileSystem.readDirectory(parentEntry.fullName);
    parentEntry.children = entries.map(function (e) { 
      return new FSTree(Path.join([parentEntry.fullName, e]));
    });
    
    for (e in parentEntry.children) {
      if (e.isDir && recurse) {
        _populate(e, recurse);
      }
    }
  }
  
  inline function handleError(path:String, error:Dynamic):Void {
    var fsError = new FSError(path, error);
    switch (FSTree.errorPolicy) {
      case Quiet:
      case Throw:
        throw fsError;
      case Log:
        trace(fsError.toString());
      case Custom(handler):
        if (handler(path, error)) throw fsError;
      default:
        throw "Unexpected!";
    }
  }  
}


class FSEntry {
  
  public var isDir(default, null):Bool;
  public var isFile(default, null):Bool;
  public var parent(default, null):String;
  public var name(default, null):String;
  public var fullName(default, null):String;
  
  public function new(path:String) {
    path = Path.normalize(path);
    parent = Path.directory(path);
    name = Path.withoutDirectory(path);
    fullName = Path.join([parent, name]);
    isDir = FileSystem.isDirectory(fullName);
    isFile = !isDir;
  }
}


class FSError {
  
  var path:String;
  var error:Dynamic;
  
  public function new(path:String, error:Dynamic) {
    this.path = path;
    this.error = error;
  }
  
  @:keep
  public function toString():String {
    return '[FSError]: Error processing "$path": ' + Std.string(error);
  }
}