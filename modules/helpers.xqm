xquery version "3.0";

(:~
 : Modul, das Hilfsfunktionen zur Ersetzung von Links enthält
 :)

module namespace helpers="http://papyri.uni-koeln.de:8080/papyri/helpers";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://papyri.uni-koeln.de:8080/papyri/config" at "config.xqm";

(: web-root of the app :)
declare variable $helpers:app-root := $config:webapp-root;
declare variable $helpers:file-path := $config:file-path;
declare variable $helpers:request-path := $config:request-path;
declare variable $helpers:webfile-path := $config:webfile-path;

declare function helpers:print-app-root-js($node as node(), $model as map(*)) {
  <script type="text/javascript">
      var papyri_app_root = "{$helpers:app-root}";
  </script>
};

declare function helpers:app-root($node as node(), $model as map(*)){
 let $elname := $node/node-name(.)
 
 return if (xs:string($elname) = "link")
        then <link href="{$helpers:app-root}/{$node/@href}">
                {$node/@*[not(xs:string(node-name(.)) = "href") and not(xs:string(node-name(.)) = "class")]}
                {helpers:copy-class-attr($node)}
             </link>
        else if (xs:string($elname) = "script" and $node/@type = "text/javascript")
        then <script type="{$node/@type}" src="{$helpers:app-root}/{$node/@src}" />
        else if (xs:string($elname) = "img")
        then <img src="{$helpers:app-root}/{$node/@src}">
                {$node/@*[not(xs:string(node-name(.)) = "src") and not(xs:string(node-name(.)) = "class")]}
                {helpers:copy-class-attr($node)}
             </img>
        else if (xs:string($elname) = "a")
             then <a href="{$helpers:app-root}/{$node/@href}">
                    {$node/@*[not(xs:string(node-name(.)) = "href") and not(xs:string(node-name(.)) = "class")]}
                    {helpers:copy-class-attr($node)}
                    {templates:process($node/node(), $model)}
                  </a>
        else if (xs:string($elname) = "form")
             then <form action="{$helpers:app-root}/{$node/@action}" class="helpers:app-root">
                    {$node/@*[not(xs:string(node-name(.)) = "action") and not(xs:string(node-name(.)) = "class")]}
                    {helpers:copy-class-attr($node)}
                    {templates:process($node/node(), $model)}
                  </form>
        else $node
};

declare function helpers:copy-class-attr($node as node()){
    attribute  class {$node/@class/concat(substring-before(., "helpers:app-root"), substring-after(., "helpers:app-root"))}
};