<cfscript>
	
	local.zitadel = new Zitadel();
	
	if ( !local.zitadel.isUserLoggedIn() ){
		local.zitadel.login();
	}

	local.userInfo = local.zitadel.userInfo();

	dump(
		var = local.userInfo,
		label = 'User Info'
	);
</cfscript>

