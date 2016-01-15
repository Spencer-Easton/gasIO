#gasIO is a small command line tool for importing and exporting Apps Script from Google Drive.  
  
The source for the client can be found in the src/client folder.  
It can be compiled with the dmd compiler found at [http://dlang.org](http://dlang.org/download.html).  
To compile use `dmd gasIO.d`. 
This has been tested on windows 7 x64, OSX 10.10, and debian 8
######If you are running on windows you need to make sure you have cURL installed as libcurl.dll is required. Also your terminal client might insert spaces at line breaks when you copy the Autorization URL from the terminal window.  

I have purposfully left OAuth Client credentials in the source code. These are safe to use, but if you are worried about giving access to a public API you can publish the script in the src/server folder as an executable API and generate your own credentials. If you are interested in this tool I'm going to assume you know how to do this. A search for `TODO` in gasIO.d will show the lines where these values go.

#####gasIO options  
-f     --fileName The name of the file to be opened or saved   
(default: push/Untitled Script  get/first script found with the given name )  
-i       --fileId The File Id of the script you want to get or push  
-c         --copy Creates a copy of the script when you push to drive  
-d --dependancies (Experimental) Save the dependancies for this script in .gasFileInfo  
-r      --recurse Recursively adds all subfolders of the current directory (default:false)  
-a       --addExt Add extension to the list of defaults: gs, html, js, css. You can add as many as you need.  
-p         --push Push the current directory to a script in Drive  
-g          --get Fetches a script and saves it locally  
-s   --syncHeader Resyncs .scriptInfo with the script project.  
-t  --clearTokens Deletes all stored OAuth tokens  
-h         --help This help information.  
  
#####Examples  

    //Download a project to your local machine.  
    //Get the first script with the matching file name
    gasIO --get --fileName="myImportantScript"  //or
    gasIO -g -f"myImportantScript"  
  
    //Get a script by ID  
    gasIO --get --fileId="1J7BFyyuCXyIXz0faFSLIkgcl_oCpgeRUXB7_p1Z-lPh2Mb"  //or  
    gasIO -g -i"1J7BFyyuCXyIXz0faFSLIkgcl_oCpgeRUXB7_p1Z-lPh2Mb"  
  
    //Upload a project to Drive  
    //Push a previously imported script back to Drive.  
    gasIO --push

    //Push a new project or copy local project on Drive 
    // --copy is also for a new project for now. I might change that later.
    gasIO --push --fileName="myNewProject"  --copy  //or   
    gasIO -p -f"myNewProject" -c  
  
    //Push a project with all subfolders to Drive  
    //Add files of a non-default extension to the project
    gasIO --push --recurse --addExt="\*.md"  //or  
    gasIO -p -r -a"\*.md"  
