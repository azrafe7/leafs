package leafs;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;


enum FSErrorPolicy {
  QUIET;
  THROW;
  LOG;
  CUSTOM(onError:/*path:*/String->/*error:*/FSError->/*mustThrow:*/Bool);
}

@:enum abstract FSFilter(String) from String to String {
  var ANY = "ANY";
  var DIRS_ONLY = "DIRS_ONLY";
  var FILES_ONLY = "FILES_ONLY";
}

typedef FilterOptions = {
  @:optional var fsFilter:FSFilter;
  @:optional var regexPattern:String;
  @:optional var regexOptions:String;
}

typedef JsonReplacer = /*key:*/Dynamic->/*value:*/Dynamic->/*newValue:*/Dynamic;


class FSTree extends FSEntry {
  
  static public var errorPolicy:FSErrorPolicy = FSErrorPolicy.LOG;
  
  static var parentsCache:Array<FSTree> = [];
  
  
  public var parentId:Int = -1;
  
  /** 
   * Returns the parent dir as an FStree if present in the `parentsCache` (or null otherwise).
   * 
   * See _populate().
   */
  public var parent(get, null):FSTree;
  function get_parent():FSTree {
    return (parentId >= 0 && parentId < parentsCache.length) ? parentsCache[parentId] : null;
  }
  
  public var children:Array<FSTree> = [];
  
  /** 
   * The `path` variable could be relative or absolute, and will be normalized by haxe.Path.normalize().
   * 
   * Note that this might throw an exception if for some reasons it couldn't read from disk.
   * Set the `errorPolicy` beforehand to specify how to handle these cases.
   */
  public function new(path:String) {
    try {
      super(path);
    } catch (e:Dynamic) {
      handleError(path, e);
    }
  }

  public function populate(recurse:Bool = false, sortByDirsFirst:Bool = true):FSTree {
    if (this.isDir) {
      _populate(this, recurse);
      
      if (sortByDirsFirst) this.sort();
    }
    
    return this;
  }
  
  inline public function getEntry(fullName:String):FSTree {
    return findEntry(this, fullName);
  }
  
  /** 
   * Converts the entire FSTree to Json.
   * 
   * See haxe.Json.stringify(). 
   */
  inline public function toJson(?replacer:JsonReplacer, space:String = "  "):String {
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
      var level = Utils.countMatches(fs.fullName, ~/\//);
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
  
  public function toPathArray():Array<String> {
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
  
  static public function findEntry(parentEntry:FSTree, fullName:String):FSTree {
    var foundEntry:FSTree = null;
    
    traverseUntil(parentEntry, function(e:FSTree):Bool {
      if (e.fullName == fullName) {
        foundEntry = e;
        return true; // stop early (no need to test further)
      };
      return false;
    });
    
    return foundEntry;
  }
  
  static public function findEntries(parentEntry:FSTree, fullNamePattern:EReg):Array<FSTree> {
    var entries:Array<FSTree> = [];
    
    traverse(parentEntry, function(e:FSTree):Void {
      if (fullNamePattern.match(e.fullName)) {
        entries.push(e);
      };
    });
    
    return entries;
  }

  static public function getFilteredEntries(rootPath:String, recurse:Bool, ?filterOptions:FilterOptions):Array<FSTree> {
    var entries = new FSTree(rootPath).populate(recurse).toFlatArray();
    
    if (filterOptions == null) filterOptions = { };
    var filterDefaults:FilterOptions = {
      fsFilter: FSFilter.ANY,
      regexPattern: "",
      regexOptions: ""
    };
    Utils.mergeAnons([filterDefaults, filterOptions], false, filterOptions);
    
    var regex = new EReg(filterOptions.regexPattern, filterOptions.regexOptions);

    function include(entry:FSTree):Bool {
      var satisfiesRegex = regex.match(entry.fullName);
      if (!satisfiesRegex) return false;
      
      return switch (filterOptions.fsFilter) {
        case FSFilter.ANY: 
          return satisfiesRegex;
        case FSFilter.DIRS_ONLY: 
          return satisfiesRegex && entry.isDir;
        case FSFilter.FILES_ONLY: 
          return satisfiesRegex && entry.isFile;
        default:
          var errorMessage = 'Invalid `fsFilter` parameter ("${filterOptions.fsFilter}"). Must be compatible with FSFilter enum.';
        #if macro
          haxe.macro.Context.fatalError(errorMessage, haxe.macro.Context.currentPos());
        #else
          throw errorMessage;
        #end
      }
    }
    
    var filteredEntries:Array<FSTree> = entries.filter(include);
    return filteredEntries;
  }
  
  static public function getFilteredPaths(rootPath:String, recurse:Bool, ?filterOptions:FilterOptions):Array<String> {
    var filteredEntries:Array<FSTree> = getFilteredEntries(rootPath, recurse, filterOptions);
    var filteredPaths:Array<String> = [for (e in filteredEntries) e.fullName];
    
    return filteredPaths;
  }
  
  inline static public function clearParentsCache():Void {
    var oldParentsCache = FSTree.parentsCache;
    oldParentsCache = null;
    FSTree.parentsCache = [];
  }
  
  /** 
   * Note: `parentEntry` will be added to `parentsCache` so that it can be easily retrieved
   * by accessing the `parent` property on every child.
   */
  function _populate(parentEntry:FSTree, recurse:Bool):Void {
    var entries = FileSystem.readDirectory(parentEntry.fullName);
    
    var parentId = parentsCache.length;
    FSTree.parentsCache[parentId] = parentEntry;
    
    parentEntry.children = entries.map(function (e) { 
      var tree = new FSTree(Path.join([parentEntry.fullName, e]));
      tree.parentId = parentId;
      return tree;
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
      case CUSTOM(onError): 
        if (onError(path, error)) throw fsError;
      default:
        throw "Unexpected!";
    }
  }  
}


class FSEntry {
  
  public var isDir(default, null):Bool;
  public var isFile(default, null):Bool;
  
  /** Guaranteed to use `/` as path separator, and to not end with a slash/backslash. */
  public var parentPath(default, null):String;
  
  /** Guaranteed to use `/` as path separator, and to not end with a slash/backslash. */
  public var name(default, null):String;
  
  /** Guaranteed to use `/` as path separator, and to not end with a slash/backslash. */
  public var fullName(default, null):String;
  
  public function new(path:String) {
    path = Path.normalize(path);
    name = Path.withoutDirectory(path);
    parentPath = Path.directory(path);
    fullName = Path.join([parentPath, name]);
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