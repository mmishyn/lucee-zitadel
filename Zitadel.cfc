component output="false" {

	public function init() hint="https://zitadel.com/docs" {
		variables.lockTimeout = 20;
		variables.sessionName = "zitadel_access_token";
		variables.config = {
			"client_id" 		= "",
			"client_secret" 	= "",
			"auth_url" 			= "/oauth/v2/authorize",
			"token_url" 		= "/oauth/v2/token",
			"redirect_url"		= "/callback.cfm",
			"userinfo_url"		= "/oidc/v1/userinfo",
			"logout_url"		= "/oidc/v1/end_session",
			"post_logout_url"	= "http://127.0.0.1/",
			"scope"				= "openid profile email"	
		}

		return this;
	}
	
	public boolean function isUserLoggedIn(){
		var local = {};

		try{

			 lock timeout=variables.lockTimeout scope="session" type="readonly" throwontimeout="true" { 
				if ( structKeyExists( session, variables.sessionName ) ){
					return true
				}            
			}

			

		}catch(any e){

		}

		return false;
	}

	public function login(){
		var local = {};

		local.state = getSessionState(  );

		local.uri = variables.config.auth_url & "?client_id=" & variables.config.client_id &"&response_type=code&scope="& URLEncodedFormat(variables.config.scope) &"&redirect_uri=" & URLEncodedFormat(variables.config.redirect_url) & "&state=" & local.state;

		location url=local.uri;
		abort;
	}

	public string function getSessionState(  ){

		try{

			lock timeout=variables.lockTimeout scope="session" type="readonly" throwontimeout="true" { 
				if ( structKeyExists( session, "cfid" ) ){
					return session[ "cfid" ];
				}            
			}

		}catch(any e){}

		return '';
	}

	public string function getAccessToken(){

		try{

			lock timeout=variables.lockTimeout scope="session" type="readonly" throwontimeout="true" { 
				if ( structKeyExists( session, variables.sessionName ) ){
					return session[variables.sessionName].access_token;
				}            
			}

		}catch(any e){

		}

		return '';
	}

	public function auth( required string code, required string state ){
		var local = {};

		local.httpService = new http( 
			method 		= "POST", 
			charset 	= "utf-8", 
			url 		= variables.config.token_url
		); 

		local.httpService.addParam( type = "formfield", name="grant_type", value="authorization_code" ); 
		local.httpService.addParam( type = "formfield", name="code", value=arguments.code ); 
		local.httpService.addParam( type = "formfield", name="redirect_uri", value=variables.config.redirect_url); 
		local.httpService.addParam( type = "formfield", name="client_id", value=variables.config.client_id); 
		local.httpService.addParam( type = "formfield", name="client_secret", value=variables.config.client_secret); 
		local.response = local.httpService.send().getPrefix(); 
		local.tokens = isJson(local.response.filecontent) ? deserializeJSON(local.response.filecontent) : {};

		if ( !structKeyExists(local.tokens, "access_token") ){
			login();
			abort;
		}

		local.access = {
			"access_token" 	= local.tokens.access_token,
			"id_token"		= local.tokens.id_token
		}

		lock timeout=variables.lockTimeout scope="session" type="exclusive" throwontimeout="true" { 
            session[variables.sessionName] = local.access;
        }


		return;
	}

	public struct function userInfo( ){
		var local = {};

		local.token = getAccessToken();

		if ( !len(local.token) ){
			return {};
		}
		local.httpService = new http( 
			method 		= "GET", 
			charset 	= "utf-8", 
			url 		= variables.config.userinfo_url
		); 
		
		local.httpService.addParam( name = "Authorization", type = "Header", value = "Bearer " &  local.token ); 
		local.httpService.addParam( name = "Content-Type", type = "Header", value = "application/json" ); 
		local.response = local.httpService.send().getPrefix(); 
		local.response.filecontent = isJson(local.response.filecontent) ? deserializeJSON(local.response.filecontent) : {};


		return local.response.filecontent;
	}

}