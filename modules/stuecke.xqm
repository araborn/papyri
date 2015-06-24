xquery version "3.0";

module namespace stuecke="http://papyri.uni-koeln.de:8080/papyri/stuecke";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function stuecke:slides-sammlung($node as node(), $model as map(*)){
    for $st in (collection("/db/apps/papyri/data/stuecke")//tei:TEI)[(.//tei:idno)[1] = ("O. 0397", "T. 032", "00055", "03288", "03852", "05512", "10212", "21351", "00904 + P.Rob. inv. 38", "00906; P.Duke Inv. 769", "21351_21376")]
    let $anzahlTexte := count($st//tei:msItemStruct)
    return
    <div class="bg">
        <div class="wrap">
            <div class="md">
                <span class="label">Inventarnummer:</span>
                <span class="value">{stuecke:get-invno($st)}</span>
                <span class="label">Datierung:</span>
                <span class="value">{stuecke:get-dates($st)}</span>
                <span class="label">Herkunft:</span>
                <span class="value">{stuecke:get-origplaces($st)}</span>
                <span class="label">Material:</span>
                <span class="value">{stuecke:get-materials($st)}</span>
                <span class="label">Text{if ($anzahlTexte gt 1) then "e" else ()}:</span>
                <span class="value">{stuecke:get-text-titles($st)}</span>
            </div>
            <div class="img">
                {if (stuecke:get-preferred-image($st) != "")
                 then <img src="{stuecke:get-preferred-image($st)}" alt="{stuecke:get-invno($st)}" />
                else "ohne Bild"}
            </div>
        </div>
    </div>
};

declare function stuecke:slides-texte($node as node(), $model as map(*)){
    for $text in collection("/db/apps/papyri/data/stuecke")//tei:msItemStruct[ancestor::tei:msDesc//tei:idno = ("00574", "06203", "05803", "01650", "07951", "20351", "20986a", "00651 Recto", "07614 Recto", "O. 0404")]
    return
    <div class="bg">
        <div class="wrap">
            <div class="md">
                <span class="label">Titel:</span>
                <span class="value">{$text/tei:title/data(.)}</span>
                <span class="label">Publikationsnummer:</span>
                <span class="value">{$text/tei:note[@type="publication"]/data(.)}</span>
                <span class="label">Datierung:</span>
                <span class="value">{stuecke:get-dates($text)}</span>
                <span class="label">Herkunft:</span>
                <span class="value">{stuecke:get-origplaces($text)}</span>
            </div>
            <div class="text">
                {stuecke:get-text-snippet($text/ancestor::tei:TEI)}
            </div>
            <div class="img">
                {if (stuecke:get-preferred-image($text/ancestor::tei:TEI) != "")
                 then <img src="{stuecke:get-preferred-image($text/ancestor::tei:TEI)}" alt="{stuecke:get-invno($text)}" />
                else "ohne Bild"}
            </div>
        </div>
    </div>
};

declare function stuecke:get-text-snippet($st as node()){
    let $snippet := $st//tei:text//tei:div[@type="edition"][@xml:lang="grc"]
    return if (string-length($snippet/data(.)) gt 250)
           then concat(substring($snippet, 1, 250), "...")
           else $snippet/data(.)
};

declare function stuecke:get-preferred-image($st as node()){
    let $URL := ($st//tei:graphic[tei:desc[@type="preferred"]])[1]/@url
    let $prevURL := replace($URL, "orig", "preview")
    let $prevURL := if (contains($prevURL, ".jpg"))
                    then replace($prevURL, "\.jpg", ".png")
                    else if (contains($prevURL, ".jpeg"))
                    then replace($prevURL, "\.jpeg", ".png")
                    else if (contains($prevURL, ".JPG"))
                    then replace($prevURL, "\.JPG", ".png")
                    else if (contains($prevURL, ".tif"))
                    then replace($prevURL, "\.tif", ".png")
                    else if (contains($prevURL, ".tiff"))
                    then replace($prevURL, "\.tiff", ".png")
                    else if (contains($prevURL, ".png") or contains($prevURL, ".PNG"))
                    then $prevURL
                    else if ($prevURL = "")
                    then ()
                    else concat($prevURL, ".png")
    return $prevURL
};
declare function stuecke:get-invno($res as document-node()){
    $res//tei:idno[1]
};

declare function stuecke:get-collection($res as document-node()) {
  $res//tei:msDesc/tei:msIdentifier/tei:collection
};

declare function stuecke:get-materials($res as document-node()){
    string-join($res//tei:msDesc/tei:physDesc//tei:material/tei:material, "; ")
};

declare function stuecke:get-origplaces($res as document-node()){
    string-join($res//tei:note[@type="orig_place"]//tei:placeName, "; ")
};

declare function stuecke:get-dimensions($id as xs:string){
    let $dimensions := doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msDesc/tei:physDesc//tei:dimensions
    let $width := let $width := $dimensions/tei:width
                  return if ($width != "") then concat("Breite: ", $width, " ", $width/@unit) else ()
    let $height := let $height := $dimensions/tei:height
                   return if ($height != "") then concat("Höhe: ", $height, " ", $height/@unit) else ()
    let $depth := let $depth := $dimensions/tei:depth
                  return if ($depth != "") then concat("Tiefe: ", $depth, " ", $depth/@unit) else ()
    let $length := let $length := $dimensions/tei:dim[@type="length"]
                   return if ($length != "") then concat("Länge: ", $length, " ", $length/@unit) else ()
    let $diameter := let $diameter := $dimensions/tei:dim[@type="diameter"]
                     return if ($diameter != "") then concat("Durchmesser: ", $diameter, " ", $diameter/@unit) else ()
    let $circumference := let $circumference := $dimensions/tei:dim[@type="circumference"]
                          return if ($circumference != "") then concat("Umfang: ", $circumference, " ", $circumference/@unit) else ()
    let $dimensions := string-join(($width, $height, $depth, $length, $diameter, $circumference), "; ")
    return $dimensions
};

declare function stuecke:get-dates($res as node()){
    let $dates := for $date in $res//tei:note[@type="orig_date"]/tei:date
                return if ($date/@type = "Zeitraum")
                       then if ($date[not(@notBefore)]) then concat("frühestens ", $date/@notAfter/data(.))
                            else if ($date[not(@notAfter)]) then concat("spätestens ", $date/@notBefore/data(.))
                            else concat($date/@notBefore, " – ", $date/@notAfter)
                       else $date/@when/data(.)
    
    return string-join($dates, "; ")
};

declare function stuecke:get-languages($res as node()) {
  string-join($res//tei:textLang//tei:term[@type="language"], "; ")
};

declare function stuecke:get-scripts($res as node()) {
  let $scripts := $res//tei:textLang//tei:term[@type="script"]
  for $script at $index in $scripts 
    where (not(empty($script))) 
    return if ($index > 1) then "; " else "" || $script
};

declare function stuecke:get-text-titles($st){
    string-join($st//tei:title, "; ")
};
