package leafs;


class Utils {
  
  /** RegEx of invalid id chars (used by toValidId()). */
  static public var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  
  /** 
   * Transforms `id` into a valid haxe identifier by replacing forbidden characters. 
   * 
   * NOTE: this mainly addresses transforming filenames/paths into valid haxe identifiers
   *       (like haxeFlixel does), but doesn't guarantee to have a valid id back 
   *       (f.e. doesn't take into account reserved words).
   */ 
  static public function toValidHaxeId(id:String):String {
    var startingDigitRegex:EReg = ~/^[0-9]/g;
    var dirSepRegex:EReg = ~/[\/\\]/g;
    var invalidCharsRegex:EReg = INVALID_CHARS_REGEX;
    
    var res = id;
    if (startingDigitRegex.match(res)) res = "_" + res;
    res = dirSepRegex.replace(res, "__");
    res = invalidCharsRegex.replace(res, "_");
    return res;
  }
  
  /** Returns true if `array` contains duplicates, and appends them to `duplicates` (if not null). */
  static public function hasDuplicates(array:Array<String>, ?duplicates:Array<String>):Bool {
    if (array.length <= 1) return false;
    
    var hasDups = false;
    var sortedCopy = [].concat(array);
    sortedCopy.sort(function(a, b):Int {
      return a < b ? -1 : (a > b ? 1 : 0); 
    });
    
    for (i in 0...sortedCopy.length - 1) {
      if (sortedCopy[i] == sortedCopy[i + 1]) {
        hasDups = true;
        if (duplicates != null) duplicates.push(sortedCopy[i]);
      }
    }
    return hasDups;
  }
  
//https://try.haxe.org/#1e17F
  /** 
   * Adds a `field` with `value` to `anon` using reflection. 
   * 
   * NOTE: tries to create a path to `field` if it doesn't exist:
   * 
   * ```
   *   var anon = {assets: "assets/"};
   *   addAnonField(anon, "assets.one", 1); // error, as assets was already defined and not an anon
   *   addAnonField(anon, "inner.value", "deep"); // ok, {assets: 1, inner: {value: "deep"}}
   * ```
   */
  static public function addAnonField<T>(anon:Dynamic, field:String, value:T) {
    try {
      var parts = field.split(".");
      var curr = anon;
      var len = parts.length;
      for (i in 0...len) {
        var part = parts[i];
        if (Reflect.hasField(curr, part)) {
          var currField = Reflect.field(curr, part);
          if (Std.is(currField, { })) {
            trace("anon");
          } else {
            trace("different!");
          }
        } else {
          trace("no field");
        }
      }
    } catch (e:Dynamic) {
      throw "Error: " + e;
    }
  }
  
  static public function setAnonField<T>(path:String, anon:{}, value:T, forceCreate:Bool = false) {
    var currField = anon;
    var parts = (path).split(".");
    var fieldName = parts.pop();
    
    for (part in parts) {
      if (!Reflect.hasField(currField, part)) {
        Reflect.setField(currField, part, { });
      }
      currField = Reflect.field(currField, part);
    }
    Reflect.setField(currField, fieldName, value);
  }  
    
  static public function mergeTwoAnons(anonA:{}, anonB:{}, deep:Bool = false, into:{} = null, path:String = ""):{ } {
    if (into == null) into = { };
    if (path != "") path += ".";
    
    // add all fields from anonB (if not already there)
    for (fieldName in Reflect.fields(anonB)) {
      var fieldB = Reflect.field(anonB, fieldName);
      var fieldIntoObj = findAnonField(path + fieldName, into);
      var alreadyAdded = fieldIntoObj != null && fieldIntoObj.value == fieldB;
      
      if (!alreadyAdded) {
        setAnonField(fieldName, into, fieldB);
      }
    }
    
    // add fields from anonA
    for (fieldName in Reflect.fields(anonA)) {
      if (Reflect.hasField(anonB, fieldName)) {
        if (!deep) continue;
        var fieldA = Reflect.field(anonA, fieldName);
        var fieldB = Reflect.field(anonB, fieldName);
        // recurse in case of an inner anon field with the same name on both anons
        if (Type.typeof(fieldA) == TObject && Type.typeof(fieldB) == TObject) {
          mergeTwoAnons(fieldA, fieldB, deep, into, path + fieldName);
        }
      } else {
        setAnonField(fieldName, into, Reflect.field(anonA, fieldName));
      }
    }
    
    return into;
  }
  
  static public function mergeAnons(anons:Array<{}>, deep:Bool = false, into:{} = null): { } {
    
    if (into == null) into = { };
    for (i in 0...anons.length - 1) {
      var anonA = anons[i];
      var anonB = anons[i + 1];
      mergeTwoAnons(anonA, anonB, deep, into);
    }
    
    return into;
  }
  
  static public function findAnonField(dotPath:String, object:{}):Null<{value:Dynamic}> {
    var parts = dotPath.split(".");
    var first = parts.shift();
    var res = null;

    if (Type.typeof(object) != TObject) return null;

    var fields = Reflect.fields(object);
    for (fName in fields) {
      var value = Reflect.field(object, fName);
      if (fName == first) {
        if (parts.length == 0) {
          res = {value:value};
          break;
        } else {
          if (Type.typeof(value) == TObject) {
            return findAnonField(parts.join("."), value);
          }
        }
      }
    }

    return res;
  }  
}