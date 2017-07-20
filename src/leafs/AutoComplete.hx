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
  static public function fromFS(dir:String, recurse:Bool = false, ?filterOptions:FSFilterOptions):Array<Field> {
    var fields = Context.getBuildFields();
    
    if (filterOptions == null) filterOptions = { };
    Utils.mergeAnons([FSTree.FILTER_DEFAULTS, filterOptions], false, filterOptions);
    
    var access = [Access.AStatic, Access.APublic, Access.AInline];
    
    for (path in FSTree.getFilteredPaths(dir, recurse, filterOptions)) {
      var field = Macros.makeVarField(Utils.toValidHaxeId(path).toUpperCase(), path);
      Macros.setFieldAccess(field, access);
      field.doc = '"$path"';
      fields.push(field);
    }
    
    return fields;
  }
}
