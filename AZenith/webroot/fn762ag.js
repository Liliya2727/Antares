function e(e) {
  return e && e.__esModule ? e.default : e;
}

var t = globalThis,
  n = {},
  a = {},
  o = t.parcelRequirefbde;

if (null == o) {
  o = function (e) {
    if (e in n) return n[e].exports;
    if (e in a) {
      var t = a[e];
      delete a[e];
      var o = { id: e, exports: {} };
      n[e] = o;
      t.call(o.exports, o, o.exports);
      return o.exports;
    }
    var i = Error("Cannot find module '" + e + "'");
    throw ((i.code = "MODULE_NOT_FOUND"), i);
  };

  o.register = function (e, t) {
    a[e] = t;
  };

  t.parcelRequirefbde = o;
}

(0, o.register)("27Lyk", function (e, t) {
  Object.defineProperty(e.exports, "register", {
    get: () => n,
    set: (e) => (n = e),
    enumerable: !0,
    configurable: !0,
  });

  var n,
    a = new Map;

  n = function (e, t) {
    for (var n = 0; n < t.length - 1; n += 2)
      a.set(t[n], { baseUrl: e, path: t[n + 1] });
  };
});

o("27Lyk").register(
  new URL("", import.meta.url).toString(),
  JSON.parse('["gvBVN","function.js","avatar.webp","banner.webp","jkrgM","48MX7"]')
);

let i = 0;

function executeCommand(e, t) {
  return void 0 === t && (t = {}),
    new Promise((n, a) => {
      let o = `exec_callback_${Date.now()}_${i++}`;

      function c(e) {
        delete window[e];
      }

      window[o] = (e, t, a) => {
        n({ errno: e, stdout: t, stderr: a }), c(o);
      };

      try {
        ksu.exec(e, JSON.stringify(t), o);
      } catch (e) {
        a(e), c(o);
      }
    });
}


function EventEmitter() {
  this.listeners = {};
}

const randomMessages = [
  "Are you ready to be carried? Yeah? Me neither.",
  "First blood! Oh wait… that was you. My bad.",
  "Joy is the strongest Jungler in the world!.",
  "Wanna be Mythic? Start by uninstalling TikTok first.",
  "Turtle has spawned! Too bad your team is still Ganking MM in Goldlane.",
  "Retreat! Chang'e is splitting push, uh.. Good luck, I guess.",
  "Your skills are impressive… if this was a bot match.",
  "Report our jungler? Nah, report your decision-making first.",
  "Our game in lose position? Nah i'd win.",
  "A wise man once said: 'It’s just a game' – then broke your phone.",
  "ML or RL? Either way, you’ll still failing.",
  "Your rank doesn’t define you… but it does explain a lot.",
  "Victory or defeat, one thing is certain: there was at least one Poke in solo rank.",
  "Your Jungler is under attack and your roamer still in the bottom with MM.",
  "Kairiiiiii!!!!.",
  "Your PING is like your KDA—unstable.",
  "Getting MVP in a losing game feels like winning at life… almost.",
  "Your Jungler is struggling? Just steal their farm. That’ll definitely help.",
];

function showRandomMessage() {
  const messageElement = document.getElementById("msg");
  const randomIndex = Math.floor(Math.random() * randomMessages.length);
  const message = randomMessages[randomIndex];
  messageElement.textContent = message;
}

window.onload = showRandomMessage;

function Process() {
  this.listeners = {};
  this.stdin = new EventEmitter();
  this.stdout = new EventEmitter();
  this.stderr = new EventEmitter();
}

function showToast(message) {
  ksu.toast(message);
}

EventEmitter.prototype.on = function (event, listener) {
  this.listeners[event] || (this.listeners[event] = []);
  this.listeners[event].push(listener);
};

EventEmitter.prototype.emit = function (event, ...args) {
  this.listeners[event] &&
    this.listeners[event].forEach((listener) => listener(...args));
};

Process.prototype.on = function (event, listener) {
  this.listeners[event] || (this.listeners[event] = []);
  this.listeners[event].push(listener);
};

Process.prototype.emit = function (event, ...args) {
  this.listeners[event] &&
    this.listeners[event].forEach((listener) => listener(...args));
};

var u = {};

async function checkModuleVersion() {
  try {
    let { errno, stdout } = await executeCommand(
      'grep "version=" /data/adb/modules/AZenith/module.prop | awk -F\'=\' \'{print $2}\''
    );
    if (errno === 0) {
      document.getElementById("moduleVer").textContent = stdout.trim();
    }
  } catch (error) {
    console.error("Failed to check module version:", error);
  }
}
async function checkServiceStatus() {
  let { errno, stdout } = await executeCommand("pgrep -f AZenith");
  if (errno === 0) {
    let statusElement = document.getElementById("serviceStatus");
    if (stdout.trim() !== "0") {
      statusElement.textContent = "Zenithed⚡";
      document.getElementById("servicePID").textContent = "Service PID: " + stdout.trim();
    } else {
      statusElement.textContent = "Suspended💤";
      document.getElementById("servicePID").textContent = "Service PID: null";
    }
  }
}

async function checkVoltOptStatus() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/VoltOpt");
  if (errno === 0) {
    document.getElementById("VoltOpt").checked = stdout.trim() === "1";
  }
}

async function setVoltOptStatus(enabled) {
  showToast("Settings Applied");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/VoltOpt" : "echo 0 >/data/AZenith/VoltOpt");
}

async function checkDND() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/dnd");
  if (errno === 0) {
    document.getElementById("DoNoDis").checked = stdout.trim() === "1";
  }
}

async function setDND(enabled) {
  showToast("DND when game");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/dnd" : "echo 0 >/data/AZenith/dnd");
}

async function checkBypassChargeStatus() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/bypass_charge");
  if (errno === 0) {
    document.getElementById("Zepass").checked = stdout.trim() === "1";
  }
}

async function setBypassChargeStatus(enabled) {
  showToast("Settings Applied");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/bypass_charge" : "echo 0 >/data/AZenith/bypass_charge");
}

async function checkOPPIndexStatus() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/cpulimit");
  if (errno === 0) {
    document.getElementById("OPPIndex").checked = stdout.trim() === "1";
  }
}

async function setOPPIndexStatus(enabled) {
  showToast("Settings Applied");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/cpulimit" : "echo 0 >/data/AZenith/cpulimit");
}

async function checkFStrim() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/FStrim");
  if (errno === 0) {
    document.getElementById("FStrim").checked = stdout.trim() === "1";
  }
}

async function setFStrim(enabled) {
  showToast("Restart Service!");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/FStrim" : "echo 0 >/data/AZenith/FStrim");
}

async function checkDThermal() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/DThermal");
  if (errno === 0) {
    document.getElementById("DThermal").checked = stdout.trim() === "1";
  }
}

async function setDThermal(enabled) {
  showToast("Reboot Needed!");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/DThermal" : "echo 0 >/data/AZenith/DThermal");
}

async function checkSFL() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/SFL");
  if (errno === 0) {
    document.getElementById("SFL").checked = stdout.trim() === "1";
  }
}

async function setSFL(enabled) {
  showToast("Reboot Needed!");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/SFL" : "echo 0 >/data/AZenith/SFL");
}

async function checkScreenEnh() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/ScreenEnh");
  if (errno === 0) {
    document.getElementById("ScreenEnh").checked = stdout.trim() === "1";
  }
}

async function setScreenEnh(enabled) {
  showToast("Applied");
  await executeCommand(enabled ? "service call SurfaceFlinger 1022 f 1.3" : "service call SurfaceFlinger 1022 f 1.0");
  
  await executeCommand(enabled ? "echo 1 > /data/AZenith/ScreenEnh" : "echo 0 > /data/AZenith/ScreenEnh");
}

async function checkMLTweak() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/mltweak");
  if (errno === 0) {
    document.getElementById("MLTweak").checked = stdout.trim() === "1";
  }
}

async function setMLTweak(enabled) {
  showToast("Restart Service!");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/mltweak" : "echo 0 >/data/AZenith/mltweak");
}

async function startService() {
  showToast("Restarting Services...");
  await executeCommand("sh /data/adb/modules/AZenith/service.sh");
  await checkServiceStatus();
}

async function stopService() {
  showToast("Killing Service!");
  await executeCommand("pkill -f AZenith_Performance");
  await executeCommand("pkill -f AZenith");
  await checkServiceStatus();
}

async function applydisablevsync() {
  await executeCommand("service call SurfaceFlinger 1035 i32 0");
  showToast("Applied!");
}

async function checkFSTrim() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/FSTrim");
  if (errno === 0) {
    document.getElementById("FSTrim").checked = stdout.trim() === "1";
  }
}

async function setFSTrim(enabled) {
  showToast("Reboot Needed!");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/FSTrim" : "echo 0 >/data/AZenith/FSTrim");
}

async function setDefaultCpuGovernor(governor) {
  await executeCommand(`echo ${governor} >/data/AZenith/custom_default_cpu_gov`);
}

async function loadCpuGovernors() {
  let { errno, stdout } = await executeCommand(
    "chmod 644 scaling_available_governors && cat scaling_available_governors",
    { cwd: "/sys/devices/system/cpu/cpu0/cpufreq" }
  );

  if (errno === 0) {
    let governors = stdout.trim().split(/\s+/);
    let cpuGovernorSelect = document.getElementById("cpuGovernor");

    cpuGovernorSelect.innerHTML = "";

    governors.forEach((gov) => {
      let option = document.createElement("option");
      option.value = gov;
      option.textContent = gov;
      cpuGovernorSelect.appendChild(option);
    });

    let { errno: errDef, stdout: defGov } = await executeCommand(
      "[ -f custom_default_cpu_gov ] && cat custom_default_cpu_gov || cat default_cpu_gov",
      { cwd: "/data/AZenith" }
    );

    if (errDef === 0) {
      cpuGovernorSelect.value = defGov.trim();
    }
  }
}

async function showGameListModal() {
  let modal = document.getElementById("gamelistModal");
  let gameListInput = document.getElementById("gamelistInput");
  let { errno, stdout } = await executeCommand("cat /data/AZenith/gamelist.txt");

  if (errno === 0) {
    gameListInput.value = stdout.trim().replace(/\|/g, "\n");
  }

  modal.classList.remove("hidden");
}

async function saveGameList() {
  let gameList = document.getElementById("gamelistInput").value.trim().replace(/\n+/g, "/");
  await executeCommand(`echo "${gameList}" | tr '/' '|' >/data/AZenith/gamelist.txt`);
  showToast("Gamelist saved.");
}

async function checklogd() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/logd");
  if (errno === 0) {
    document.getElementById("logd").checked = stdout.trim() === "1";
  }
}

async function setlogd(enabled) {
  showToast("Applied");
  await executeCommand(enabled ? "stop logd" : "start logd");  
  await executeCommand(enabled ? "echo 1 > /data/AZenith/logd" : "echo 0 > /data/AZenith/logd");
}

async function checkPerfMode() {
  let { errno, stdout } = await executeCommand("cat /data/AZenith/PerfMode");
  if (errno === 0) {
    document.getElementById("perfmode").checked = stdout.trim() === "1";
  }
}

async function setPerfMode(enabled) {
  showToast("Applied");
  await executeCommand(enabled ? "echo 1 >/data/AZenith/PerfMode" : "echo 0 >/data/AZenith/PerfMode");
  await executeCommand(enabled ? "nohup sh /data/adb/modules/AZenith/system/bin/AZenith_Performance" : "pkill -f AZenith_Performance");
  await executeCommand(enabled ? "pkill -f AZenith_Normal" : "sh /data/adb/modules/AZenith/system/bin/AZenith_Normal");
  await executeCommand("pkill -f AZenith");
}

document.addEventListener("DOMContentLoaded", async () => {
  await checkModuleVersion();
  await checkServiceStatus();
  await checkVoltOptStatus();
  await checkOPPIndexStatus();
  await checkDThermal();
  await checkMLTweak();
  await checkDND();
  await loadCpuGovernors();
  await checkFSTrim();
  await checkBypassChargeStatus();
  await checkScreenEnh();
  await checkSFL();
  await checklogd();
  await checkPerfMode();

 
  document.getElementById("startButton").addEventListener("click", async () => {
    await startService();
  });
  
    document.getElementById("disablevsync").addEventListener("click", async () => {
    await applydisablevsync();
  });

  document.getElementById("killService").addEventListener("click", async () => {
    await stopService();
  });

  document.getElementById("VoltOpt").addEventListener("change", async function () {
    await setVoltOptStatus(this.checked);
  });
  
  document.getElementById("SFL").addEventListener("change", async function () {
    await setSFL(this.checked);
  });
  
  document.getElementById("perfmode").addEventListener("change", async function () {
    await setPerfMode(this.checked);
  });
  
    document.getElementById("DThermal").addEventListener("change", async function () {
    await setDThermal(this.checked);
  });
  
    document.getElementById("OPPIndex").addEventListener("change", async function () {
    await setOPPIndexStatus(this.checked);
  });
  
  document.getElementById("ScreenEnh").addEventListener("change", async function () {
  await setScreenEnh(this.checked);
  });
  
  document.getElementById("logd").addEventListener("change", async function () {
  await setlogd(this.checked);
  });
  
  document.getElementById("MLTweak").addEventListener("change", async function () {
    await setMLTweak(this.checked);
  });
  
  document.getElementById("DoNoDis").addEventListener("change", async function () {
    await setDND(this.checked);
  });
  
  document.getElementById("FSTrim").addEventListener("change", async function () {
    await setFSTrim(this.checked);
  });

  document.getElementById("Zepass").addEventListener("change", async function () {
    await setBypassChargeStatus(this.checked);
  });

  document.getElementById("cpuGovernor").addEventListener("change", async function () {
    await setDefaultCpuGovernor(this.value);
  });

  document.getElementById("editGamelistButton").addEventListener("click", function () {
    showGameListModal();
  });

  document.getElementById("cancelButton").addEventListener("click", function () {
    document.getElementById("gamelistModal").classList.add("hidden");
  });

  document.getElementById("saveGamelistButton").addEventListener("click", async function () {
    await saveGameList();
    document.getElementById("gamelistModal").classList.add("hidden");
  });
});
