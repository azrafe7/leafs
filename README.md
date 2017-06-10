# leafs

:herb: A tiny FileTree implementation wrapping haxe file system API.

## Usage

```haxe
    var root = new FSTree("assets"); 
    
    trace("Root entry:");
    Sys.println(root);
    Sys.print("\n");
    
    trace("FullName: " + new Path(root.fullName));
    Sys.print("\n");
    
    root.populate(true); // passing false will do a shallow scan instead of a deep one
    
    var prettyJson = root.toJson();
    trace("toJson:");
    Sys.println(prettyJson);
    Sys.print("\n");
    
    trace("toFlatArray:");
    Sys.println(root.toFlatArray().join('\n'));
    Sys.print("\n");
    
    trace("toStringArray:");
    Sys.println(root.toStringArray().join('\n'));
    Sys.print("\n");
    
    trace("Using iterator:");
    for (e in root) {
      if (e.isDir) Sys.println("[" + e.name + "]");
      else Sys.println(e.name);
    }
    Sys.print("\n");
    
    var deepFile = FSTree.findEntries(~/.*deep.file.*/i, root)[0];
    trace('Contents of "${deepFile.fullName}":');
    Sys.println(File.getContent(deepFile.fullName));
    Sys.print("\n");
```

## Notes about API and implementation
Paths are relative!

`leafs.FSTree` extends `leafs.FSEntry` and exposes simple properties like:
 - `isFile`: true if references a file
 - `isDir`: true if references a dir
 - `parent`: parent dir (or empty string if none)
 - `name`: last part of the path
 - `fullName`: parent and name combined
 - `children`: array of sub entries

`FSTree` also has a bunch of methods to perform common tasks like:
 - populate the tree in a shallow fashion, or descend recursively into subdirs (`populate()`)
 - traverse the tree (`traverse()`/`traverseUntil()`)
 - convert to Json (`toJson()`)...
 - or to arrays (`toFlatArray()`/`toStringArray()`)
 - retrieve entries (`getEntry()`/`findEntry()`/`fineEntries()`)
 - custom handling of IO errors (`FSErrorPolicy`)
 - iterate through the tree (`iterator()`)

See [testAll.hx](test/testAll.hx) for more info/examples. 

## License
MIT (see [LICENSE](LICENSE) file).