<cfscript>
	try{

		param name="url.code" default="";
		param name="url.state" default="";

		
		local.zitadel = new Zitadel();

		
		if (url.state NEQ local.zitadel.getSessionState()) {
			writeOutput("Invalid state. Possible CSRF.");
			abort;
		}
		
		local.zitadel.auth(
			code = url.code,
			state = url.state
		);

		if ( local.zitadel.isUserLoggedIn() ){
			location url="/";
			
		}

		


	}catch(any e){

	}
</cfscript>
callback