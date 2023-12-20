import Toybox.Lang;

(:background)
class StringUtil {

    (:background_method)
    static function reformatMarkDown(text) {
        var chars = ["\\", "_", "*", "[", "]", "(", ")", "~", "`", ">", "#", "+", "-", "=", "|", "{", "}", ".", "!"];
        for (var i = 0; i < chars.size(); i++) {
            var char = chars[i];
            text = stringReplace(text, char, "\\" + char);
        }
        return text;
    }

    (:background_method)
    static function stringReplace(str, oldString, newString) {
        var result = null;
        var toProcess = str;
        var index = toProcess.find(oldString);

        if (index != null) {
            result = "";
        }

        while (index != null) {
            var index2 = index + oldString.length();
            result = result + toProcess.substring(0, index) + newString;
            toProcess = toProcess.substring(index2, toProcess.length());

            index = toProcess.find(oldString);
        }

        return result == null ? str : result + toProcess;
    }
}