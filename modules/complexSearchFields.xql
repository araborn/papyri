xquery version "3.0";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace autocomplete="http://www.tei-c.org/";
import module namespace search="http://papyri.uni-koeln.de:8080/papyri/search" at "search.xqm";

declare option exist:serialize "method=json media-type=text/javascript jsonp=fields";

let $fields := for $fieldName in map:keys($search:fields)
	let $field := $search:fields($fieldName)
	let $operators := for $operator in $field("operators")
						let $display := $search:ops($operator)
						return	<operator>
									<value>{$operator}</value>
									<title>{$display}</title>
							   	</operator>
	return 	<fields>
				<title>{$field("title")}</title>
				<operators>{$operators}</operators>
			</fields>

return <blub>{$fields}</blub>