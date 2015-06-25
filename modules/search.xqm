xquery version "3.0";

(:~
 :  API zur Suche im Papyri-Bestand 
 :)


module namespace search="http://papyri.uni-koeln.de:8080/papyri/search";
import module namespace app="http://papyri.uni-koeln.de:8080/papyri/templates" at "app.xql";
import module namespace date="http://papyri.uni-koeln.de:8080/papyri/date" at "date.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $search:data-path := "/db/apps/papyri/data/stuecke";

(:~
 : Gibt alle Objekte oder Texte der Papyri-Sammlung zurück, die den Suchbedingungen entsprechen
 :  
 : @param $constraints Suchbedingungen als Sequenz von Maps mit folgenden Einträgen (jeweils als xs:string):
 :          *  "searchField": die ID des Felds, in dem gesucht werden soll (siehe $search:fields)
 :          *  "combinationOperator": wie die Suchbedingung mit den andren kombiniert werden soll
 :                  gültige Werte z.Zt. "and" für UND sowie "nand" für UND NICHT
 :          * "searchOperator": Vergleichsoperator für die Bedingung (siehe $search:ops)
 :          * "searchTerm": Suchbegriff oder Sequenz von mit ODER zu kombinierenden Suchbegriffen
 : @param $resultType: "item" für Suche nach Textträgern, "text" für Suche nach Texten
 : @return Sequenz von <tei:TEI>-Nodes (bei resultType $search:cItem) bzw. <tei:msItemStruct>-Nodes (bei resultType $search:cText)
 :)
declare function search:search($constraints as map()*, $resultType as xs:string) {

    let $collection := xmldb:xcollection($search:data-path)

    (: Funktion, die nach Textträger- bzw. Textbedingungen filtert :)
    let $filterConstraints := function($type as xs:string) {
        for $constraint in $constraints 
            let $field := $search:fields($constraint("searchField"))
            where $field($search:kFieldRef) = $type and $constraint("searchTerm") != ""
            return $constraint
    }

    (: filtere zunächst nach Bedigungen, die sich auf die Textträger beziehen :)
    let $itemConstraints := $filterConstraints($search:cItem)    
    let $matchingItems := search:resolve($collection, $itemConstraints)

    (: filtere dann ggf. nach Bedingungen, die sich auf die Texte (msItemStruct) beziehen :)
    (: und gebe je nach resultType die tei-Node oder alle passenden msItemStruct-Nodes zurück :)
    let $textConstraints := $filterConstraints($search:cText)
    return if (empty($textConstraints))
            then for $item in $matchingItems
                return if ($resultType = $search:cItem)
                        then $item
                        else $item//tei:msItemStruct
            else for $item in $matchingItems 
                    let $matching := $item//tei:msItemStruct[search:resolve(., $textConstraints)]
                    where count($matching) > 0
                    return if ($resultType = $search:cItem)
                        then $item
                        else $matching


};

(:~
 : Wendet alle Suchbedingungen aus $constraints rekursiv (UND) auf die Nodes in $base an 
 :  
 : @param $base: die Nodes, die gefiltert werden sollen
 : @param $constraints Suchbedingungen als Sequenz von Maps (Format siehe $search:search)
 : @return Sequenz den Bedingungen entsprechender Nodes
 :)
declare function search:resolve($base as node()*, $constraints as map()*) {

	if (not(empty($constraints))) then

        let $constraint := $constraints[1]
        let $searchOp := $constraints[1]('searchOperator')
		let $field := $search:fields($constraint("searchField")) 
        let $resolveFunction := $field($search:kFieldResolve)

		let $results := for $searchTerm in $constraint("searchTerm")
                            return for $item at $index in $base
                                                where if ($constraint("combinationOperator") = 'nand') then 
                                                        not($resolveFunction($item, $searchOp, $searchTerm))
                                                    else
                                                        $resolveFunction($item, $searchOp, $searchTerm)
                                            return $item


        (: Filtere Duplikate bei ODER-Verknüpfungen (mehrere Suchbegriffe für ein Feld) :)
        let $distinctResults := if (count($constraint("searchTerm")) = 1) then 
                                    $results
                                 else 
                                    for $resultID in distinct-values($results/*[1]/@xml:id)
                                        return $results[*/@xml:id = $resultID]

		return search:resolve($distinctResults, subsequence($constraints, 2))
	   
    else 
		$base
};


(: Definition der Vergleichsoperatoren :)
declare variable $search:ops := map {
    "eq" := "entspricht",
    "cont" := "enthält",
    "post" := "ab",
    "pre" := "bis"
};

(: Konstanten für den Ergebnistyp :)
declare variable $search:cItem := "item"; (: Textträger :)
declare variable $search:cText := "text"; (: einzelner Text (msItemStruct) :)


(: 
 :  Definition der Suchfelder  
 :)

(: Schlüsselnamen der Maps für die Suchfelder:)
declare variable $search:kFieldTitle := "title"; (: Titel des Felds :)
declare variable $search:kFieldRef := "ref"; (: Bezieht sich das Feld auf den Textträger 
                                                ($search:cItem) oder den Text ($search:cText)? :)
declare variable $search:kFieldOperators := "operators"; (: Vergleichsoperatoren für dieses Feld, siehe $search:ops :)
declare variable $search:kFieldInput := "input"; (: Das HTML-Formularelement für dieses Feld :)
declare variable $search:kFieldResolve := "resolve"; (: Die Suchfunktion, die eine Bedingung für das entsprechende Feld auflöst :)
declare variable $search:kFieldValues := "values"; (: Funktion, die alle für das Feld im Korpus enthaltenen Werte zurückgibt
                                                      (für Facettenbrowsing und Drop-Down-Felder in der Suche) :)

(: Definition der Suchfelder :)
declare variable $search:fields := map {
	(: Suche nach Inventarnummer :)
    "inventarnummer" := map {
    	$search:kFieldTitle := "Inventarnummer",
        $search:kFieldRef := $search:cItem,
        $search:kFieldOperators := ("cont"),
        $search:kFieldInput := <input type="text"></input>,
        $search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	contains(substring-before(util:document-name($item), ".xml"), $term)
        }
    },
    (: Suche nach Material :)
    "material" := map {
    	$search:kFieldTitle := "Material",
        $search:kFieldRef := $search:cItem,
        $search:kFieldOperators := ("eq"),
        $search:kFieldInput := <select></select>,
        $search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
		    $item//tei:msDesc/tei:physDesc//tei:material/tei:material[contains(lower-case(.), lower-case($term))]
		}, 
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msDesc/tei:physDesc//tei:material/tei:material)
        }
				
    },
    (: Suche nach Herkunft :)
    "herkunft" := map {
    	$search:kFieldTitle := "Herkunft",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("cont"),
        $search:kFieldInput := <input type="text"></input>,
        $search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	$item//tei:msItemStruct/tei:note[@type="orig_place"]//tei:placeName[contains(lower-case(.), lower-case($term))]
        }
    },
    (: Suche nach Sammlung :)
    "sammlung" := map {
    	$search:kFieldTitle := "Sammlung",
        $search:kFieldRef := $search:cItem,
        $search:kFieldOperators := ("cont"),       
    	$search:kFieldInput := <input type="text"></input>,
    	$search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	$item//tei:msIdentifier/tei:collection[contains(lower-case(.), lower-case($term))]
        }
    }, 
    (: Suche nach Publikationsstatus :)
   "publikationsstatus" := map {
    	$search:kFieldTitle := "Publikationsstatus",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("eq"),
    	$search:kFieldInput := <select></select>,
    	$search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	$item//tei:msItemStruct/tei:note[@type="availability" and contains(., $term)]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:note[@type="availability"])
        }
    },
    (: Suche nach Textsorte :)
    "textsorte" := map {
    	$search:kFieldTitle := "Textsorte",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("eq"),
    	$search:kFieldInput := <select></select>,
    	$search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	$item//tei:msItemStruct/tei:note[@type="text_type" and contains(., $term)]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:note[@type="text_type"])
        }
    },
    (: Suche nach Textsprache :)
    "sprache" := map {
    	$search:kFieldTitle := "Sprache",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("eq", "cont"),
    	$search:kFieldInput := <input type="text"></input>,
    	$search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
			        	 switch($op) 
                            case 'cont' return $item//tei:msItemStruct/tei:textLang/tei:note[@type="language" and contains(lower-case(.), lower-case($term))]
                            default  return $item//tei:msItemStruct/tei:textLang/tei:note[@type="language" and lower-case(.) = lower-case($term)]
        }
    },
    (: Suche in allen Elementen :)
    "volltext" := map {
        $search:kFieldTitle := "Volltext",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("cont"),
        $search:kFieldInput := <input type="text"></input>,
        $search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
            $item//tei:msItemStruct/tei:textLang/tei:note[@type="language" and contains(lower-case(.), lower-case($term))]
        }
    },
    (: Suche nach Datierung :)
    "datierung" := map {
        $search:kFieldTitle := "Datierung",
        $search:kFieldRef := $search:cText,
        $search:kFieldOperators := ("pre", "post"),
        $search:kFieldInput := <input type="text"></input>,
        $search:kFieldResolve := function($item as node(), $op as xs:string?, $term as xs:string) {
            let $searchDate := date:parse-tei-date($term)
            let $teiDates := $item//tei:msItemStruct/tei:note[@type="orig_date"]/tei:date
            for $teiDate in $teiDates 
                where if ($teiDate/@type = "Zeitraum")
                        then switch($op)
                            case 'post'     return  date:parse-tei-date($teiDate/@notAfter) ge $searchDate
                            default (:pre:) return  $searchDate le date:parse-tei-date($teiDate/@notAfter)
                        else (:Zeitpunkt:) switch($op)
                            case 'post'     return date:parse-tei-date($teiDate/@when) ge $searchDate
                            default (:pre:) return date:parse-tei-date($teiDate/@when) le $searchDate


                return $teiDate

        }
    }
};


declare %private function search:filtered-collection($query as xs:string, $value) {
	for $stueck in xmldb:xcollection($search:data-path)
		where switch($query)
			case "material" return $stueck//tei:msDesc/tei:physDesc//tei:material/tei:material/lower-case(.) = lower-case($value)
			case "herkunft" return $stueck//tei:note[@type="orig_place"]//tei:placeName/lower-case(.) = lower-case($value)
			default return 1
		return $stueck
};


declare function search:query($node as node(), $model as map(*)) {

	let $limit := 30
	let $start := request:get-parameter("start", 1)
	let $parameters := request:get-parameter-names()

	let $results := if (count($parameters) > 0) 
					then for $param in $parameters
							for $value in request:get-parameter($param, "")
								for $stueck in search:filtered-collection($param, $value)
									return $stueck//tei:msIdentifier/tei:idno/data(.)
					else for $stueck in xmldb:xcollection($search:data-path)
						return $stueck//tei:msIdentifier/tei:idno/data(.)	

	return (<div>{count($results)} Ergebnisse</div>, <ul>{
				for $result in subsequence($results, $start, $start + $limit)
					return <li>{$result}</li>
				}
			</ul>)

};