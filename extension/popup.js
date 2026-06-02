const sendBtn = document.getElementById('sendBtn');
const msgInput = document.getElementById('msgInput');
const logDiv = document.getElementById('log');

sendBtn.addEventListener('click', () => {
  const textToSend = msgInput.value;
  chrome.runtime.sendMessage({ type: "SEND_TO_HOST", payload: textToSend }, (response) => {
    logDiv.textContent = "Sending...";
  });
});

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === "FROM_HOST") {
    logDiv.textContent = "Echoed JSON: " + JSON.stringify(message.data);
  }
});

