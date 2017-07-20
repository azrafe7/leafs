import haxe.io.Path;
import leafs.FSTree;
import leafs.Macros;
import leafs.Utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
#end


typedef CustomBuildOptions = { varName:String, dir:String };


class CustomMacros {
  
  #if !macro macro #end
  static public function customBuild(options:CustomBuildOptions):Array<Field> {
    var fields = Context.getBuildFields();
    
    var root = new FSTree(options.dir).populate(true); // scan the dir recursively
    
    var fsAnon = { };
    for (e in root) {
      var dotPath = Utils.toValidDotPath(e.fullName); // convert to dotPath
      
      if (e.isDir) Utils.setAnonField(fsAnon, dotPath, { }); // add `dotPath: { }` if it's a dir
      else Utils.setAnonField(fsAnon, dotPath, e.fullName); // add `dotPath: fullName` if it's a file
    }
    
    var innerAnon = Utils.findAnonField(fsAnon, Utils.toValidDotPath(Path.normalize(options.dir))).value; // extract content of anon referenced by `options.dir`
    var access = [Access.APublic, Access.AStatic]; // desired var access
    var existingField = Macros.findField(fields, options.varName, access); // check if the field is already present
    
    var field:Field = null;
    if (existingField == null) {
      field = Macros.makeVarField(options.varName, innerAnon); // create a var field named `varName`
      Macros.setFieldAccess(field, access); // make it static and public
      fields.push(field); // add it to the other fields
    } else {
      //trace("existing field " + existingField.kind);
      var expr = switch (existingField.kind) { // extract expr from existing field
        case FVar(_, e): e;
        default:
          throw "duplicate field is of invalid type";
      }
      var existingAnon = (expr != null) ? Macros.exprValueAs(expr, macro : { }) : { }; // get its value
      var mergedAnon = Utils.mergeTwoAnons(existingAnon, innerAnon, true); // merge old and new anons
      existingField.kind = FVar(null, macro $v{mergedAnon}); // update existing field
      field = existingField;
    }
    
    field.doc = "Auto-generated from '" + Macros.getCurrentMethodName() + "()'."; // set doc comments
    
    return fields;
  }
}
