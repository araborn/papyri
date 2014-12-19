xquery version "3.0";

module namespace app="http://papyri.uni-koeln.de:8080/papyri/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://papyri.uni-koeln.de:8080/papyri/config" at "config.xqm";
import module namespace auth="http://papyri.uni-koeln.de:8080/papyri/auth" at "auth.xqm";
import module namespace error="http://papyri.uni-koeln.de:8080/papyri/error" at "error.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with a class attribute: class="app:test". The function
 : has to take exactly 3 parameters.
 : 
 : @param $node the HTML node with the class attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};


(: Navigation :)
declare function app:menu($node as node(), $model as map(*)){
    let $resource := tokenize(request:get-url(), "/")[last()]
        return
        <nav class="navbar navbar-default" role="navigation">
            <ul class="nav navbar-nav">
             <!-- class="active" -->
                <li class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Sammlung <b class="caret"></b></a>
                    <ul class="dropdown-menu">
                        <li><a href="/pages/sammlung_inventarnummer.html">Nach Inventarnummer</a></li>
                        <li><a href="/pages/sammlung_datierung.html">Nach Datierung</a></li>
                        <li><a href="/pages/sammlung_herkunft.html">Nach Herkunft</a></li>
                        <li><a href="/pages/sammlung_material.html">Nach Material</a></li>
                    </ul>
                </li>
                <li class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Texte <b class="caret"></b></a>
                    <ul class="dropdown-menu">
                        <li><a href="#">Publikationen</a></li>
                        <li><a href="/pages/stuecke.html">Die wichtigsten Stücke</a></li>
                        <li><a href="#">Nach Titel</a></li>
                        <li><a href="#">Nach Textsorte</a></li>
                        <li><a href="#">Nach Datierung</a></li>
                        <li><a href="#">Nach Herkunft</a></li>
                    </ul>
                </li>
                <li>{if ($resource = "bibliographie.html") then attribute class {"active"} else ()}<a href="/pages/bibliographie.html">Bibliographie</a></li>
                <li><a href="#">Recherche</a></li>
                <li>{if ($resource = "about.html") then attribute class {"active"} else ()}<a href="/pages/about.html">About</a></li>
             </ul>
        </nav>
};

(: einfaches Suchformular (macht noch nichts) :)
declare function app:search($node as node(), $model as map(*)){
    <form class="navbar-form navbar-left" role="search">
        <div class="form-group">
            <input type="text" class="form-control" placeholder="Suche" />&#x00A0;
            <input type="submit" value="Los!" />
        </div>
    </form>
};

(: LOGIN-Formular :)
declare function app:login($node as node(), $model as map(*)){
    let $path := request:get-url()
    let $error := session:get-attribute("error")
    return
    <div class="login">
        {if (auth:logged-in())
         then (<span class="navbar-text">Angemeldet als: {xmldb:get-current-user()}</span>,
              <a href="logout?path={$path}">Logout</a>
              )
         else <span onclick="document.getElementById('LoginForm').style.display='block';">Login</span>
         }
        <div id="LoginForm" style="display: {if ($error = "login") then "block;" else "none;"}">
            <span class="close" onclick="document.getElementById('LoginForm').style.display='none';"><img src="/resources/icons/dialog_close.png" alt="Schließen" /></span>
            <form method="POST" action="/login">
               {if ($error = "login") 
               then (app:print-error($node, $model, $error), session:remove-attribute("error"))
               else ()}
               Benutzername:<br /><input name="username" type="text" size="30" maxlength="30" /><br />
               Passwort:<br /><input name="password" type="password" size="30" maxlength="40" /><br />
               <input type="submit" value="Anmelden" /> <input type="reset" value="Zurücksetzen" />
               <input type="hidden" name="path" value="{$path}"/>
            </form>
        </div>
    </div>
};

(: Liste der vorhandenen Stück-Dateien :)
declare function app:list-items($node as node(), $model as map(*), $type as xs:string){
    let $page := request:get-parameter("page", "1")
    let $maxNumPerPage := 30
    let $items := if ($type = "inventarnummer")
                  then 
                    for $res in xmldb:get-child-resources("/db/apps/papyri/data/stuecke")
                    let $inv := app:get-invnr($res)
                    order by $inv
                    return $res
                  else if ($type = "material")
                  then for $res in xmldb:get-child-resources("/db/apps/papyri/data/stuecke")
                        let $id := substring-before($res, ".xml")
                        let $material := app:get-material($id)
                        order by $material
                        return $res
                  else if ($type = "herkunft")
                  then for $res in xmldb:get-child-resources("/db/apps/papyri/data/stuecke")
                        let $id := substring-before($res, ".xml")
                        let $herkunft := app:get-origplace(doc(concat("/db/apps/papyri/data/stuecke/", $res)))
                        order by $herkunft
                        return $res
                  else if ($type = "datierung")
                  then for $res in xmldb:get-child-resources("/db/apps/papyri/data/stuecke")
                       let $datierung := app:get-date(doc(concat("/db/apps/papyri/data/stuecke/", $res)))
                       order by $datierung
                       return $res
                  else
                    for $res in xmldb:get-child-resources("/db/apps/papyri/data/stuecke")
                    order by $res
                    return $res
    let $table := <ul>
                    {for $res in app:get-page($node, $model, $items, $maxNumPerPage, xs:integer($page))
                    let $resID := substring-before($res, '.xml')
                    let $inv := app:get-invnr($res)
                    let $material := app:get-material($resID)
                    let $herkunft := app:get-origplace(doc(concat("/db/apps/papyri/data/stuecke/", $res)))
                    let $datierung := app:get-date(doc(concat("/db/apps/papyri/data/stuecke/", $res)))
                    return <li><a href="stueck.html?id={$resID}">{
                                if ($type = "inventarnummer")
                                then $inv/data(.)
                                else if ($type = "material")
                                then $material
                                else if ($type = "herkunft")
                                then $herkunft
                                else if ($type ="datierung")
                                then $datierung
                                else $resID}
                                </a></li>
                    }
                 </ul>
    let $pageNav := app:get-page-nav($node, $model, $items, $maxNumPerPage, $page, $type)
    return ($pageNav, $table, $pageNav)
};


(: Blätterfunktion: nur eine bestimmte Seite mit Treffern anzeigen :)
declare function app:get-page($node as node(), $model as map(*), $nodes as item()*, $maxNum as xs:integer, $page as xs:integer){
    let $numItems := count($nodes)
    let $numPages := round($numItems div $maxNum)
    return subsequence($nodes, ($page - 1) * $maxNum + 1, $maxNum)
};

(: Blätterfunktion: Seitennavigation anzeigen :)
declare function app:get-page-nav($node as node(), $model as map(*), $nodes as item()*, $maxNum as xs:integer, $page as xs:integer, $type as xs:string){
    let $numItems := count($nodes)
    let $numPages := round($numItems div $maxNum)
    return 
        <ul class="page-nav">
            <li class="first-page"><a href="sammlung_{$type}.html?page=1" title="zur ersten Seite">&lt;&lt;</a></li>
            <li class="prev-page"><a href="sammlung_{$type}.html?page={if ($page gt 1) then $page - 1 else $page}" title="eine Seite zurück">&lt;</a></li>
            {if ($page gt 2) 
             then <li><a href="sammlung_{$type}.html?page={$page - 2}" title="zur Seite {$page - 2}">{$page - 2}</a></li>
             else ()}
            {if ($page gt 1)
             then <li><a href="sammlung_{$type}.html?page={$page - 1}" title="zur Seite {$page - 1}">{$page - 1}</a></li>
             else ()}
            <li class="current-page">{$page}</li>
            {if ($page lt $numPages - 1)
             then <li><a href="sammlung_{$type}.html?page={$page + 1}" title="zur Seite {$page + 1}">{$page + 1}</a></li>
             else ()}
            {if ($page lt $numPages - 2)
             then <li><a href="sammlung_{$type}.html?page={$page + 2}" title="zur Seite {$page + 2}">{$page + 2}</a></li>
             else ()}
            <li class="next-page"><a href="sammlung_{$type}.html?page={if ($page lt $numPages) then $page + 1 else $page}" title="eine Seite vor">&gt;</a></li>
            <li class="last-page"><a href="sammlung_{$type}.html?page={$numPages}" title="zur letzten Seite">&gt;&gt;</a></li>
        </ul>
};

(: ########################################### AUSGABEN ################################################ :)

(: Titel/ID eines Stücks anzeigen :)
declare function app:item-title($node as node(), $model as map(*)){
    let $id := request:get-parameter("id", ())
    return <h1>{$id}</h1>
};

(: msIdentifier ausgeben :)
declare function app:show-msIdentifier($node as node(), $model as map(*), $id as xs:string) as node()*{
    (<tr>
        <th>Inventarnummer:</th>
        <td>{doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msDesc/tei:msIdentifier/tei:idno}</td>
    </tr>,
    <tr>
        <th>Sammlung:</th>
        <td>{doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msDesc/tei:msIdentifier/tei:collection}</td>
    </tr>)
};

(: msContents ausgeben :)
declare function app:show-msContents($node as node(), $model as map(*), $id as xs:string) as node()* {
    (: hier noch Fehlerbehandlung, wenn eine ungültige ID übergeben werden sollte :)
    for $item at $pos in doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msContents/tei:msItemStruct
    let $heading := <h2>Text Nr. {$pos}</h2>
    let $languages := string-join($item/tei:textLang//tei:term[@type="language"], "; ")
    let $scripts := string-join($item/tei:textLang//tei:term[@type="script"], "; ")
    let $md := <table class="text-md">
                  <tr>
                    <th>Titel:</th>
                    <td>{$item/tei:title/data(.)}</td>
                  </tr>
                  <tr>
                    <th>Publikationsnummer:</th>
                    <td>{$item/tei:note[@type="publication"]}</td>
                  </tr>
                  <tr>
                    <th>Textsorte:</th>
                    <td>{$item/tei:note[@type="text_type"]}</td>
                  </tr>
                  <tr>
                    <th>Datierung:</th>
                    <td>{app:get-date($item)}</td>
                  </tr>
                  <tr>
                    <th>Herkunft:</th>
                    <td>{app:get-origplace($item)}</td>
                  </tr>
                  {if ($languages != "")
                  then  <tr>
                            <th>Sprache:</th>
                            <td>{$languages}</td>
                          </tr>
                  else ()}
                 {if ($scripts != "")
                 then 
                  <tr>
                    <th>Schrift:</th>
                    <td>{$scripts}</td>
                  </tr>
                  else ()}
               </table> 
    let $content := <div class="note_content">
                        <h3>Anmerkung zum Inhalt</h3>
                         {for $p in $item/tei:note[@type="content"]/tei:p
                           return <p>{$p/data(.)}</p>}
                    </div>
    return ($heading, $md, $content)
};

(: physDesc ausgeben :)
declare function app:show-physDesc($node as node(), $model as map(*), $id as xs:string) as node()*{
    let $material := app:get-material($id)
    let $dimensions := app:get-dimensions($id)
    return
        (if ($material != "") 
        then
            <tr>
                <th>Material:</th>
                <td>{$material/data(.)}</td>
            </tr> 
        else (),
        if ($dimensions != "") 
        then
            <tr>
                <th>Maße:</th>
                <td>{$dimensions}</td>
            </tr> 
        else ())
};

(: additional ausgeben :)
declare function app:show-additional($node as node(), $model as map(*), $id as xs:string) as node()*{
    <tr>
        <th>Versicherungssumme:</th>
        <td>{doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msDesc/tei:additional//tei:note[@type="coverage_amount"]}</td>
    </tr>
};


(: Fehlermeldung ausgeben :)
declare function app:print-error($node as node(), $model as map(*), $result) as node(){
        <p class="error">{error:get-message(data($result))}</p>
};

declare function app:get-invnr($resource-name as xs:string){
    (doc(concat("/db/apps/papyri/data/stuecke/", $resource-name))//tei:idno)[1]
};

declare function app:get-material($id as xs:string){
    (doc(concat("/db/apps/papyri/data/stuecke/", $id ,".xml"))//tei:msDesc/tei:physDesc//tei:material/tei:material)[1]
};

declare function app:get-origplace($item as node()){
    string-join($item//tei:note[@type="orig_place"]//tei:placeName, "; ")
};

declare function app:get-dimensions($id as xs:string){
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

declare function app:get-date($item as node()){
    let $dates := for $date in $item//tei:note[@type="orig_date"]/tei:date
                return if ($date/@type = "Zeitraum")
                       then concat($date/@notBefore, "-", $date/@notAfter)
                       else $date/@when/data(.)
    return string-join($dates, "; ")
};
