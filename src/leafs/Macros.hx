package leafs;

import haxe.PosInfos;
import leafs.FSTree.FSEntry;
import leafs.FSTree.FSFilter;
import leafs.Utils;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Context;
import haxe.macro.Expr;
#end


class Macros {
  
  #if !macro macro #end
  static public function makeVarField<T>(name:String, value:T):Field {
    var field:Field = {
      name: name,
      kind: FieldType.FVar(null, macro $v{value}),
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