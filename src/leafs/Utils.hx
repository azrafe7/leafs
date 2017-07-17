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
   * 
   * For example transforms something like "assets/sub.dir/image.png" into "assets__sub_dir__image_png".
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
  
  /** Transforms something like "assets/sub.dir/image.png" into "assets.sub_dir.image_png". */
  inline static public function toValidDotPath(filePath:String):String {
    return filePath.split("/").map(Utils.toValidHaxeId).join(".");
  }
  
  /** 
   * Returns true if `array` contains duplicates.
   * If `duplicate` is specified they will be appended to it. 
   */
  static public function hasDuplicates<T>(array:Array<String>, ?duplicates:Array<String>):Bool {
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
  
  /** 
   * Sets the field indentified by `dotPath` on `anon` to `value`.
   * If `forceCreate` is true, it will create all the fields needed to reach `dotPath`.
   * 
   * ```
   *   var anon = {assets: "path/to/res/"};
   *   setAnonField(anon, "assets.one", 1); // error, the `assets` field was already defined and not an anon
   *   setAnonField(anon, "inner.value", "deep"); // error, the `inner` field doesn't exist
   *   setAnonField(anon, "inner.value", "deep", true); // ok, {assets: 1, inner: {value: "deep"}}, the `inner` field will be created
   * ```
   */
  static public function setAnonField<T>(anon:{}, dotPath:String, value:T, forceCreate:Bool = false) {
    var currField = anon;
    var parts = dotPath.split(".");
    var fieldName = parts.pop();
    
    for (part in parts) {
      if (!Reflect.hasField(currField, part)) {
        Reflect.setField(currField, part, { });
      }
      currField = Reflect.field(currField, part);
    }
    Reflect.setField(currField, fieldName, value);
  }  
    
  /**
   * Same as `mergeAnons`, but only for two anons.
   * The optional `atDotPath` identifies where into the resulting object the fields will be merged.
   */
  static public function mergeTwoAnons(anonA:{}, anonB:{}, deep:Bool = false, into:{} = null, atDotPath:String = ""):{ } {
    if (into == null) into = { };
    if (atDotPath != "") atDotPath += ".";
    
    // add all fields from anonB (if not already there)
    for (fieldName in Reflect.fields(anonB)) {
      var fieldB = Reflect.field(anonB, fieldName);
      var fieldIntoObj = findAnonField(atDotPath + fieldName, into);
      var alreadyAdded = fieldIntoObj != null && fieldIntoObj.value == fieldB;
      
      if (!alreadyAdded) {
        setAnonField(into, fieldName, fieldB);
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
          mergeTwoAnons(fieldA, fieldB, deep, into, atDotPath + fieldName);
        }
      } else {
        setAnonField(into, fieldName, Reflect.field(anonA, fieldName));
      }
    }
    
    return into;
  }

  /** 
   * Merges an array of anons (similar to jquery's extend(): fields in anons later in the array will win).
   * 
   * If `deep` is true a deep/recursive merge will be performed.
   * The resulting anon will be placed into `into` if specified.
   */
  static public function mergeAnons(anons:Array<{}>, deep:Bool = false, into:{} = null): { } {
    
    if (into == null) into = { };
    for (i in 0...anons.length - 1) {
      var anonA = anons[i];
      var anonB = anons[i + 1];
      mergeTwoAnons(anonA, anonB, deep, into);
    }
    
    return into;
  }
  
  /** 
   * Searches for a field identified by `dotPath` in `object`. Returns null if it can't find it.
   * 
   * Note: remember to unwrap the value in case of a successful search.
   */
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
  
  /** Applies `regex` to `str` and returns the number of matches. */
  static public function countOccurrencies(str:String, regex:EReg):Int {
    var count = 0;
    while (regex.match(str)) {
      count++;
      str = regex.matchedRight();
    }
    return count;
  }
}