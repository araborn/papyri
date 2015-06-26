xquery version "3.0";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace autocomplete="http://www.tei-c.org/";
import module namespace search="http://papyri.uni-koeln.de:8080/papyri/search" at "search.xqm";


declare option exist:serialize "method=json media-type=text/javascript";


declare function autocomplete:lookup() {
	 let $stuecke := xmldb:xcollection('/db/apps/papyri/data/stuecke')
	 let $facetName := "herkunft"
  
	 let $values := for $value in distinct-values($stuecke//tei:note[@type="orig_place"]//tei:placeName)
  		return <blub>{$value}</blub>

  	return <wurst>{$values}</wurst>
};

let $fields := for $field in $search:fields
	let $operators := for $operator in $field("operators")
						let $display := $search:ops($operator)
						return	<operator>
									<value>{$operator}</value>
									<title>{$display}</title>
							   	</operator>
	return 	<field>
				<title>{$field("title")}</title>
				<operators>{$operators}</operators>
			</field>

return <blub>{$fields}</blub>