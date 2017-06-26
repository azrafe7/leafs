package;

import buddy.BuddySuite;
import buddy.Buddy;
import buddy.SuitesRunner;
import haxe.io.Path;
import leafs.AutoComplete;
import leafs.Utils;
import sys.FileSystem;
import utest.Assert;
import leafs.FSTree;
import Constants.*;


@reporter("MochaReporter")
class TestAll /*implements Buddy <[
    TestMisc, 
    TestValidIds,
    TestAnonUtils,
  ]>*/ { 

  
  static public function main():Void {
    
    var reporter = new MochaReporter();
  
    createEmptyDirsIn([ASSETS_DIR, ASSETS_SUBDIR]);
    
    var runner = new SuitesRunner([
      new TestMisc(), 
      new TestValidIds(),
      new TestAnonUtils(),
    ], reporter);
    
    runner.run();
  }
  
  // manually create empty dirs, as they're not git versionable without adding a dummy file inside
  static function createEmptyDirsIn(parentDirs:Array<String>):Void {
    for (parent in parentDirs) {
      var emptyDir = Path.join([parent, EMPTY_DIR]);
      if (!FileSystem.exists(emptyDir)) FileSystem.createDirectory(emptyDir);
    }
  }
  
  static public function debugger() {
  #if nodejs
    untyped __js__('debugger');
  #end
  }
}  


class TestMisc extends BuddySuite {
  
  public function new() {
    
    describe('Check empty dirs', {
      it('Should be there', {
        Assert.isTrue(FileSystem.exists(Path.join([ASSETS_DIR, EMPTY_DIR])));
        Assert.isTrue(FileSystem.exists(Path.join([ASSETS_SUBDIR, EMPTY_DIR])));
      });
    });
    
    describe('FSTree constructor', {
      var entry = new FSTree(ASSETS_DIR);
      
      it('Not populated yet', {
        Assert.isTrue(entry.children.length == 0);
      });
    });
    
    describe('Populate tree (shallow)', {
      var root = new FSTree(ASSETS_DIR);
      root.populate(false);
      
      it('Check root properties', {
        Assert.isTrue(root.isDir);
        Assert.isFalse(root.isFile);
        Assert.isTrue(root.children.length > 0);
        Assert.isTrue(root.name == root.fullName);
        Assert.isTrue(root.parent == "");
        Assert.isTrue(root.fullName.split(SEP).pop() != ""); // doesn't end with '/'
        Assert.isTrue(root.parent == ""); // parent is empty (as it's a relative path)
      });
      
      it('Contains subdir', function(done) {
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName == ASSETS_SUBDIR && e.isDir) done();
        });
        fail();
      });

      it('Contains empty dir', function(done) {
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName.indexOf(EMPTY_DIR) >= 0 && e.isDir) done();
        });
        fail();
      });

      it('Doesn\'t contain deep file', function(done) {
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0 && e.isFile) fail("Contains deep file");
        });
        done();
      });
    });
    
    describe('Populate tree (deep)', {
      var root = new FSTree(ASSETS_DIR);
      root.populate(true);
      
      it('Check root properties', {
        Assert.isTrue(root.isDir);
        Assert.isFalse(root.isFile);
        Assert.isTrue(root.children.length > 0);
        Assert.isTrue(root.name == root.fullName);
        Assert.isTrue(root.parent == "");
        Assert.isTrue(root.fullName.split(SEP).pop() != ""); // doesn't end with '/'
      });
      
      it('Contains two empty dirs', {
        var count = 0;
        
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName.indexOf(EMPTY_DIR) >= 0 && e.isDir) count++;
        });
        
        Assert.isTrue(count == 2);
      });

      it('Contains deep file', function(done) {
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0 && e.isFile) done();
        });
        fail();
      });
    });
    
    describe('Traversal, to*Array() and iterator', {
      var root = new FSTree(ASSETS_DIR);
      root.populate(true);
      
      it('Same length and values', {
        var count = 0;
        var paths = root.toStringArray();
        var entries = root.toFlatArray();
        
        FSTree.traverse(root, function (e:FSTree) {
          Assert.isTrue(e == entries[count]);
          Assert.isTrue(e.fullName == paths[count]);
          count++;
        });
        
        Assert.isTrue(count == entries.length);
        Assert.isTrue(count == paths.length);
        
        for (e in root) {
          count--;
        }
        
        Assert.isTrue(count == 0);
      });
    });
    
    describe('Populate file (length == 1)', {
      var root = new FSTree(ASSETS_FILE);
      
      it('Shallow', {
        root.populate(false);
        Assert.isTrue(root.isFile);
        Assert.isTrue(root.children.length == 0);
        Assert.isTrue(root.toFlatArray().length == 1);
        Assert.isTrue(root.toStringArray().length == 1);
      });
      
      it('Deep', {
        root.populate(true);
        Assert.isTrue(root.isFile);
        Assert.isTrue(root.children.length == 0);
        Assert.isTrue(root.toFlatArray().length == 1);
        Assert.isTrue(root.toStringArray().length == 1);
      });
    });
    
    // no entry ends with '/'
    describe('No trailing backslashes', {
      var root = new FSTree(ASSETS_FILE);
      root.populate(true);
      
      it('traverse()', {
        FSTree.traverse(root, function (e:FSTree) {
          var lastPart = e.fullName.split(SEP).pop();
          Assert.isTrue(lastPart != "");
        });
      });
      
      it('to*Array()', {
        var paths = root.toStringArray();
        var entries = root.toFlatArray();
        
        for (i in 0...paths.length) {
          var path = paths[i];
          var entry = entries[i];
          Assert.isTrue(path == entry.fullName);
          Assert.isTrue(path.lastIndexOf(SEP) < path.length - 1);
          Assert.isTrue(entry.fullName.lastIndexOf(SEP) < entry.fullName.length - 1);
          Assert.isTrue(entry.name.lastIndexOf(SEP) < entry.name.length - 1);
          Assert.isTrue(entry.parent.lastIndexOf(SEP) < entry.parent.length - 1);
        }
      });
    });

    describe('Search single entries', {
      it('File', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(false);
        
        var file = root.getEntry(ASSETS_FILE);
        Assert.notNull(file);
        Assert.isTrue(file.isFile);
        
        var deep = root.getEntry(ASSETS_SUBSUBDIR + SEP + DEEP_FILE);
        Assert.isNull(deep);
        
        root.populate(true);
        deep = root.getEntry(ASSETS_SUBSUBDIR + SEP + DEEP_FILE);
        Assert.notNull(deep);
        Assert.isTrue(deep.isFile);
      });
      
      it('Dir', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(false);
        
        var subdir = root.getEntry(ASSETS_SUBDIR);
        Assert.notNull(subdir);
        Assert.isTrue(subdir.isDir);
        
        var subsubdir = root.getEntry(ASSETS_SUBSUBDIR);
        Assert.isNull(subsubdir);
        
        root.populate(true);
        subsubdir = root.getEntry(ASSETS_SUBSUBDIR);
        Assert.notNull(subsubdir);
        Assert.isTrue(subsubdir.isDir);
      });
    });
    
    describe('Search multiple entries with regex', {
      it('Two empty dirs', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(true);
        
        var ereg = ~/.*empty-dir.*/;
        var emptyDirs = FSTree.findEntries(ereg, root);
        Assert.isTrue(emptyDirs.length == 2);
      });
      
      it('Ignore case', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(true);
        
        var ereg = ~/.*caps\.txt.*/i;
        var emptyDirs = FSTree.findEntries(ereg, root);
        Assert.isTrue(emptyDirs.length == 1);
      });
      
      it('Respect case', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(true);
        
        var ereg = ~/.*caps\.txt.*/;
        var emptyDirs = FSTree.findEntries(ereg, root);
        Assert.isTrue(emptyDirs.length == 0);
        
        var ereg = ~/.*CAPS\.txt.*/;
        var emptyDirs = FSTree.findEntries(ereg, root);
        Assert.isTrue(emptyDirs.length == 1);
      });
    });
    
    describe('No duplicates', {
      it('fullName is unique', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(true);
        
        function compareEntries(a:FSEntry, b:FSEntry):Int {
          if (a.name == b.name) {
            //trace('  seems similar (${a.name} == ${b.name})');
            //trace('  but it is not (${a.fullName} != ${b.fullName})');
          }
          return a.fullName == b.fullName ? 0 : 1;
        }
        
        var entries:Array<FSTree> = root.toFlatArray();
        
        var sortedEntries = entries;
        sortedEntries.sort(compareEntries);
        for (i in 0...entries.length - 1) {
          var a = sortedEntries[i];
          var b = sortedEntries[i + 1];
          Assert.isTrue(a.fullName != b.fullName);
        }
      });
    });
    
    describe('Delayed populate()', {
      it('Populate subdir only', function(done) {
        var root = new FSTree(ASSETS_DIR);
        root.populate(false);
        
        Assert.isNull(root.getEntry(OTHER_SUB_DIR));
        
        var subdir = root.getEntry(ASSETS_SUBDIR);
        Assert.notNull(subdir);
        subdir.populate(false);
        
        FSTree.traverse(root, function (e:FSTree) {
          if (e.fullName.indexOf(ASSETS_SUBSUBDIR) >= 0) done();
        });
        fail(ASSETS_SUBSUBDIR + " not found");
      });
    });
  }
}


class TestValidIds extends BuddySuite {

  static public var mockedAssets = [
      ".assets",
      "assets/4.g",
      "a\\fi.t",
      "\\.4",
      "5.txt",
      "name(3)",
      "[azz]",
      "[",
      "4+3",
      "assets\\dir\\5/*5",
      "invalid-minus"
  ];
  
  
  public function new() {
    
    describe('Check transform to valid ids', {
      it('From assets', function (done) {
        var root = new FSTree(ASSETS_DIR).populate(true);
        var entries = root.toStringArray();
        
        var xformed = entries.map(Utils.toValidHaxeId);
        
        Assert.isFalse(Utils.hasDuplicates(xformed));
        
        for (e in xformed) {
          if (Utils.INVALID_CHARS_REGEX.match(e)) fail("duplicate identifier found!");
        }
        done();
      });
      
      it('From mocked strings', function (done) {
        var xformed = mockedAssets.map(Utils.toValidHaxeId);
        
        Assert.isFalse(Utils.hasDuplicates(xformed));
        
        for (e in xformed) {
          if (Utils.INVALID_CHARS_REGEX.match(e)) fail("duplicate identifier found!");
        }
        done();
      });
      
      it('From mocked strings (with dups)', {
        TestAll.debugger();
        var dup = ".4.3";
        var assets = [].concat(mockedAssets);
        assets.push(dup);
        var xformed = assets.map(Utils.toValidHaxeId);
        
        Assert.isTrue(Utils.hasDuplicates(xformed));
        
        var dups = [];
        Utils.hasDuplicates(xformed, dups);
        Assert.isTrue(dups.length == 1);
        Assert.isTrue(dups[0] == "_4_3");
        
        var mapped = [for (e in assets) '"$e" => "${Utils.toValidHaxeId(e)}"'];
        //trace('dups:\n\t  ' + dups.join('\n\t  '));
      });
    });
  }
}


class TestAnonUtils extends BuddySuite {

  static public var anonA = {
    valueA: "must be present",
    root: {
      inner: {
        str: 0,
        must: "be in output only if deep merge",
        arr: ["a"]
      }
    },
    fn: 2
  }
  
  static public var anonB = {
    root: {
      inner: {
        str: "NOW it's a str",
        arr: ["b", "has", "overwritten", "a"]
      }
    },
    fn: function(x) { return x; },
    valueB: "must be present",
    nullField: null,
  }
  
  static public var anonC = { 
    varInC: "c"
  }
  
  
  public function new() {
    
    describe('Set fields with dotPath', {
      it('Force path creation', {
        var obj = { };
        Utils.setAnonField("root", obj, { }, true);
        Assert.isTrue(obj.root != null);
      });
    });
    
    describe('Searching fields with dotPath', {
      it('Existing fields', {
        var result = Utils.findAnonField("root", anonA);
        Assert.notNull(result);
        Assert.same(result.value, anonA.root, true);
        Assert.isTrue(Type.typeof(result.value) == TObject);
        
        result = Utils.findAnonField("root.inner.arr", anonA);
        Assert.notNull(result);
        Assert.same(result.value, anonA.root.inner.arr);

        result = Utils.findAnonField("fn", anonB);
        Assert.notNull(result);
        Assert.same(result.value, anonB.fn);
      });
      
      it('Existing null field', {
        var result = Utils.findAnonField("nullField", anonB);
        Assert.notNull(result);
        Assert.same(result.value, anonB.nullField);
        Assert.isTrue(result.value == null);
      });
      
      it('Non existing fields', {
        var result = Utils.findAnonField("root.deeper", anonA);
        Assert.isNull(result);
        
        result = Utils.findAnonField("fn.inner", anonA);
        Assert.isNull(result);
        
        result = Utils.findAnonField("root.inner.deeper", anonB);
        Assert.isNull(result);
      });
    });
    
    describe('Merge anons', {
      it('Shallow merge', {
        
        var expected = {
          root: {
            inner: {
              str: "NOW it's a str",
              arr: ["b", "has", "overwritten", "a"]
            }
          },
          fn: function(x) { return x; },
          valueB: "must be present",
          nullField: null,
          valueA: "must be present",
          varInC: "c"
        };
        
        var result = Utils.mergeAnons([anonA, anonB], false);
        Assert.same(result, expected, true);
        Assert.isTrue(Utils.findAnonField("root.inner.str", result).value == anonB.root.inner.str);
        Assert.isTrue(Reflect.hasField(result, "root"));
        trace(Type.typeof(result));
        trace(result.root);
      });
      
    });
  }
}