package leafs;

import leafs.FSTree;
import leafs.Utils;

#if macro
import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end


class AutoComplete {

  /**
   * Build macro that creates inline static vars having their respective path as value.
   * 
   * They will be available in the IDE for autocomplete, and stripped from the actual output (replaced by inline strings).
   */
  #if !macro macro #end
  static public function fromFS(rootPath:String, recursive:Bool = false, ?filterOptions:FSFilterOptions, toUpperCase:Bool = true):Array<Field> {
    var fields = Context.getBuildFields();
    
    if (filterOptions == null) filterOptions = { };
    Utils.mergeAnons([FSTree.FILTER_DEFAULTS, filterOptions], false, filterOptions);
    
    var access = [Access.AStatic, Access.APublic, Access.AInline];
    
    for (path in FSTree.getFilteredPaths(rootPath, recursive, filterOptions)) {
      var fieldName = Utils.toValidHaxeId(path);
      if (toUpperCase) fieldName = fieldName.toUpperCase();
      var field = Macros.makeVarField(fieldName, path);
      Macros.setFieldAccess(field, access);
      field.doc = '"$path"';
      fields.push(field);
    }
    
    return fields;
  }

  /**
   * Build macro that creates an anon var replicating the fs tree structure.
   * 
   * If `anonName` is not specified the var name will be inferred from the last part of rootPath.
   */
  #if !macro macro #end
  static public function fromFSIntoAnon(rootPath:String, recursive:Bool = false, ?filterOptions:FSFilterOptions, ?anonName:String):Array<Field> {
    var fields = Context.getBuildFields();
    
    if (filterOptions == null) filterOptions = { };
    Utils.mergeAnons([FSTree.FILTER_DEFAULTS, filterOptions], false, filterOptions);
    
    var entries = FSTree.getFilteredEntries(rootPath, recursive, filterOptions);
    var root = new FSTree(rootPath).populate(false);
    if (anonName == null) anonName = haxe.io.Path.normalize(rootPath).split("/").pop();
    var fsAnon = { };
    
    for (e in entries) {
      var fullName = e.fullName;
      
      // skip root?
      if (root.isDir && filterOptions.skipRoot && StringTools.startsWith(fullName, root.fullName)) {
        fullName = fullName.substring(root.fullName.length + 1);
      }
      var dotPath = Utils.toValidDotPath(fullName); // convert to dotPath
      
      if (e.isDir) Utils.setAnonField(fsAnon, dotPath, { }); // add `dotPath: { }` if it's a dir
      else Utils.setAnonField(fsAnon, dotPath, fullName); // add `dotPath: fullName` if it's a file
    }
    
    var access = [Access.AStatic, Access.APublic];
    var field = Macros.makeVarFieldFromExpr(anonName, macro $v{fsAnon});
    Macros.setFieldAccess(field, access);
    field.doc = '"$rootPath"';
    fields.push(field);
    
    return fields;
  }
}
