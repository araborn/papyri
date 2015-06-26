xquery version "3.0";

(:~
 :  Daten interpretieren und formatieren 
 :)
module namespace date="http://papyri.uni-koeln.de:8080/papyri/date";


(:~
 : Versucht ein gültiges xs:date/xs:dateTime aus tei-Daten im Papyri-Bestand zu konstruieren
 :  
 : @param $dateString der String im Format "YYYY", "YYYY-MM-DD" oder "YYYY-MM-DDThh:mm:ss" 
 : @return konstruiertes Datum oder leere Sequenz
 :)
declare function date:parse-tei-date($dateString as xs:string?) {
  if ($dateString castable as xs:dateTime) then xs:dateTime($dateString)
  else if ($dateString castable as xs:date) then xs:date($dateString)
  else if ($dateString castable as xs:gYear) then xs:date($dateString || "-01-01")
  else ()
};



(:~
 : Berechne das Jahrhundert aus einem Datum
 :  
 : @param $date Jahreszahl als xs:integer, gültiger xs:date-castable String oder xs:date 
 : @return xs:integer Berechnetes Jahrhundert
 :)

declare function date:get-century($date) as xs:integer {
	let $year := if ($date castable as xs:date) then 
                  year-from-date($date cast as xs:date)
                  else if ($date castable as xs:integer) then
                  $date cast as xs:integer
                else 1

   let $bc := ($year < 0)
   
   let $century := let $cent := $year idiv 100
   				   let $add := if ($bc) then -1
   				   			   else  1
   				   return $cent + $add

   return $century
};

(:~
 : Formatiert einen String für das Jahrhundert eines Datums
 :  
 : @param $date Jahreszahl als xs:integer, gültiger xs:date-castable String oder xs:date 
 : @return xs:string Jahrhundert als formatierter String
 :)

declare function date:format-century($date) as xs:string {
   
   let $century := date:get-century($date)

   return if ($century < 0)
    then let $abs := abs($century) return concat($abs, ". Jhdt. v. Chr")  
    else concat($century, ". Jhdt. n. Chr.")
};
