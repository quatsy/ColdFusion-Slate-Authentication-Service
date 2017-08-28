# ColdFusion-Slate-Authentication-Service
Provides ColdFusion connectivity to Slate Authentication Service using CAS

Built by Jason Quatrino for Hamilton College on 8/28/2017 based on Slate CAS Authentication Documentation found at:

https://technolutions.zendesk.com/hc/en-us/articles/216174348-Slate-authentication-service#article-comments

Instructions:

1. Save CAS-auth.cfc to your working copy.
2. Open file and update "slateEndpoint" variable to use your secure (SSL) Slate domain, e.g.: "https://admission.mycollege.edu/". Include trailing slash.
3. Update "cfc.path.to.auth" below to your CFC path.
4. Authenticate as follows:

<cfset request.slateCASAuth = createObject("component","cfc.path.to.auth").authUser() />

authUser() returns a ColdFusion Struct containing "isAuth" boolean, "msg" string, and raw "slateData" results struct containing metadata about the authenticated user. Take a look at the results by dumping them:

<cfdump var="#request.slateCASAuth#">

Enjoy!
