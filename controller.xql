xquery version "3.0";

import module namespace auth="http://papyri.uni-koeln.de:8080/papyri/auth" at "modules/auth.xqm";
import module namespace config="http://papyri.uni-koeln.de:8080/papyri/config" at "modules/config.xqm";
import module namespace autocomplete="http://papyri.uni-koeln.de:8080/papyri/autocomplete" at "modules/autocomplete.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
declare variable $exist:app := concat($config:webapp-root,'/');






if ($exist:path eq "/" or $exist:path eq "") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{$exist:app}index.html"/>
    </dispatch>
else if ($exist:path eq "/login") then
    let $path := substring-after(request:get-parameter("path", ()), "/apps/papyri")
    return
        if (auth:login())
        then (session:remove-attribute("error"),
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="http://papyri.uni-koeln.de{$path}" />
             </dispatch>)
    else (session:set-attribute("error", "login"),
         <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="http://papyri.uni-koeln.de{$path}" />
         </dispatch>)
else if ($exist:path eq "/logout") then
    let $path := substring-after(request:get-parameter("path", ()), "/apps/papyri")
    return
        if (auth:logout())
        then <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="http://papyri.uni-koeln.de{$path}?logout=true" />
             </dispatch>
        (: Bei Logout-Fehler keine Meldung :)
        else <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="http://papyri.uni-koeln.de{$path}" />
             </dispatch>
else if (starts-with($exist:path, "/query")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/templates/query.html" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql" />
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
(: JSON Autocomplete :)
else if (starts-with($exist:path, "/values")) then
    autocomplete:lookup()
(: Facettierte Übersicht :)
else if (starts-with($exist:path, "/uebersicht")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/pages/objekte/uebersicht.html" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql" />
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
(: Liste der Objekte :)
else if (starts-with($exist:path, "/objekte")) then
    let $components := text:groups($exist:path, "/objekte/nach-([a-z]+)/?([^/]+)?/?$")
    let $forward := if (($components)[3])
        then "/pages/objekte/stuecke.html"
        else "/pages/objekte/facette.html"

    return <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$forward}" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                 <add-parameter name="facet" value="{$components[2]}" />
                 <add-parameter name="value" value="{util:unescape-uri($components[3], 'UTF-8')}" />
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>
(: Unterseiten 1. Ebene :)
else if (matches($exist:path, "^/[a-z-]+$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/pages/{$exist:resource}.html" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql" />
        </view>
        <error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
(: Unterseiten 2. Ebene :)
else if (matches($exist:path, "^/[a-z-]+/[a-z-]+$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/pages/{substring-before(substring-after($exist:path, "/"), "/")}/{$exist:resource}.html" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql" />
        </view>
        <error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
(: Unterseiten 3. Ebene :)
else if (matches($exist:path, "^/[a-z-]+/[a-z-]+/[a-z-]+$")) then
    let $part1 := substring-before(substring-after($exist:path, "/"), "/")
    let $part2 := substring-before(substring-after(substring-after($exist:path, "/"), "/"), "/")
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/pages/{$part1}/{$part2}/{$exist:resource}.html" />
        <view>
            <forward url="{$exist:controller}/modules/view.xql" />
        </view>
        <error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
