const toggleSwitch = document.getElementById("theme-toggle");
const body = document.body;

// Load theme based on user's previous choice if available
const currentTheme = localStorage.getItem("theme") || "light-mode";
body.classList.add(currentTheme);

// Set the toggle position based on current theme
if (currentTheme === "dark-mode") {
  toggleSwitch.checked = true;
}

toggleSwitch.addEventListener("change", function () {
  if (toggleSwitch.checked) {
    body.classList.replace("light-mode", "dark-mode");
    localStorage.setItem("theme", "dark-mode");
  } else {
    body.classList.replace("dark-mode", "light-mode");
    localStorage.setItem("theme", "light-mode");
  }
});

function copyToClipboard() {
  const codeBlock = document.querySelector(".terminal-body code");
  const text = codeBlock.textContent;
  navigator.clipboard.writeText(text);
}
