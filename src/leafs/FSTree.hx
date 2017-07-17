package leafs;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;


enum FSErrorPolicy {
  QUIET;
  THROW;
  LOG;
  CUSTOM(handler:/*path:*/String->/*error:*/FSError->/*mustStop:*/Bool);
}

@:enum abstract FSFilter(String) from String to String {
  var ANY = "ANY";
  var DIRS_ONLY = "DIRS_ONLY";
  var FILES_ONLY = "FILES_ONLY";
}


class FSTree extends FSEntry {
  
  static public var errorPolicy:FSErrorPolicy = FSErrorPolicy.LOG;
  
  public var children:Array<FSTree> = [];
  
  public function new(path:String) {
    try {
      super(path);
    } catch (e:Dynamic) {
      handleError(path, e);
    }
  }

  inline public function populate(recurse:Bool = false, sortByDirsFirst:Bool = true):FSTree {
    if (this.isDir) {
      _populate(this, recurse);
      if (sortByDirsFirst) this.sort();
    }
    
    return this;
  }
  
  inline public function getEntry(fullName:String):FSTree {
    return findEntry(fullName, this);
  }
  
  /** See haxe.Json.stringify(). */
  inline public function toJson(?replacer:Dynamic->Dynamic->Dynamic, space:String = "  "):String {
    return Json.stringify(this, replacer, space);
  }
  
  inline function _cmpDirsFirst(a:FSTree, b:FSTree):Int {
    if (a.isDir || b.isDir) {
      var aValue = a.isDir ? -1 : 0;
      var bValue = b.isDir ?  1 : 0;
      return aValue + bValue;
    }
    else return 0;
  }
  
  /** Sorts by dirs first, otherwise leaves elements' position unchanged. */
  public function sort():Void {
    this.children.sort(_cmpDirsFirst);
    
    for (c in this.children) {
      if (c.isDir) c.sort();
    }
  }
  
  public function toDebugString():String {
    var buf = new StringBuf();
    var indent = "  ";
    var currIndent = "";
    
    traverse(this, function(fs):Void {
      var level = Utils.countOccurrencies(fs.fullName, ~/\//);
      var str = fs.name;
      if (fs.isDir) str = "[" + str + "]";
      for (i in 0...level) str = indent + str;
      buf.add(str + "\n");
    });
    return buf.toString();
  }
  
  public function toFlatArray():Array<FSTree> {
    var entries = [];
    traverse(this, entries.push);
    return entries;
  }
  
  public function toStringArray():Array<String> {
    var entries = [];
    function pushFullName(e) {
      entries.push(e.fullName);
    }
    traverse(this, pushFullName);
    return entries;
  }
  
  inline public function iterator():Iterator<FSTree> {
    return toFlatArray().iterator();
  }
  
  static public function traverse(parentEntry:FSTree, fn:FSTree->Void):Void {
    fn(parentEntry);
    
    for (e in parentEntry.children) {
      if (e.isDir) traverse(e, fn);
      else fn(e);
    }
  }
  
  static public function traverseUntil(parentEntry:FSTree, mustStop:FSTree->Bool):Void {
    var halt = mustStop(parentEntry);
    
    for (e in parentEntry.children) {
      if (halt) return;
      if (e.isDir) traverseUntil(e, mustStop);
      else halt = mustStop(e);
    }
  }
  
  static public function findEntry(fullName:String, parentEntry:FSTree):FSTree {
    var foundEntry:FSTree = null;
    traverseUntil(parentEntry, function(e:FSTree):Bool {
      //trace(e.fullName);
      if (e.fullName == fullName) {
        foundEntry = e;
        return true;
      };
      return false;
    });
    return foundEntry;
  }
  
  static public function findEntries(fullNamePattern:EReg, parentEntry:FSTree):Array<FSTree> {
    var entries:Array<FSTree> = [];
    traverse(parentEntry, function(e:FSTree):Void {
      if (fullNamePattern.match(e.fullName)) {
        entries.push(e);
      };
    });
    return entries;
  }

  static public function getFilteredEntries(rootPath:String, recurse:Bool, ?fsFilter:FSFilter, ?regexFilter:String, ?regexOptions:String):Array<FSTree> {
    var entries = new FSTree(rootPath).populate(recurse).toFlatArray();
    
    if (fsFilter == null) fsFilter = FSFilter.ANY;
    if (regexOptions == null) regexOptions = "";
    if (regexFilter == null) regexFilter = ".*";
    
    var regex = new EReg(regexFilter, regexOptions);

    function include(entry:FSTree):Bool {
      var satisfiesRegex = regex.match(entry.fullName);
      if (!satisfiesRegex) return false;
      return switch (fsFilter) {
        case FSFilter.ANY:
          return satisfiesRegex;
        case FSFilter.DIRS_ONLY:
          return satisfiesRegex && entry.isDir;
        case FSFilter.FILES_ONLY:
          return satisfiesRegex && entry.isFile;
        default:
          var errorMessage = 'Invalid `fsFilter` parameter ("$fsFilter"). Must be compatible with FSFilter enum.';
        #if macro
          haxe.macro.Context.fatalError(errorMessage, haxe.macro.Context.currentPos());
        #else
          throw errorMessage;
        #end
      }
    }
    
    var includedEntries:Array<FSTree> = entries.filter(include);
    
    return includedEntries;
  }
  
  static public function getFilteredPaths(rootPath:String, recurse:Bool, ?fsFilter:FSFilter, ?regexFilter:String, ?regexOptions:String):Array<String> {
    var includedEntries:Array<FSTree> = getFilteredEntries(rootPath, recurse, fsFilter, regexFilter, regexOptions);
    var includedPaths:Array<String> = [for (e in includedEntries) e.fullName];
    
    return includedPaths;
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
      case QUIET:
      case THROW:
        throw fsError;
      case LOG:
        trace(fsError.toString());
      case CUSTOM(handler):
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
  /** Guaranteed to not end with a slash/backslash. */
  public var name(default, null):String;
  /** Guaranteed to not end with a slash/backslash. */
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