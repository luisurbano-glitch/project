import { APP_CONFIG } from "./config.js";

const elements = {
  time: document.querySelector("#current-time"),
  date: document.querySelector("#current-date"),
  networkStatus: document.querySelector("#network-status"),
  terminalName: document.querySelector("#terminal-name"),
  employeeCode: document.querySelector("#employee-code"),
  continueButton: document.querySelector("#continue-button"),
  cameraButton: document.querySelector("#camera-button"),
  closeCamera: document.querySelector("#close-camera"),
  captureButton: document.querySelector("#capture-button"),
  cameraModal: document.querySelector("#camera-modal"),
  cameraPreview: document.querySelector("#camera-preview"),
  notification: document.querySelector("#notification"),
  notificationMessage: document.querySelector("#notification-message")
};

let cameraStream = null;

function updateClock() {
  const now = new Date();

  elements.time.textContent = now.toLocaleTimeString("pt-BR");
  elements.date.textContent = now.toLocaleDateString("pt-BR", {
    weekday: "long",
    day: "2-digit",
    month: "long",
    year: "numeric"
  });
}

function updateNetworkStatus() {
  const online = navigator.onLine;

  elements.networkStatus.classList.toggle("status-online", online);
  elements.networkStatus.classList.toggle("status-offline", !online);

  elements.networkStatus.innerHTML = online
    ? `<i data-lucide="wifi"></i><span>Online</span>`
    : `<i data-lucide="wifi-off"></i><span>Offline</span>`;

  window.lucide?.createIcons();
}

function showNotification(message) {
  elements.notificationMessage.textContent = message;
  elements.notification.classList.remove("hidden");

  window.clearTimeout(showNotification.timeout);

  showNotification.timeout = window.setTimeout(() => {
    elements.notification.classList.add("hidden");
  }, 4000);
}

async function openCamera() {
  if (!navigator.mediaDevices?.getUserMedia) {
    showNotification("A câmera não está disponível neste navegador.");
    return;
  }

  try {
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: "user",
        width: {
          ideal: 1280
        },
        height: {
          ideal: 720
        }
      },
      audio: false
    });

    elements.cameraPreview.srcObject = cameraStream;
    elements.cameraModal.classList.remove("hidden");
  } catch (error) {
    console.error(error);
    showNotification(
      "Não foi possível acessar a câmera. Verifique a permissão do navegador."
    );
  }
}

function closeCamera() {
  if (cameraStream) {
    cameraStream.getTracks().forEach((track) => track.stop());
    cameraStream = null;
  }

  elements.cameraPreview.srcObject = null;
  elements.cameraModal.classList.add("hidden");
}

function capturePhoto() {
  if (!cameraStream) {
    return;
  }

  const video = elements.cameraPreview;

  const canvas = document.createElement("canvas");
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;

  const context = canvas.getContext("2d");

  context.drawImage(
    video,
    0,
    0,
    canvas.width,
    canvas.height
  );

  const photoDataUrl = canvas.toDataURL("image/jpeg", 0.85);

  console.info("Foto capturada:", photoDataUrl.length);

  closeCamera();

  showNotification("Foto capturada com sucesso.");
}

function continueIdentification() {
  const employeeCode = elements.employeeCode.value.trim();

  if (!employeeCode) {
    showNotification("Informe sua matrícula para continuar.");
    elements.employeeCode.focus();
    return;
  }

  showNotification(
    `Funcionário ${employeeCode} identificado. A próxima etapa será a autenticação.`
  );
}

function setupEvents() {
  window.addEventListener("online", updateNetworkStatus);
  window.addEventListener("offline", updateNetworkStatus);

  elements.continueButton.addEventListener(
    "click",
    continueIdentification
  );

  elements.employeeCode.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      continueIdentification();
    }
  });

  elements.cameraButton.addEventListener("click", openCamera);
  elements.closeCamera.addEventListener("click", closeCamera);
  elements.captureButton.addEventListener("click", capturePhoto);

  elements.cameraModal.addEventListener("click", (event) => {
    if (event.target === elements.cameraModal) {
      closeCamera();
    }
  });
}

function initialize() {
  elements.terminalName.textContent = APP_CONFIG.terminal.name;

  updateClock();
  updateNetworkStatus();

  window.setInterval(updateClock, 1000);

  setupEvents();

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("./sw.js").catch((error) => {
      console.error("Falha ao registrar Service Worker:", error);
    });
  }

  window.lucide?.createIcons();
}

initialize();
