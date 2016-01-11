import std.stdio;
import std.net.curl;
import std.json;
import std.process;
import std.file;
import std.datetime;
import std.c.stdlib;
import std.algorithm : sort, copy;
import std.array;
import std.getopt;
import std.conv;
import std.path;



// TODO: Ask to overwrite on GET
// TODO: dependancies(experimental)


string scriptFileName = "Untitled Script";
const string scriptInfoName = ".scriptInfo";
const string scriptConfigFileName = ".gasIO";

version(Debug)
	{
		const string tempDevFolder = "test";
	}else{
		const string tempDevFolder = ".";
	}

string fileId = "null"; // string on purpose;
string[] addExtensions;

string[] defaultExtensions = ["*.js","*.ccs","*.html","*.gs"];
bool newFile = false;
bool recursive = false;
bool getDependancies = false;




int main(string[] args){

	try{
		auto cmdOptions = getopt(args,"fileName|f","The name of the file to be opened or saved \n(default: push/Untitled Script  get/first script found with the given name )",&scriptFileName,
									  "fileId|i","The File Id of the script you want to get or push",&fileId,
									  "copy|c","Creates a copy of the script when you push to drive",&newFile,
									  "dependancies|d","(Experimental) Save the dependancies for this script in .gasFileInfo", &getDependancies,
									  "recurse|r","Recursively adds all subfolders of the current directory (default:false)",&recursive,
									  "addExt|a","Add extension to the list of defaults: gs, html, js, css. You can add as many as you need.",&addExtensions,
									  "push|p","Push the current directory to a script in Drive",&PUSH,									  
									  "get|g","Fetches a script and saves it locally",&GET,
									  "clearTokens|t","Deletes all stored OAuth tokens",&removeConfigFile);
		if (cmdOptions.helpWanted){
			defaultGetoptPrinter("\ngasIO options",
								 cmdOptions.options);
			return 0;
		}

	}
	catch(std.file.FileException e){
		version(Debug){
			writeln(to!string(e));	
		}else{
		writeln("Error writing to file.");
		return 1;
	}
	}

	catch(std.getopt.GetOptException e){
		version(Debug){
			writeln(to!string(e));	
		}else{
		writeln("Invalid arguments use --help for options.");
		return 1;
	}
	}

	catch(Exception e){
		version(Debug){
			writeln(to!string(e));	
		}else{
			writeln("Something broke. Possibly " ~ e.msg);	
		}
		return 1;
	}
	return 0;
}

// get Full Qualified File Name of the config file
char[] getFQFileName(){
	string homePathVer;	
    version (Windows){homePathVer = "APPDATA";}
	version(Posix){homePathVer = "HOME";}
	char[] homePath = cast(char[])environment[homePathVer];
    return homePath ~ "/"~scriptConfigFileName;

}

void removeConfigFile(){
	char[] filename = getFQFileName();
	if (exists(filename)!=0){
		remove(filename);
	}
	std.c.stdlib.exit(-1);
}

string loadConfigFile(){
    string cId = "402007435673-9csca56cp695iqes48rgubktp1o0eq63.apps.googleusercontent.com"; //TODO clientID
	string cSecret = "Id3fezbJOIjH8OhbHFSAoqnQ"; //TODO clientSecret Go ahead and use these Auth creds. Can't guarantee if many people are useing them the free quota won't run out. 
	string redirect_uri = "urn:ietf:wg:oauth:2.0:oob";	// Web Auth
	string authUrl = "https://accounts.google.com/o/oauth2/v2/auth";
	string scopes = "https://www.googleapis.com/auth/drive.apps.readonly https://www.googleapis.com/auth/script.external_request https://www.googleapis.com/auth/drive.scripts https://www.googleapis.com/auth/drive"; 
    char[]  filename  = getFQFileName();
    JSONValue oTokens;
	string oAuthToken;

	if (exists(filename)!=0) { //The config file exists
        char[] tokenFile = cast(char[])read(filename);  //Read the stored token info
		oTokens = parseJSON(tokenFile);
		bool isTokenValid = checkOAToken(oTokens.object["access_token"].str());

		if(!isTokenValid){ // if it insn't a valid token (ie it has expired). Try to get a new one.
			auto postData = "client_id="~cId~
				"&client_secret="~cSecret~
				"&refresh_token=" ~ oTokens["refresh_token"].str() ~ 
				"&grant_type=refresh_token";
	        oAuthToken = getOAToken(postData, filename, oTokens["refresh_token"].str());
		}else{
			oAuthToken = oTokens["access_token"].str();
		}
	} else { // There is no config file. Prompt the user the authorize this client.
		string url = authUrl ~ "?" ~ "scope=" ~ scopes ~ "&redirect_uri=" ~ redirect_uri ~ "&response_type=code&client_id=" ~ cId;
		writef("Please post this URL in your Browser.\n\n" ~ url ~ "\n\nEnter response code here:");
		string oCode = readln();
		auto postData = "code="~oCode~"&client_id="~cId~"&client_secret="~cSecret~"&redirect_uri=" ~ redirect_uri ~ "&grant_type=authorization_code";
	    oAuthToken = getOAToken(postData, filename, null);
	}
	return oAuthToken;
}


// Checks to see if an OAuth2 token is valid
bool checkOAToken(string token){
    string url = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token="~token;
	auto http = HTTP(url);
	string results;
	http.onReceive = (ubyte[] data){	
		results ~= cast(string)data;
		return data.length;
	};
	http.perform();

	JSONValue tokenResults = parseJSON(results);
	if("error" in tokenResults){
		return false;
	}

	if(tokenResults.object["expires_in"].integer > 60){
		return true;
	}else{
		return false;
	}
}

// This will request a new token from Google. Takes either the Auth Code or the Refresh token and gets a valid OAuth2 token.
// Saves the token info to the config file.
string getOAToken(string postData, char[] fileName, string refreshToken){ //pass the refresh token as this isnt returned. Leave null for intial request.
 	string oAuthToken;

	string requestUrl = "https://www.googleapis.com/oauth2/v4/token";
	//exchange code for token
	auto http = HTTP(requestUrl);
	http.setPostData(postData, "application/x-www-form-urlencoded");
	http.onReceive = (ubyte[] data)
	{	
		JSONValue res = parseJSON(cast(string)data);
		if("error" in res){
			writeln("Invalid Code\n");
			std.c.stdlib.exit(-1);  // the memories leak?
		}else{
			if(refreshToken != null){
				res.object["refresh_token"] = refreshToken;
			}
			std.file.write(fileName,res.toString());
			oAuthToken = res["access_token"].str();
			
		}
		return data.length;
	};
	http.perform(); 

	return oAuthToken;
}


// This turns a directory structure into a file object used by the GAS import / export API
JSONValue makeFilesObject(){
   
   //build the string of file extensions to add
   string searchExtensions = "{";
   foreach(ext; defaultExtensions){
   		searchExtensions ~= "," ~ ext;
    }
    foreach(ext; addExtensions){
   		searchExtensions ~= "," ~ ext;
    }
    searchExtensions ~="}";
   
   
   auto recurseMode = (recursive)?SpanMode.breadth:SpanMode.shallow;
   auto dirFiles = dirEntries("./",searchExtensions,recurseMode); //directory files
   
   string[string][] filesArray; // Array to hold the fileObjs
   foreach(file; dirFiles){
   	string shortName = file.name[2..$]; // remove the initial './';
   	if(std.path.extension(file.name) == ".gs"){ // strip off extensions the IDE pushes on
   		shortName = shortName[0..$-3];
   	}		
if(std.path.extension(file.name) == ".html"){  // strip off extensions the IDE pushes on
   		shortName = shortName[0..$-5];
   	}
bool updateScript = (exists(scriptInfoName) && !newFile);

string[string] filesData;
if (updateScript){
	
	JSONValue tmpJSON = parseJSON(readText(scriptInfoName));
	auto allFilesData = tmpJSON.object["files"].array();
	for(int i = 0; i < allFilesData.length; i++){
		filesData[allFilesData[i].object["name"].str()] = allFilesData[i].object["id"].str();
	}
}

   	string[string] fileObj;     // The object to hold file info {name,id?,type,source}
    writeln("Adding: " ~ file.name);
    try{
    	auto thisFile = readText(file.name);
    	if(updateScript){
 			try{fileObj["id"] = filesData[shortName];}
 			catch(core.exception.RangeError e){
 				// do nada as this is probably a new file and doesn't have an id. I could do a (param in obj) check but meh..
 			}	   		
    	}
    	fileObj["name"] = shortName;
    	fileObj["type"] = (std.path.extension(file.name) == ".gs")?"server_js":"html"; // app script has only two extensions
    	fileObj["source"] = thisFile;
    	filesArray ~= fileObj;
    }
    catch(Exception e){writeln("Error reading file:" ~ file.name);}
	}
	JSONValue gasObject = ["files":filesArray];
   return gasObject;

}



// Push files to a Apps Script
void PUSH(){
	string oAuthToken = loadConfigFile();

	if(newFile && fileId != "null"){
		throw new Exception("Can't copy this script to an existing script. Please use --newFile instead of --fileId");
	}
	
	if(exists(scriptInfoName)){
		auto scriptInfo = readText(scriptInfoName);
		fileId = parseJSON(scriptInfo).object["fileId"].str();
	}

	writeln("Saving Script...");

    string cApi_Id = "MA9m6em62bf-mLIJKvQgTekMLm9v2IJHf"; //TODO execution API ID	
	string fetchUrl = "https://script.googleapis.com/v1/scripts/"~ cApi_Id ~":run";

	string[] params = [scriptFileName];      //Param 1
	JSONValue filesObj = makeFilesObject();

	params ~= to!string(filesObj);           //Param 2
	
	if(fileId != null){                      //Param 3
		params ~= fileId;
	}else{
		params ~= "null";
	}

	params ~= to!string(newFile);             //Param 4

	JSONValue postData =  ["function":"PUSH", "devMode":"false"];
	
	postData.object["parameters"] = params;

	auto http = HTTP(fetchUrl);	
	http.setPostData(postData.toString(), "application/json");	
	http.addRequestHeader("Authorization", "Bearer "~oAuthToken);

    string retVal;
    http.onReceive = (ubyte[] data){
    	retVal ~= cast(string)data;  
		return data.length;
	};
	writeln("Creating script on drive");
    http.perform();
    JSONValue res = parseJSON(retVal);
    if("error" in res){
			try{writeln(res["error"].object["details"].array[0].object["errorMessage"].str());}
			catch(Exception e){writeln(retVal);}
		}
		
		if("response" in res){
			writeln("done");
			try{writeln(res["response"].object["result"].str());}
			catch(Exception e){writeln(retVal);}
    	}
 }


// get files from an Apps Script
void GET(){
	bool overWriteAll = false;
	string oAuthToken = loadConfigFile();
	writeln("Getting Script...");

    string cApi_Id = "MA9m6em62bf-mLIJKvQgTekMLm9v2IJHf"; //TODO execution API ID	
	string fetchUrl = "https://script.googleapis.com/v1/scripts/"~ cApi_Id ~":run";

	string[] params = [scriptFileName];
	if(fileId != null){
		params ~= fileId;
	}else{
		params ~= "null";
	}

	JSONValue postData =  ["function":"GET", "devMode":"false"];
	
	postData.object["parameters"] = params;
	auto http = HTTP(fetchUrl);	

	http.setPostData(postData.toString(), "application/json");	
	http.addRequestHeader("Authorization", "Bearer "~oAuthToken);

    string retVal;
	http.onReceive = (ubyte[] data)
	{	retVal ~= cast(string)data;
		return data.length;
	};
	http.perform();

    JSONValue res = parseJSON(retVal);

    if("error" in res){
			try{writeln(res["error"].object["details"].array[0].object["errorMessage"].str());}
			catch(Throwable e){writeln(e);writeln(res);}
		}
		if("response" in res){
			writeln("done");
			JSONValue scriptFile = parseJSON(res["response"].object["result"].str());

			JSONValue metaData = parseJSON(res["response"].object["result"].str()); //not sure how to copy object. used the Javascript parse trick.
			
			foreach(JSONValue mfo; metaData.object["files"].array()){ // just need the headerinfo
				mfo.object.remove("source");
			}
			if(!exists(dirName(tempDevFolder ~ "/" ~  scriptInfoName))){
				mkdir(dirName(tempDevFolder ~ "/" ~  scriptInfoName));//possible I'll put a path on the scriptInfo}
			}
			std.file.write(tempDevFolder ~ "/" ~  scriptInfoName,to!string(metaData));
			foreach(JSONValue fo; scriptFile.object["files"].array()){
			    string extension;
			    if(!exists(dirName(tempDevFolder ~ "/"~fo.object["name"].str()))){
			    	mkdirRecurse(dirName(tempDevFolder ~ "/"~fo.object["name"].str()));
				}
			    switch(fo.object["type"].str()){ // The export api strips the file extensions so you have to put them back on.
			    	case "server_js":
			    	extension = ".gs";
			    	break;
			    	
			    	case "html":
			    	 if(std.path.extension(fo.object["name"].str()) is null){ // if there is no extension with html type then it is .html
			    	 	extension = ".html";
			    	 }
					 break;
			    	 default:
			    }
				std.file.write(tempDevFolder ~ "/" ~ fo.object["name"].str() ~ extension,fo.object["source"].str());
			}
		}
}
