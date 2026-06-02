let nativePort = null;

function connectToNativeHost() {
  const hostName = "io.github.cpsdenis";
  nativePort = chrome.runtime.connectNative(hostName);

  nativePort.onMessage.addListener((messageFromCPlusPlus) => {
    console.log("Received from C++:", messageFromCPlusPlus);
    chrome.runtime.sendMessage({ type: "FROM_HOST", data: messageFromCPlusPlus });
  });

  nativePort.onDisconnect.addListener(() => {
    if (chrome.runtime.lastError) {
      const errmsg = "Disconnected from native host. \
          Native Messaging Error: " + chrome.runtime.lastError.message;
      console.error(errmsg);
      chrome.runtime.sendMessage({ type: "FROM_HOST", data: errmsg });
    } else {
      console.log("Port disconnected normally by app exit or garbage collection.");
    }
    nativePort = null;
  });
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "SEND_TO_HOST") {
    if (!nativePort) {
      connectToNativeHost();
    }
    
    nativePort.postMessage({ text: request.payload });
    sendResponse({ status: "Sent to C++ pipeline" });
  }
  return true; 
});

