
/*
* Push Changes to a script
*/
function PUSH(scriptName, filesObject, scriptId,newFile) {
  
  if(scriptId === "null"){
    if(!scriptName){
      throw new Error("You must specify a script Id or File Name");
    }else{
      if(newFile === "true"){
       Logger.log("try new file");
         var newScript = createNewProject(scriptName,JSON.parse(filesObject),DriveApp.getRootFolder().getId());
         scriptId = newScript.id; 
      }else{
        scriptId = getScriptId(scriptName);
      }
    }
  }
  
  
  if(scriptId !== "null"){
    scriptName = DriveApp.getFolderById(scriptId).getName();
  }
  
  if(newFile !== "true"){
    try{updateFilesinScript(scriptId, filesObject);}
    catch(e){throw Error(e)}
  }
  return "Written to: "+ scriptName +". File Id: "+ scriptId;
}


/*
* Download a script to local
*/
function GET(scriptName,scriptId){
  if(scriptId === "null"){
    if(!scriptName){
      throw new Error("You must specify a script Id or File Name");
    }else{
      scriptId = getScriptId(scriptName)
    }
  }
  try{var filesObject = fetchFilesFromScript(scriptId);}
  catch(e){return e}
  // add the fileId to the filesObject
  filesObject["fileId"] = scriptId;
  return JSON.stringify(filesObject);
  }




function getScriptId(scriptName){
  var files = DriveApp.searchFiles("mimeType='application/vnd.google-apps.script' AND title='"+scriptName+"'");;
  if(!files.hasNext()){
    throw new Error("No documents found by that name")
  }else{
    return files.next().getId();
  }
}



