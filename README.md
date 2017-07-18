# leafs

:herb: A tiny FileTree implementation wrapping the haxe file system API.

(WIP: will include macros for AutoComplete and Resource Embedding. I'm trying to come up with a simple/intuitive API, so expect it to change a lot initially)


## Usage

```haxe
    var root = new FSTree("assets"); 
    
    trace("Root entry: " + root);
    // Root entry: { isDir => true, name => assets, parentId => -1, fullName => assets, isFile => false, parentPath => , children => [] }
    
    trace("FullName: " + new Path(root.fullName));
    // FullName: assets
    
    // read entries from disk
    root.populate(true); // passing false will do a shallow scan instead of a deep one
    trace(root.children.length); // 5
    
    // convert to pretty Json string
    var prettyJson = root.toJson();
    
    // flatten the tree structure into an array of FSTree
    var flatArray = root.toFlatArray();
    
    // flatten the tree structure into an array of path strings
    var pathArray = root.toPathArray();
    
    // iterate the tree
    for (e in root) {
      if (e.isDir) trace("[" + e.name + "]");
      else trace(e.name);
    }
    
    // search for entries using a regex
    var deepFile = FSTree.findEntries(root, ~/.*deep.file.*/i)[0];
    trace('Contents of "${deepFile.fullName}":');
    trace(File.getContent(deepFile.fullName));

    ...
```

## Notes about API and implementation
Paths are relative!
Read first (with `populate()`), handle them later!

`leafs.FSTree` extends `leafs.FSEntry` and exposes simple properties like:
 - `isFile`: true if references a file
 - `isDir`: true if references a dir
 - `parent`: parent dir (or null)
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