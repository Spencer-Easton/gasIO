function PUSH(scriptName, filesObject, scriptId,newFile){
  if(newFile === "true"){ //were copying/creating
    if(scriptName === ""){
      throw new Error("You must specify a File Name");
    }else{
      var newScript = createNewProject(scriptName,JSON.parse(filesObject),DriveApp.getRootFolder().getId());
      scriptId = newScript.id;   
    }
  }else{ // not a new file we're updating
    if(scriptId === "null"){
      if(scriptName === ""){
        throw new Error("You must specify a File Name or File Id");
      }
      scriptId = getScriptId(scriptName); 
    }else{      
       scriptName = DriveApp.getFolderById(scriptId).getName();      
      //we now have the script Id and Script Name
      try{updateFilesinScript(scriptId, filesObject);}
      catch(e){throw Error(e)}
    }
  }
   var returnString =  "Written to: "+ scriptName +". File Id: "+ scriptId;
   if(newFile === "true"){
     returnString += '.\nTo switch to your new projet locally use the command:\ngasIO --syncHeader --fileId="'+scriptId+'"';
   }
   return returnString;
  
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



