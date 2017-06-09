package;

import buddy.BuddySuite;
import buddy.Buddy;
import buddy.SuitesRunner;
import utest.Assert;
import leafs.FSTree;
import Constants.*;


@reporter("MochaReporter")
class TestAll /*implements Buddy <[
    TestMisc, 
  ]>*/ { 

  
  static public function main():Void {
    
    var reporter = new MochaReporter();
  
    var runner = new SuitesRunner([
      new TestMisc(), 
    ], reporter);
    
    runner.run();
  }
}  

class TestMisc extends BuddySuite {
  
  public function new() {
    
    describe('Populate tree', {
    
      it('Shallow', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(false);
        
        var hasSubDir = false;
        
        Assert.isTrue(root.children.length > 0);
        
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0) fail("contains deep file");
          if (e.fullName == ASSETS_SUBDIR) hasSubDir = true;
        }, root);
        
        Assert.isTrue(hasSubDir);
      });

      it('Deep (recurse)', {
        var root = new FSTree(ASSETS_DIR);
        root.populate(true);
        
        var hasSubSubDir = false;
        var hasDeepFile = false;
        
        Assert.isTrue(root.children.length > 0);
        
        FSTree.traverse(function (e:FSTree) {
          if (e.fullName.indexOf(DEEP_FILE) >= 0) hasDeepFile = true;
          if (e.fullName == ASSETS_SUBSUBDIR) hasSubSubDir = true;
        }, root);
        
        Assert.isTrue(hasDeepFile);
        Assert.isTrue(hasSubSubDir);
      });
    });
  }
}
