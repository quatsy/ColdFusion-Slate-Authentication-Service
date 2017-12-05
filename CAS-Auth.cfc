<cfcomponent hint="Slate Central Authentication Service (CAS) integration" output="false">

	<!--- Built by Jason Quatrino on 8/25/2017 based on Slate CAS Authentication Documentation found at:

		https://technolutions.zendesk.com/hc/en-us/articles/216174348-Slate-authentication-service#article-comments

	--->

	<cfset slateEndpoint = "https://Your.SlateDomainName.here/" />
	<cfset serviceURI = "https://#cgi.server_name#" />

	<cfset serviceURI &= cgi.SCRIPT_NAME />

	<cffunction name="authUser" returntype="struct" output="false">
		<cfargument name="uri" type="string" required="false" default="" hint="URI of the service you'd like to redirect to after authentication." />

		<cfif Len(arguments.uri) EQ 0>
			<cfset arguments.uri = serviceURI />
		</cfif>

		<cfset local.results = {} />
		<cfset local.results.msg = "" />

		<cfif structKeyExists(url,"ticket") AND Len(url.ticket)>
			<cfset local.results = retrieveCredentials(ticket=url.ticket,uri=arguments.uri) />
		<cfelse>
			<cfif IsValid("url",arguments.uri)>
				<cflocation url="#slateEndpoint#/account/cas/login?service=#arguments.uri#" addtoken="false" />
			<cfelse>
				<cfset local.results.msg &= " AuthUser ERROR: Bad URI provided." />
			</cfif>
		</cfif>

		<cfreturn local.results />
	</cffunction>

	<cffunction name="retrieveCredentials" returntype="struct" output="false">
		<cfargument name="ticket" type="string" required="true" />
		<cfargument name="uri" type="string" required="false" />

		<cfset local.results = {} />
		<cfset local.results.msg = "" />
		<cfset local.results.isAuth = false />
		<cfset local.results.slateData = {} />

		<cfif Len(arguments.uri) EQ 0>
			<cfset arguments.uri = serviceURI />
		</cfif>

		<cfif Len(url.ticket)>
			<cftry>
				<cfhttp url="#slateEndpoint#account/cas/serviceValidate" method="get" result="local.httpResult">
					<cfhttpparam type="url" name="service" value="#arguments.uri#" />
					<cfhttpparam type="url" name="ticket" value="#arguments.ticket#" />
				</cfhttp>

				<cfcatch type="any">
					<cfset local.results.msg &= "AuthUser HTTP ERROR: #cfcatch.message#" />
					<cfreturn results />
				</cfcatch>
			</cftry>

			<cfif structKeyExists(local.httpResult,"errordetail") AND Len(local.httpResult.errordetail)>
				<cfset local.results.msg &= "retrieveCredentials HTTP ERROR: #local.httpResult.errordetail#" />
			<cfelse>
				<cfif structKeyExists(local.httpResult,"filecontent") AND Len(local.httpResult.filecontent)>
					<cfif isValid("xml",local.httpResult.filecontent)>
						<!--- parse results --->
						<cfset local.results.slateData = parseSlateXML(XMLParse(local.httpResult.filecontent)) />
						
						<!--- check whether authenticated properly --->
						<cfset local.results.isAuth = isSuccessfulLogin(local.results.slateData) />

						<cfif structKeyExists(local.results.slateData,"cas:AuthenticationFailure")>
							<cfset local.results.msg &= local.results.slateData["cas:AuthenticationFailure"] />
						</cfif>
					<cfelse>
						<cfset local.results.msg &= " retrieveCredentials File Content ERROR: Invalid XML." />
					</cfif>
				<cfelse>
					<cfset local.results.msg &= " retrieveCredentials File Content ERROR: Unexpected result." />
				</cfif>
			</cfif>
		<cfelse>
			<cfset local.results.msg &= " retrieveCredentials ERROR: ticket not provided." />
		</cfif>

		<cfreturn local.results />
	</cffunction>

	<cffunction name="logout" output="false">
		<cfhttp url="#slateEndpoint#account/cas/logout" method="get" result="local.httpResult">
		</cfhttp>
	</cffunction>

	<cffunction name="parseSlateXML" returntype="struct" output="false">
		<cfargument name="slateXML" type="xml" required="true" />

		<cfset local.slateResults = {} />
		
		<cfset local.resultNodes = arguments.slateXML.XmlRoot />

		<cfif structKeyExists(local.resultNodes,"XmlChildren")>
			<cfset local.slateResults = xmlChildrenParser(local.resultNodes.XmlChildren) />
		</cfif>

		<cfreturn local.slateResults />
	</cffunction>

	<cffunction name="xmlChildrenParser" returntype="struct" output="false">
		<cfargument name="xmldata" type="xml" required="true">

		<cfset local.returnStruct = {} />

		<cfif isValid("array",arguments.xmldata)>
			<cfloop array="#arguments.xmldata#" item="local.child">
				<cfset local.returnStruct[local.child.xmlName] = local.child.xmlText />

				<cfif structKeyExists(local.child,"XmlChildren") AND ArrayLen(local.child.XmlChildren)>
					<cfset StructAppend(local.returnStruct,xmlChildrenParser(local.child.XmlChildren)) />
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn local.returnStruct />
	</cffunction>

	<cffunction name="isSuccessfulLogin" returntype="boolean" output="false">
		<cfargument name="slateConfig" type="struct" required="true" />

		<cfreturn (structKeyExists(arguments.slateConfig,"cas:AuthenticationSuccess") ? true : false) />
	</cffunction>
</cfcomponent>
