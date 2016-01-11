/*********************************************
*
*
*
*
*********************************************/
var GASFileType = {
  "GS":"server_js",
  "HTML":"html"
}


/*********************************************
*
*
*
* 
*********************************************/
function createNewProject(projectName,content,folderId){
  
  var emptyProject = 
      { "files": 
       [
         {
           "name": "code",
           "type": "server_js",
           "source": "function myFunction(){\n}"
         }
       ]
      };
  
  
  var newProject = {
    title:projectName,
    mimeType: 'application/vnd.google-apps.script+json'
  };
  
  if(folderId != null){
    newProject.parents=
      [
        {
          "kind": "drive#fileLink",
          "id": folderId
        }
      ];
  }
  
  var newFile;
  
  if(content == null){newFile = Drive.Files.insert(newProject,Utilities.newBlob(JSON.stringify(emptyProject),"application/vnd.google-apps.script+json" ),{"convert":true});}
  else{newFile = Drive.Files.insert(newProject, Utilities.newBlob(JSON.stringify(content),"application/vnd.google-apps.script+json" ),{"convert":true} );}
  
  
  return newFile
}



/*********************************************
*
*
*
*
*********************************************/
function fetchFilesFromScript(scriptID){
  
  var retVal;
  var url = "https://script.google.com/feeds/download/export?id="+ scriptID +"&format=json";
  var parameters = { method : 'get',
                    headers : {'Authorization': 'Bearer '+ScriptApp.getOAuthToken()},
                    contentType:'application/json',                    
                    muteHttpExceptions:true};
  
  var response = UrlFetchApp.fetch(url,parameters);
  if(response.getResponseCode() != 200){
    throw new Error("Error Fetching Script");
  }else{
    return JSON.parse(response.getContentText());
  }
  
}

/*********************************************
*
*
*
*
*********************************************/
function fetchFileHeadersFromScript(scriptID){
  var headers = fetchFilesFromScript(scriptID);
  for(var i in headers.files){   
    delete headers.files[i].source;
  }
  return headers;
}


/*********************************************
*
*
*
*
*********************************************/
function addFiletoScript(scriptId, fileName, fileType, source){
  
  var scriptFiles = fetchFilesFromScript(scriptId);
  
  for(var i in scriptFiles.files){
    if((scriptFiles.files[i].name == fileName) && (scriptFiles.files[i].type == fileType)){throw new Error("Duplicate file name"); /*fileName = "Duplicate "+ fileName*/ };
  }
  scriptFiles.files.push({"name":fileName,"type":fileType,"source":source});
  
  var content = content || ""
  var url = "https://www.googleapis.com/upload/drive/v2/files/"+scriptId;
  var parameters = { method : 'PUT',
                    headers : {'Authorization': 'Bearer '+ ScriptApp.getOAuthToken()},
                    payload : JSON.stringify(scriptFiles),
                    contentType:'application/vnd.google-apps.script+json',                    
                    muteHttpExceptions:true};
  
  var response = UrlFetchApp.fetch(url,parameters);
  if(response.getResponseCode() != 200){
    throw new Error("Error Creating File");
  }else{
    return fetchFilesFromScript(scriptId);
  }
  
}

/*********************************************
*
*
*
*
*********************************************/
function removeFileInScript(scriptId, fileId){
  
  
  var scriptFiles = fetchFilesFromScript(scriptId);
  
  for(var i in scriptFiles.files){
    if((scriptFiles.files[i].id == fileId)){
      scriptFiles.files.splice(i,1);
    }
    
  }
  var url = "https://www.googleapis.com/upload/drive/v2/files/"+scriptId;
  var parameters = { method : 'PUT',
                    headers : {'Authorization': 'Bearer '+ ScriptApp.getOAuthToken()},
                    payload : JSON.stringify(scriptFiles),
                    contentType:'application/vnd.google-apps.script+json',                    
                    muteHttpExceptions:true};
  
  var response = UrlFetchApp.fetch(url,parameters);
  if(response.getResponseCode() != 200){
    throw new Error("Error deleting file");
  }else{
    return fetchFilesFromScript(scriptId);
  }
}



/*********************************************
*
*
*
*
*********************************************/
function removeAllFilesInScript(scriptId){
  var emptyProject = {"files":[]};
   var url = "https://www.googleapis.com/upload/drive/v2/files/"+scriptId;
  var parameters = { method : 'PUT',
                    headers : {'Authorization': 'Bearer '+ ScriptApp.getOAuthToken()},
                    payload : JSON.stringify(emptyProject),
                    contentType:'application/vnd.google-apps.script+json',                    
                    muteHttpExceptions:true};
  
  var response = UrlFetchApp.fetch(url,parameters);
  if(response.getResponseCode() != 200){
    throw new Error("Error deleting files: "+ response.getContentText());
  }else{
    return true;
  }
  
}


/*********************************************
*
*
*
*
*********************************************/
function updateFilesinScript(scriptId, filesObject){
  var url = "https://www.googleapis.com/upload/drive/v2/files/"+scriptId;
  var parameters = { method : 'PUT',
                    headers : {'Authorization': 'Bearer '+ ScriptApp.getOAuthToken()},
                    payload : filesObject,
                    contentType:'application/vnd.google-apps.script+json',                    
                    muteHttpExceptions:true};
  
  var response = UrlFetchApp.fetch(url,parameters); 
  if(response.getResponseCode() != 200){
    throw new Error('Error updating files:' + filesObject);
  }else{
    return fetchFilesFromScript(scriptId);
  }
}


/*********************************************
*fileObject {id,name:,type:,source:}
*********************************************/
function updateFileinScript(scriptId, fileObject){
  
  var scriptFiles = fetchFilesFromScript(scriptId);
  
  for(var i in scriptFiles.files){
    if((scriptFiles.files[i].id == fileObject.id)){
      scriptFiles.files[i] = fileObject;
    }
    
  }
  
  return updateFilesinScript(scriptId,scriptFiles)
  
}

/*********************************************
*fileObject {id,name:,type:,source:}
*********************************************/
function updateFileNameinScript(scriptId,fileId,newName){
  
  var scriptFiles = fetchFilesFromScript(scriptId);
  
  for(var i in scriptFiles.files){
    if((scriptFiles.files[i].id == fileId)){
      scriptFiles.files[i].name = newName;
    }
    
  }
  
  return updateFilesinScript(scriptId,scriptFiles)
  
}

/*********************************************
*fileObject {id,name:,type:,source:}
*********************************************/
function updateFileSourceinScript(scriptId,fileId,newSource){
  
  var scriptFiles = fetchFilesFromScript(scriptId);
  
  for(var i in scriptFiles.files){
    if((scriptFiles.files[i].id == fileId)){
      scriptFiles.files[i].source = newSource;
    }
    
  }
  
  return updateFilesinScript(scriptId,scriptFiles)
  
}

