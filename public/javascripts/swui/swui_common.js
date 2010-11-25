/*
      * Author::    Andreia Luna (mailto: amluna@inf.puc-rio.br)
      * ---
      * WUI-Runtime-JS Library
      * Common functions.
      * ---
*/

// Returns a piece of a string, based on a delimiter
function swui_piece(string, sep, start, end) {
   var result = ""
   if (string != "") {
      var vector = string.split(sep);
      //if (vector.length == 1)
      // returns the number of pieces
      if (start == undefined && end == undefined) {
         result = vector.length;  
      } else {
         // returns the selected piece
         vector = (end == undefined) ? vector.slice(start) : vector.slice(start, end);
         var result = vector.join(sep);
      }
   }
   return result;
}

function swui_writeLog(msg) {
   try {
      console.log(msg);
   } catch (error) {
   }
}

