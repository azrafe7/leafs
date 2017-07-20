package leafs;

import haxe.PosInfos;
import leafs.Utils;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end


class Macros {
  
  #if !macro macro #end
  static public function makeVarField<T>(name:String, value:T, asMonomorph:Bool = false):Field {
    var type = asMonomorph ? null : TypeTools.toComplexType(Context.typeof(macro $v{value}));
    var field:Field = {
      name: name,
      kind: FieldType.FVar(type, macro $v{value}),
      pos: Context.currentPos()
    }
    
    return field;
  }
  
  #if !macro macro #end
  static public function setFieldAccess(field:Field, access:Array<Access>):Field {
    field.access = access;
    return field;
  }
  
  #if !macro macro #end
  static public function parseComplexType(type:String):ComplexType {
    var expr = Context.parseInlineString('(_$type)', (macro _).pos);
    
    return switch (expr) {
      case macro (_:$complexType): complexType;
      default: 
        throw '`type` must be a valid type, and start with ":" (ex.: ":Array<String>").';
    }
  }  
  
  #if !macro macro #end
  static public function getCurrentMethodName(?pos:PosInfos):String {
    return pos != null ? pos.className + "." + pos.methodName : null;
  }
  
  /**
   * TODO: Find a better way (my macro-fu is too weak)
   * Returns the value of `expr`. Throws an exception if `expr` and `type` don't unify.
   * 
   * ```
   *   var value = exprValueAs({name:"ego", surname:"surego"}, ComplexTypeTools.toType(macro : {name:String, surname:String});
   *   trace(value.name);
   * ```
   */
  #if !macro macro #end
  static public function exprValueAs(expr:Expr, type:ComplexType, ?pos:PosInfos):Dynamic {
    var actualType = Context.typeof(expr);
    var expectedType = ComplexTypeTools.toType(type);
    var unifies = Context.unify(actualType, expectedType);

    if (!unifies) {
      var error = "ERROR: `expr` and `type` don't unify (called from " + pos.fileName + ":" + pos.lineNumber + ")";
      error += "\n  `expr` was: " + TypeTools.toString(actualType);
      error += "\n  `type` was: " + TypeTools.toString(expectedType);
      throw error;
    }
    
    var value = ExprTools.getValue(expr);
    return value;
  }
  
  #if !macro macro #end
  static public function findField(fields:Array<Field>, name:String, ?access:Array<Access>):Null<Field> {
    var field = null;
    if (access == null) access = [];
    
    for (f in fields) {
      if (f.name == name) {
        var idx = access.length - 1;
        while (idx >= 0 && f.access.indexOf(access[idx]) >= 0) idx--;
        
        if (idx == -1) { // found
          field = f;
          break;
        }
      }
    }
    
    return field;
  }
}