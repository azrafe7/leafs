package;

import buddy.BuddySuite;
import buddy.Buddy;
import buddy.SuitesRunner;
import haxe.io.Path;
import sys.FileSystem;
import utest.Assert;
import leafs.FSTree;
import Constants.*;


@reporter("MochaReporter")
class TestAll /*implements Buddy <[
    TestMisc, 
  ]>*/ { 

  
  static public function main():Void {
    
    var reporter = new MochaReporter();
  
    createEmptyDirsIn([ASSETS_DIR, ASSETS_SUBDIR]);
    
    var runner = new SuitesRunner([
      new TestMisc(), 
    ], reporter);
    
    runner.run();
  }
  
  // manually create empty dirs as they're not git versionable without adding a dummy file inside
  static function createEmptyDirsIn(parentDirs:Array<String>):Void {
    for (parent in parentDirs) {
      var emptyDir = Path.join([parent, EMPTY_DIR]);
      if (!FileSystem.exists(emptyDir)) FileSystem.createDirectory(emptyDir);
    }
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
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName == ASSETS_SUBDIR && e.isDir) done();
        }, root);
        fail();
      });

      it('Contains empty dir', function(done) {
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(EMPTY_DIR) >= 0 && e.isDir) done();
        }, root);
        fail();
      });

      it('Doesn\'t contain deep file', function(done) {
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0 && e.isFile) fail("Contains deep file");
        }, root);
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
        
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(EMPTY_DIR) >= 0 && e.isDir) count++;
        }, root);
        
        Assert.isTrue(count == 2);
      });

      it('Contains deep file', function(done) {
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0 && e.isFile) done();
        }, root);
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
        
        FSTree.traverse(function (e:FSTree) {
          Assert.isTrue(e == entries[count]);
          Assert.isTrue(e.fullName == paths[count]);
          count++;
        }, root);
        
        Assert.isTrue(count == entries.length);
        Assert.isTrue(count == paths.length);
        
        for (e in root) {
          count--;
        }
        
        Assert.isTrue(count == 0);
      });
    });
    
    describe('Populate file', {
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
        FSTree.traverse(function (e:FSTree) {
          var lastPart = e.fullName.split(SEP).pop();
          Assert.isTrue(lastPart != "");
        }, root);
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
  }
}
