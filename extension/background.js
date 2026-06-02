let nativePort = null;

function connectToNativeHost() {
  const hostName = "io.github.cpsdenis";
  nativePort = chrome.runtime.connectNative(hostName);

  nativePort.onMessage.addListener((messageFromCPlusPlus) => {
    console.log("Received from C++:", messageFromCPlusPlus);
    chrome.runtime.sendMessage({ type: "FROM_HOST", data: messageFromCPlusPlus });
  });

  nativePort.onDisconnect.addListener(() => {
    var errmsg = "Disconnected from native host."
    if (chrome.runtime.lastError) {
      errmsg += " Native Messaging Error: " + chrome.runtime.lastError.message;
    } else if (nativePort.error) {
      errmsg += " Native disconnected due to an error: " + nativePort.error;
    } else {
      errmsg += " Port disconnected normally by app exit or garbage collection.";
    }
    chrome.runtime.sendMessage({ type: "FROM_HOST", data: errmsg });
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

