package leafs;

import haxe.PosInfos;
import leafs.Utils;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
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
}