# leafs

:herb: A tiny FileTree implementation wrapping the haxe file system API.

(still **WIP**: will hopefully include macros for AutoComplete and Resource Embedding. I'm trying to come up with a simple/intuitive API, so expect it to change a lot initially)


## Usage

```haxe
    var root = new FSTree("assets/subdir"); 
    
    trace("root entry: " + root);
    // root entry: { isDir => true, name => subdir, parentId => -1, fullName => assets/subdir, isFile => false, parentPath => assets, children => [] }
    
    trace("fullName: " + root.fullName); // fullName: assets/subdir
    trace("name: " + root.name); // name: subdir
    trace("absolute path: " + sys.FileSystem.fullPath(root.fullName)); // absolute path: d:\Dev\Haxe\leafs_git\assets\subdir
    
    // populate structure by reading entries from disk
    root.populate(true); // passing false (default) will do a shallow scan instead of a deep one
    trace("immediate children: " + root.children.length); // 3
    
    trace("\n" + root.toDebugString());
    //[subdir]
    //  [empty-dir]
    //  [subsubdir]
    //    deep.file
    //  subfile.zip
    
    // convert to pretty Json string
    var prettyJson = root.toJson();
    
    // flatten the tree structure into an array of FSTree
    var flatArray = root.toFlatArray();
    trace("all children: " + (flatArray.length - 1)); // 4
    
    // flatten the tree structure into an array of path strings
    var pathArray = root.toPathArray();
    
    // iterate the tree
    var repr = "";
    for (e in root) {
      if (e.isDir) repr += "\n[" + e.name + "]";
      else repr += "\n" + e.name;
    }
    trace(repr);
    
    // search for entries using a regex
    var deepFile = FSTree.findEntries(root, ~/.*deep.file.*/i)[0];
    trace('contents of "${deepFile.fullName}":');
    trace(File.getContent(deepFile.fullName));

    ...
```

## Notes about API and implementation
Paths are relative!
Read first (with `populate()`), handle them later!

`leafs.FSTree` extends `leafs.FSEntry` and exposes simple properties like:
 - `isFile`: true if references a file
 - `isDir`: true if references a dir
 - `parent`: parent dir entry (or null)
 - `parentPath`: parent dir name (or empty string)
 - `name`: last part of the path
 - `fullName`: parentPath and name combined
 - `children`: array of sub entries

`FSTree` also has a bunch of methods to perform common tasks like:
 - populate the tree in a shallow fashion, or descend recursively into subdirs (`populate()`)
 - traverse the tree (`traverse()`/`traverseUntil()`)
 - convert to Json (`toJson()`)...
 - or to arrays (`toFlatArray()`/`toPathArray()`)
 - retrieve entries (`getEntry()`/`findEntry()`/`findEntries()`/`getFilteredEntries()`)
 - custom handling of IO errors (`FSErrorPolicy`)
 - iterate through the tree (`iterator()`)

See [TestAll.hx](test/TestAll.hx) and examples for more info. 

## Tests
All tests _should_ be passing for the `sys` targets (neko/nodejs/cpp/cs/java/python): run `haxe testAll.hxml -<target> <output>`.

Feedback very welcome!

## License
MIT (see [LICENSE](LICENSE) file).