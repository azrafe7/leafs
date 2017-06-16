package leafs;


class Utils {
  
  /** RegEx of invalid id chars (used by toValidId()). */
  static public var INVALID_CHARS_REGEX:EReg = ~/[^a-zA-Z_0-9]/g;
  
  
  /** 
   * Transform `id` into a valid haxe identifier by replacing forbidden characters. 
   * 
   * NOTE: this mainly addresses transforming filenames/paths into valid haxe identifiers
   *       (like haxeFlixel does), but doesn't guarantee to have a valid id back 
   *       (f.e. doesn't take into account reserved words).
   */ 
  public static function toValidHaxeId(id:String):String {
    var startingDigitRegex:EReg = ~/^[0-9]/g;
    var dirSepRegex:EReg = ~/[\/\\]/g;
    var invalidCharsRegex:EReg = INVALID_CHARS_REGEX;
    
    var res = id;
    if (startingDigitRegex.match(res)) res = "_" + res;
    res = dirSepRegex.replace(res, "__");
    res = invalidCharsRegex.replace(res, "_");
    return res;
  }
  
  /** Returns true if `array` contains duplicates, and appends them into `duplicates` (if not null). */
  public static function hasDuplicates(array:Array<String>, ?duplicates:Array<String>):Bool {
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
}