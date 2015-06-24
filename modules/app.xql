xquery version "3.0";

module namespace app="http://papyri.uni-koeln.de:8080/papyri/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://papyri.uni-koeln.de:8080/papyri/config" at "config.xqm";
import module namespace auth="http://papyri.uni-koeln.de:8080/papyri/auth" at "auth.xqm";
import module namespace error="http://papyri.uni-koeln.de:8080/papyri/error" at "error.xqm";
import module namespace helpers="http://papyri.uni-koeln.de:8080/papyri/helpers" at "helpers.xqm";
import module namespace search="http://papyri.uni-koeln.de:8080/papyri/search" at "search.xqm";
import module namespace date="http://papyri.uni-koeln.de:8080/papyri/date" at "date.xqm";
import module namespace stuecke="http://papyri.uni-koeln.de:8080/papyri/stuecke" at "stuecke.xqm";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with a class attribute: class="app:test". The function
 : has to take exactly 3 parameters.
 : 
 : @param $node the HTML node with the class attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)

(: Navigation :)
declare function app:menu($node as node(), $model as map(*)){
    let $resource := tokenize(request:get-url(), "/")[last()]
        return
        <nav class="navbar navbar-default" role="navigation">
            <ul class="nav navbar-nav">
             <!-- class="active" -->
                <li class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Objekte <b class="caret"></b></a>
                    <ul class="dropdown-menu">
                        <li><a href="{$helpers:app-root}/objekte/uebersicht">Übersicht</a></li>
                        <li><a href="{$helpers:app-root}/objekte/nach-inventarnummer">nach Inventarnummer</a></li>
                        <li><a href="{$helpers:app-root}/objekte/nach-datierung">nach Datierung</a></li>
                        <li><a href="{$helpers:app-root}/objekte/nach-herkunft">nach Herkunft</a></li>
                        <li><a href="{$helpers:app-root}/objekte/nach-material">nach Material</a></li>
                    </ul>
                </li>
                <li class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Texte <b class="caret"></b></a>
                    <ul class="dropdown-menu">
                        <li class="dropdown-submenu" >
                            <a href="#">Editionen</a>
                            <ul class="dropdown-menu">
                                <li><a href="{$helpers:app-root}/texte/editionen/nach-baenden">nach Bänden</a></li>
                                <li><a href="{$helpers:app-root}/texte/editionen/nach-titeln">nach Titeln</a></li>
                            </ul>
                        </li>
                        <li><a href="{$helpers:app-root}/texte/prominente-stuecke">Prominente Stücke</a></li>
                        <li><a href="{$helpers:app-root}/texte/uebersicht">Übersicht</a></li>
                        <li><a href="{$helpers:app-root}/texte/titel">nach Titel</a></li>
                        <li><a href="{$helpers:app-root}/texte/textsorte">nach Textsorte</a></li>
                        <li><a href="{$helpers:app-root}/texte/datierung">nach Datierung</a></li>
                        <li><a href="{$helpers:app-root}/texte/sprache">nach Sprache</a></li>
                        <li><a href="{$helpers:app-root}/texte/schrift">nach Schrift</a></li>
                    </ul>
                </li>
                <li class="dropdown">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">Recherche <b class="caret"></b></a>
                    <ul class="dropdown-menu">
                       <li><a href="{$helpers:app-root}/recherche/komplexe-suche">komplexe Suche</a></li>
                       <li><a href="{$helpers:app-root}/recherche/bibliographie">Bibliographie</a></li>
                    </ul>
                </li>
                <li>{if ($resource = "about.html") then attribute class {"active"} else ()}<a href="{$helpers:app-root}/about">About</a></li>
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
            <span class="close" onclick="document.getElementById('LoginForm').style.display='none';"><img src="{$helpers:app-root}/resources/icons/dialog_close.png" alt="Schließen" /></span>
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

declare function app:get-query-title($node as node(), $model as map(*)) {
  let $facetParam := request:get-parameter("facet", "")
  let $valueParam := request:get-parameter("value", "")

  let $facet := concat(upper-case(substring($facetParam, 1, 1)), substring($facetParam, 2))
  let $value := concat(upper-case(substring($valueParam, 1, 1)), substring($valueParam, 2))

  return if ($value = "") then $facet
         else string-join(($facet, ": ", $value))
};


declare function app:list-facet($node as node(), $model as map(*), $facet as xs:string?){
  let $facetName := request:get-parameter("facet", $facet)


  let $stuecke := xmldb:xcollection('/db/apps/papyri/data/stuecke')
  let $items := switch($facetName)
                    case "material" return distinct-values($stuecke//tei:msDesc/tei:physDesc//tei:material/tei:material)
                    case "herkunft" return distinct-values($stuecke//tei:note[@type="orig_place"]//tei:placeName)
                    case "datierung"
                      return for $century in distinct-values(for $teiDate in $stuecke//tei:note[@type="orig_date"]/tei:date return $teiDate/@*[name() = "notBefore"or name() = "notAfter" or name() = "when"]/date:format-century(data(.)))
                          order by $century
                          return map {
                            "display": $century,
                            "value": $century
                          }  
                      (:return for-each(distinct-values(for-each($stuecke//tei:note[@type="orig_date"]/tei:date) , function($date){
                          if ($date/@type = "Zeitraum")
                            then concat($date/@notBefore, "-", $date/@notAfter)
                            else $date/@when/data(.)
                        })
                      ):)
                    case "inventarnummer"
                        return for $i in (1 to count($stuecke))[. mod 30 = 1]
                          let $subsequence := subsequence($stuecke, $i, 30)
                          let $num :=  string-join((substring-before(util:document-name($subsequence[1]), '.xml'), "-", substring-before(util:document-name($subsequence[last()]), '.xml')) )
                          return map {
                            "display": $num,
                            "value": $i
                          }
                    

                    default return ()

  let $table := for $item in $items
                  where typeswitch($item)
                  case xs:string return $item != ""
                  case map() return $item('display') != ""
                   default return 1
                  order by $item
                  return typeswitch($item) 
                    case map() return <li><a class="papyri-facet" data-papyri-facet-value="{$item("value")}" href="{$helpers:app-root}/objekte/nach-{$facetName}/{$item("value")}">{$item("display")}</a></li>
                    default return <li><a class="papyri-facet" data-papyri-facet-value="{$item}" href="{$helpers:app-root}/objekte/nach-{$facetName}/{$item}">{$item}</a></li>
                  
                
                
  return  <ul class="papyri-facets" data-papyri-facet="{$facetName}">{$table}</ul>
};


(: Liste der vorhandenen Stück-Dateien :)
declare function app:list-items($node as node(), $model as map(*)){
    let $page := request:get-parameter("page", "1")
    let $facet := request:get-parameter("facet", "")
    let $value := request:get-parameter("value", "")

    let $maxNumPerPage := 30
    let $stuecke := xmldb:xcollection("/db/apps/papyri/data/stuecke")
    let $items := switch($facet) 
              case "material"
                return for $stueck in $stuecke
                  where $stueck//tei:msDesc/tei:physDesc//tei:material/tei:material/lower-case(.) = lower-case($value)
                  return util:document-name($stueck)
              case "herkunft"
                return for $stueck in $stuecke
                where $stueck//tei:note[@type="orig_place"]//tei:placeName/lower-case(.) = lower-case($value)
                return util:document-name($stueck)
              case "datierung" return ()
              case "inventarnummer"
                return for $stueck at $pos in $stuecke
                  let $startInv := concat(substring-before($value, '-'), ".xml")
                  let $startStueck := index-of($stuecke, $stuecke[util:document-name(.) = $startInv])
                  where $pos >= $startStueck and $pos < $startStueck + $maxNumPerPage
                  return util:document-name($stueck)
              default return ()


    let $table := <ul>
                    {for $res in $items
                    let $resID := substring-before($res, '.xml')
                    (:let $inv := app:get-invno($res):)
                    let $material := stuecke:get-materials($resID)
                    (:let $herkunft := app:get-origplace(doc(concat("/db/apps/papyri/data/stuecke/", $res)))
                    let $datierung := app:get-date(doc(concat("/db/apps/papyri/data/stuecke/", $res))):)
                    return <li>{$inv/data(.)}</li>
                    }
                 </ul>
  

    let $pageNav := () (:app:get-page-nav($node, $model, $items, $maxNumPerPage, $page, ""):)
    return ($pageNav, $table, $pageNav)
};


(: Blätterfunktion: nur eine bestimmte Seite mit Treffern anzeigen :)
(:declare function app:get-page($node as node(), $model as map(*), $nodes as item()*, $maxNum as xs:integer, $page as xs:integer){
    let $numItems := count($nodes)
    let $numPages := round($numItems div $maxNum)
    return subsequence($nodes, ($page - 1) * $maxNum + 1, $maxNum)
};:)

(: Blätterfunktion: Seitennavigation anzeigen :)
declare function app:get-page-nav($node as node(), $model as map(*)){
  if (map:contains($model, "error"))
    then ()
    else 
  
    let $queryString := concat("?", replace(request:get-query-string(), 'page=[0-9]+', ''), "&amp;")
    let $maxNum := xs:integer(request:get-parameter("max", 30))
    let $page := xs:integer(request:get-parameter("page", 1))

    let $numItems := $model("numberOfResults")
    let $numPages := round($numItems div $maxNum)
    return 
        <ul class="page-nav">
            <li class="first-page"><a href="{$queryString}page=1" title="zur ersten Seite">&lt;&lt;</a></li>
            <li class="prev-page"><a href="{$queryString}page={if ($page gt 1) then $page - 1 else $page}" title="eine Seite zurück">&lt;</a></li>
            {if ($page gt 2) 
             then <li><a href="{$queryString}page={$page - 2}" title="zur Seite {$page - 2}">{$page - 2}</a></li>
             else ()}
            {if ($page gt 1)
             then <li><a href="{$queryString}page={$page - 1}" title="zur Seite {$page - 1}">{$page - 1}</a></li>
             else ()}
            <li class="current-page">{$page}</li>
            {if ($page lt $numPages - 1)
             then <li><a href="{$queryString}page={$page + 1}" title="zur Seite {$page + 1}">{$page + 1}</a></li>
             else ()}
            {if ($page lt $numPages - 2)
             then <li><a href="{$queryString}page={$page + 2}" title="zur Seite {$page + 2}">{$page + 2}</a></li>
             else ()}
            <li class="next-page"><a href="{$queryString}page={if ($page lt $numPages) then $page + 1 else $page}" title="eine Seite vor">&gt;</a></li>
            <li class="last-page"><a href="{$queryString}page={$numPages}" title="zur letzten Seite">&gt;&gt;</a></li>
        </ul>
};

(: ########################################### AUSGABEN ################################################ :)

(: Titel/ID eines Stücks anzeigen :)
declare function app:item-title($node as node(), $model as map(*)){
    let $id := request:get-parameter("id", ())
    return <h1>{$id}</h1>
};

(: msIdentifier ausgeben :)
declare function app:show-msIdentifier($node as node(), $model as map(*), $tei as node()) as node()*{
    (<tr>
        <th>Inventarnummer:</th>
        <td>{$tei//tei:msDesc/tei:msIdentifier/tei:idno}</td>
    </tr>,
    <tr>
        <th>Sammlung:</th>
        <td>{$tei//tei:msDesc/tei:msIdentifier/tei:collection}</td>
    </tr>)
};

(: msContents ausgeben :)
declare function app:show-msContents($node as node(), $model as map(*), $tei as node()) as node()* {
    (: hier noch Fehlerbehandlung, wenn eine ungültige ID übergeben werden sollte :)
    for $item at $pos in $tei//tei:msContents/tei:msItemStruct
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
                    <td>{stuecke:get-dates($item)}</td>
                  </tr>
                  <tr>
                    <th>Herkunft:</th>
                    <td>{stuecke:get-origplaces($item)}</td>
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
    let $material := stuecke:get-materials($id)
    let $dimensions := stuecke:get-dimensions($id)
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



declare function app:parse-search-query() {

 let $explodedParams := for $param in request:get-parameter-names()
                            let $components := text:groups($param, '(searchField|searchTerm|combinationOperator|searchOperator)-([0-9]+)')
                            let $index := xs:integer($components[3])
                            order by $index
                            return map {
                              "index" := $index,
                              "name" := $components[2], 
                              "value" := request:get-parameter($param, "")
                            }

  let $fields := for $param in $explodedParams
     where $param("name") = "searchField"
     return $param("value")

  let $getConstraintComponentForIndex := function($component as xs:string, $index as xs:integer) {
    for $p in $explodedParams
      where $p('name') = $component and $p('index') = $index
      return $p('value') 
  }

  let $constraints := for $field at $index in $fields
                        return map {
                          "searchField" := $field,
                          "searchOperator" := $getConstraintComponentForIndex('searchOperator', $index),
                          "combinationOperator" :=  $getConstraintComponentForIndex('combinationOperator', $index),
                          "searchTerm" := $getConstraintComponentForIndex('searchTerm', $index) 
                        }

  return $constraints
};

declare %templates:wrap function app:post-test($node as node(), $model as map(*)) as map(*) {
  
  let $resultType := request:get-parameter("resultType", "item")

  let $constraints := for $constraint in app:parse-search-query()
                        where $constraint("searchTerm") != ""
                        return $constraint

  let $resultTypeName := if ($resultType = "item") then "items"
                          else "texts" 

  let $results := search:search($constraints, $resultType)
  let $numberOfResults := count($results)
  let $maxNum := xs:integer(request:get-parameter("max", 30))
  let $page := xs:integer(request:get-parameter("page", 1))


  return if (count($constraints)) then map {
    "constraints" := $constraints,
    "type" := $resultTypeName,
    "numberOfResults" := $numberOfResults,
    $resultTypeName := subsequence($results, ($page - 1) * $maxNum + 1, $maxNum)
  } else map {
    "error" := "Keine Suchparameter angegeben"
  }

};

declare function app:search-print-result-no($node as node(), $model as map(*)) {
  if (not(map:contains($model, "error")))
    then $model("numberOfResults")
    else 0
};

declare function app:search-print-error($node as node(), $model as map(*)) {
  if ($model("error") != "")
    then element {$node/name()} {($node/@*, $node/*, $model("error"))}
    else ()
};

declare %templates:wrap function
  app:constraint-print-field($node as node(), $model as map(*)) { $search:fields($model("constraint")("searchField"))("title") };

declare %templates:wrap function
  app:constraint-print-term($node as node(), $model as map(*)) { $model("constraint")("searchTerm") };

declare %templates:wrap function
  app:constraint-print-op($node as node(), $model as map(*)) { 
  
  let $searchOp := if (empty($model("constraint")("searchOperator")))
                    then $search:fields($model("constraint")("searchField"))($search:kFieldOperators)[1]
                    else $model("constraint")("searchOperator")


  let $combinationOp := $model("constraint")("combinationOperator")
    return if ($combinationOp = "and") 
          then  $search:ops($searchOp)
        else if ($searchOp = "post" or $searchOp = "pre")
          then  concat("nicht ", $search:ops($searchOp))
          else  concat($search:ops($searchOp), " nicht")
};


declare function app:search-print-item-result($node as node(), $model as map(*)) {

  let $res := $model("result")

  return ( 
    <div class="msidentifier">
      <a href="#">
        <span class="inv-no">
          {stuecke:get-invno($res)}, {stuecke:get-collection($res)}
        </span>
      </a>
    </div>,
    <div class="material">
      <span class="material">Material: <em>{stuecke:get-materials($res)}</em></span>&#160;
      <span class="herkunft">Herkunft: <em>{stuecke:get-origplaces($res)}</em></span>
    </div>,
    <div class="content-details">
      <div class="datierung">Datierung: <em>{stuecke:get-dates($res)}</em></div>
      <div class="sprachen-schrift">
        <span class="sprache">Sprache: <em>{stuecke:get-languages($res)}</em></span>&#160;
        {
          let $scripts := stuecke:get-scripts($res)
          return if ($scripts != "") then
            element {"span"} {
              attribute {"class"} {"schrift"},
              "Schrift: ",
              element {"em"} {$scripts}
            }
          else ()
        }
      </div>
    </div>
  )
};

declare function app:search-print-text-result($node as node(), $model as map(*)) {
  let $res := $model("result")
  let $parentItem := root($res)

  let $title := <div><a href="#">{stuecke:get-text-titles($res)}</a></div>
  let $date := <div class="datierung">Datierung: <em>{stuecke:get-dates($res)}</em></div>
  let $textInfo := <div class="sprachen-schrift">
                        <span class="sprache">Sprache: <em>{stuecke:get-languages($res)}</em></span>&#160;
                        {
                          let $scripts := stuecke:get-scripts($res)
                          return if ($scripts != "") then
                            element {"span"} {
                              attribute {"class"} {"schrift"},
                              "Schrift: ",
                              element {"em"} {$scripts}
                            }
                          else ()
                        }
                    </div>
  let $itemTitle := <div class="texttraeger-info">
                      Textträger:
                      <a href="#">
                        <span class="inv-no">
                          {stuecke:get-invno($parentItem)}, {stuecke:get-collection($parentItem)}
                        </span>
                      </a> 
                    </div>
  let $itemInfo := <div class="material">
                    <span class="material">Material: <em>{stuecke:get-materials($parentItem)}</em></span>&#160;
                    <span class="herkunft">Herkunft: <em>{stuecke:get-origplaces($parentItem)}</em></span>
                  </div>

  let $textSnippet := <div class="snippet">
                        {stuecke:get-text-snippet($res)}
                      </div>

  return ($title, $date, $textInfo, $itemTitle, $itemInfo, $textSnippet)
};



declare function app:get-search-field($node as node(), $model as map(*)) {
  let $field := request:get-parameter("name", "")
  let $index := xs:integer(request:get-parameter("index", "0"))

  return app:create-search-field($field, $index)
};

declare function app:create-search-field($fieldID as xs:string, $index as xs:integer) {

    let $prefillSearchField := request:get-parameter(concat('searchTerm-', $index), "")
    let $prefillCombineOp := request:get-parameter(concat('combinationOperator-', $index), "")
    let $prefillSearchOp := request:get-parameter(concat('searchOperator-', $index), "")

    let $field := $search:fields($fieldID)

     let $searchOperatorOptions := for $operator in $field('operators')
                                      let $attSelected := if ($prefillSearchOp = $operator)
                                                            then attribute {"selected"} {"selected"}
                                                            else () 
                                      return <option value="{$operator}">{($attSelected, $search:ops($operator))}</option>
     let $searchOperatorInput := if (count($searchOperatorOptions) > 1) 
                                    then <select class="operator" name="{concat('searchOperator-', $index)}">
                                                {$searchOperatorOptions}
                                         </select>
                                    else <span class="operator">{$searchOperatorOptions[1]/text()}</span>
      let $searchFieldOptions := for $selectField in map:keys($search:fields)
        return 
          <option value="{$selectField}">
          {
            let $attSelected := if ($fieldID = $selectField) 
                                 then attribute {"selected"} {"selected"}
                                else ()
            return ($attSelected, $search:fields($selectField)("title"))
          }
          </option>
      let $orButton := <a href="#">oder</a>
      let $removeButton := if ($index = 1) then () else <a href="#" class="remove"> - </a>
    return 
    <fieldset id="{$fieldID}" class="search-field">
        <select class="combine" name="{concat('combinationOperator-', $index)}">
           <option value="and">{(if ($prefillCombineOp = 'and') then attribute {"selected"}{"selected"} else (), if ($index = 1) then "" else "und")}</option>
           <option value="nand">{(if ($prefillCombineOp = 'nand') then attribute {"selected"}{"selected"} else (),  if ($index = 1) then "nicht" else "und nicht")}</option>
        </select>
        <select class="field" name="{concat('searchField-', $index)}">
          {$searchFieldOptions}
        </select>
        <!--<label for="{$field('title')}">{upper-case(substring($field('title'), 1, 1)) || substring($field('title'), 2)}</label>-->
        {$searchOperatorInput}
        { let $fieldName := concat('searchTerm-', $index)
          return element {$field('input')/name()} {
          (attribute {'name'} {$fieldName}, 
            attribute {'value' } { $prefillSearchField },
            $field('input')/@*, $field('input')/*,
            if ($field('input')/name() = "select") then
              app:form-control-select-options($fieldName, (
                <option value="">(Alle)</option>, 
                for $value in $field('values')()
                  where $value != "" 
                  return <option value="{$value}">{$value}</option>
              ))
            else ()
            )}
          }
        &#160;{$orButton}
        &#160;{$removeButton}
    </fieldset>
};

declare %templates:wrap
function app:search-fields($node as node(), $model as map(*))  {


    let $constraints := app:parse-search-query()

    let $initialFields := if (not(empty($constraints))) 
                            then for $const in $constraints
                              return $const("searchField")

                            else ("volltext", "material")

    for $field at $index in $initialFields
      return app:create-search-field($field, $index)
};

(: Vorselektieren des Ergebnistyps der komplexen Suche anhand der Query-Parameter.
   Notwendig, da templates:form-control bei Inputs vom Typ "radio" nicht funktioniert. :)
declare function app:form-control-resultType($node as node(), $model as map(*)) {
  let $resultType := request:get-parameter("resultType", "item")
  return if ($resultType != "" and $resultType = $node/@value) 
    then element {$node/name()} {(attribute {"checked"} {"checked"}, $node/@*, $node/*)}
    else $node
};

(: Vorselektieren Suchbegriffs in Dropdown-Listen der komplexen Suche anhand der Query-Parameter :)
declare function app:form-control-select-options($paramName as xs:string, $options as element(option)*) {
  let $paramQueryValue := request:get-parameter($paramName, "")
  
  return for $option in $options     
                let $optionValue := $option/@value/data(.)
                return if ($paramQueryValue = $optionValue) then
                  element {"option"} {(attribute {"selected"} {"selected"}, $option/@*, $option/*, $option/text())}
                else $option
};