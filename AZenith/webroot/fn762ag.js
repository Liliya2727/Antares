function e(c) {
    return c && c.__esModule ? c.default : c;
}
var t = globalThis,
    n = {},
    a = {},
    o = t.parcelRequirefbde;
null == o &&
    (((o = function (c) {
        if (c in n) return n[c].exports;
        if (c in a) {
            var s = a[c];
            delete a[c];
            var r = { id: c, exports: {} };
            return (n[c] = r), s.call(r.exports, r, r.exports), r.exports;
        }
        var d = Error("Cannot find module '" + c + "'");
        throw ((d.code = "MODULE_NOT_FOUND"), d);
    }).register = function (c, s) {
        a[c] = s;
    }),
    (t.parcelRequirefbde = o)),
    (0, o.register)("27Lyk", function (c, s) {
        Object.defineProperty(c.exports, "register", { get: () => r, set: (c) => (r = c), enumerable: !0, configurable: !0 });
        var r,
            d = new Map();
        r = function (c, s) {
            for (var r = 0; r < s.length - 1; r += 2) d.set(s[r], { baseUrl: c, path: s[r + 1] });
        };
    }),
    o("27Lyk").register(new URL("", import.meta.url).toString(), JSON.parse('["gvBVN","fn762ag.js","jkrgM","48MX7"]'));
let i = 0;
function executeCommand(c, s) {
    return (
        void 0 === s && (s = {}),
        new Promise((r, d) => {
            let l = `exec_callback_${Date.now()}_${i++}`;
            function h(c) {
                delete window[c];
            }
            window[l] = (c, s, d) => {
                r({ errno: c, stdout: s, stderr: d }), h(l);
            };
            try {
                ksu.exec(c, JSON.stringify(s), l);
            } catch (m) {
                d(m), h(l);
            }
        })
    );
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
    let c = document.getElementById("msg"),
        s = randomMessages[Math.floor(Math.random() * randomMessages.length)];
    c.textContent = s;
}
function Process() {
    (this.listeners = {}), (this.stdin = new EventEmitter()), (this.stdout = new EventEmitter()), (this.stderr = new EventEmitter());
}
function showToast(c) {
    ksu.toast(c);
}
(window.onload = showRandomMessage),
    (EventEmitter.prototype.on = function (c, s) {
        this.listeners[c] || (this.listeners[c] = []), this.listeners[c].push(s);
    }),
    (EventEmitter.prototype.emit = function (c, ...s) {
        this.listeners[c] && this.listeners[c].forEach((c) => c(...s));
    }),
    (Process.prototype.on = function (c, s) {
        this.listeners[c] || (this.listeners[c] = []), this.listeners[c].push(s);
    }),
    (Process.prototype.emit = function (c, ...s) {
        this.listeners[c] && this.listeners[c].forEach((c) => c(...s));
    });
var u = {};
async function checkModuleVersion() {
    try {
        let { errno: c, stdout: s } = await executeCommand("grep \"version=\" /data/adb/modules/AZenith/module.prop | awk -F'=' '{print $2}'");
        0 === c && (document.getElementById("moduleVer").textContent = s.trim());
    } catch (r) {
        console.error("Failed to check module version:", r);
    }
}
async function checkCurrentProfile() {
    try {
        let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/profiler");
        0 === c && (document.getElementById("CurProfile").textContent = s.trim());
    } catch (r) {
        console.error("Failed to check Current Profile:", r);
    }
}
async function checkCPUInfo() {
    try {
        let { errno: c, stdout: s } = await executeCommand("echo MediaTek && getprop ro.soc.model");
        0 === c && (document.getElementById("cpuInfo").textContent = s.trim());
    } catch (r) {
        console.error("Failed to retrieve CPU info:", r);
    }
}
async function checkKernelVersion() {
    try {
        let { errno: c, stdout: s } = await executeCommand("uname -r");
        if (0 === c && s.trim()) document.getElementById("kernelInfo").textContent = s.trim();
        else {
            let r = await executeCommand("cat /proc/version");
            0 === r.errno && r.stdout.trim() ? (document.getElementById("kernelInfo").textContent = r.stdout.trim()) : (document.getElementById("kernelInfo").textContent = "Unknown Kernel");
        }
    } catch (d) {
        console.error("Failed to retrieve kernel version:", d), (document.getElementById("kernelInfo").textContent = "Error");
    }
}
async function getAndroidVersion() {
    try {
        let { errno: c, stdout: s } = await executeCommand("echo Android && getprop ro.build.version.release");
        0 === c && (document.getElementById("android").textContent = s.trim());
    } catch (r) {
        console.error("Failed to retrieve Android Version:", r);
    }
}
async function checkServiceStatus() {
    let { errno: c, stdout: s } = await executeCommand("pgrep -f AZenith");
    if (0 === c) {
        let r = document.getElementById("serviceStatus");
        "0" !== s.trim()
            ? ((r.textContent = "Zenithed⚡"), (document.getElementById("servicePID").textContent = "Service PID: " + s.trim()))
            : ((r.textContent = "Suspended\uD83D\uDCA4"), (document.getElementById("servicePID").textContent = "Service PID: null"));
    }
}
async function checkVoltOptStatus() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/VoltOpt");
    0 === c && (document.getElementById("VoltOpt").checked = "1" === s.trim());
}
async function setVoltOptStatus(c) {
    showToast("Settings Applied"), await executeCommand(c ? "echo 1 >/data/AZenith/VoltOpt" : "echo 0 >/data/AZenith/VoltOpt");
}
async function checkDND() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/dnd");
    0 === c && (document.getElementById("DoNoDis").checked = "1" === s.trim());
}
async function setDND(c) {
    showToast("DND when game"), await executeCommand(c ? "echo 1 >/data/AZenith/dnd" : "echo 0 >/data/AZenith/dnd");
}
async function checkBypassChargeStatus() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/bypass_charge");
    0 === c && (document.getElementById("Zepass").checked = "1" === s.trim());
}
async function setBypassChargeStatus(c) {
    showToast("Settings Applied"), await executeCommand(c ? "echo 1 >/data/AZenith/bypass_charge" : "echo 0 >/data/AZenith/bypass_charge");
}
async function checkOPPIndexStatus() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/cpulimit");
    0 === c && (document.getElementById("OPPIndex").checked = "1" === s.trim());
}
async function setOPPIndexStatus(c) {
    showToast("Settings Applied"), await executeCommand(c ? "echo 1 >/data/AZenith/cpulimit" : "echo 0 >/data/AZenith/cpulimit");
}

async function checkDThermal() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/DThermal");
    0 === c && (document.getElementById("DThermal").checked = "1" === s.trim());
}
async function setDThermal(c) {
    showToast("Reboot Needed!"), await executeCommand(c ? "echo 1 >/data/AZenith/DThermal" : "echo 0 >/data/AZenith/DThermal");
}
async function checkSFL() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/SFL");
    0 === c && (document.getElementById("SFL").checked = "1" === s.trim());
}
async function setSFL(c) {
    showToast("Reboot Needed!"), await executeCommand(c ? "echo 1 >/data/AZenith/SFL" : "echo 0 >/data/AZenith/SFL");
}
async function checkScreenEnh() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/ScreenEnh");
    0 === c && (document.getElementById("ScreenEnh").checked = "1" === s.trim());
}
async function setScreenEnh(c) {
    showToast("Applied"), await executeCommand(c ? "service call SurfaceFlinger 1022 f 1.3" : "service call SurfaceFlinger 1022 f 1.0"), await executeCommand(c ? "echo 1 > /data/AZenith/ScreenEnh" : "echo 0 > /data/AZenith/ScreenEnh");
}
async function checkMLTweak() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/mltweak");
    0 === c && (document.getElementById("MLTweak").checked = "1" === s.trim());
}
async function setMLTweak(c) {
    showToast("Restart Service!"), await executeCommand(c ? "echo 1 >/data/AZenith/mltweak" : "echo 0 >/data/AZenith/mltweak");
}

async function stopService() {
    showToast("Killing Service!"),
    await executeCommand("pkill -f AZenith"), 
    await checkServiceStatus();
}
async function applydisablevsync() {
    await executeCommand("service call SurfaceFlinger 1035 i32 0"), showToast("Applied!");
}
async function checkFSTrim() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/FSTrim");
    0 === c && (document.getElementById("FSTrim").checked = "1" === s.trim());
}
async function setFSTrim(c) {
    showToast("Reboot Needed!"), await executeCommand(c ? "echo 1 >/data/AZenith/FSTrim" : "echo 0 >/data/AZenith/FSTrim");
}
async function setDefaultCpuGovernor(gov) {
  await executeCommand(`echo ${gov} >/data/AZenith/custom_default_cpu_gov`);
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
    let c = document.getElementById("gamelistModal"),
        s = document.getElementById("gamelistInput"),
        { errno: r, stdout: d } = await executeCommand("cat /data/AZenith/gamelist.txt");
    0 === r && (s.value = d.trim().replace(/\|/g, "\n")), c.classList.remove("hidden");
}

async function saveGameList() {
    await executeCommand(`echo "${document.getElementById("gamelistInput").value.trim().replace(/\n+/g, "/")}" | tr '/' '|' >/data/AZenith/gamelist.txt`), showToast("Gamelist saved.");
}
async function checklogger() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/logger");
    0 === c && (document.getElementById("logger").checked = "1" === s.trim());
}
async function setlogger(c) {
    showToast("Applied!"), await executeCommand(c ? "echo 1 > /data/AZenith/logger" : "echo 0 > /data/AZenith/logger");
}
async function checkPerfMode() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/PerfMode");
    0 === c && (document.getElementById("perfmode").checked = "1" === s.trim());
}
async function setPerfMode(c) {
    showToast("Applied"),
        await executeCommand(c ? "echo 1 >/data/AZenith/PerfMode" : "echo 0 >/data/AZenith/PerfMode"),
        await executeCommand(c ? "sh /data/adb/modules/AZenith/libs/AZenith_Performance" : "sh /data/adb/modules/AZenith/libs/AZenith_Normal");
}



async function setCpuFreqOffsets(c) {
    await executeCommand(`echo ${c} >/data/AZenith/customFreqOffset`);
    await executeCommand(`sh /data/adb/modules/AZenith/libs/AZenith_Normal`);
}

async function loadCpuFreq() {
    let { errno: c, stdout: s } = await executeCommand("cat availableFreq", { cwd: "/data/AZenith" });
    if (0 === c) {
        let r = s.trim().split(/\s+/),
            d = document.getElementById("cpuFreq");
        (d.innerHTML = ""),
            r.forEach((c) => {
                let s = document.createElement("option");
                (s.value = c), (s.textContent = c), d.appendChild(s);
            });
        let { errno: l, stdout: h } = await executeCommand("[ -f customFreqOffset ] && cat customFreqOffset", { cwd: "/data/AZenith" });
        0 === l && (d.value = h.trim());
    }
}


async function checkKillLog() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/AZenith/logd");
    0 === c && (document.getElementById("logd").checked = "1" === s.trim());
}
async function setKillLog(c) {
    showToast("Reboot Needed!"), await executeCommand(c ? "echo 1 >/data/AZenith/logd" : "echo 0 >/data/AZenith/logd");
}

async function startService() {
    showToast("Restarting Services..."), 
    await executeCommand("pkill -f AZenith"), 
    await executeCommand("su -c sh /data/adb/modules/AZenith/service.sh"),
    await checkServiceStatus();
}

document.addEventListener("DOMContentLoaded", async () => {
    await checkModuleVersion();
    await checkServiceStatus();
    await checkCPUInfo();
    await checkCurrentProfile();
    await checkKernelVersion();
    await getAndroidVersion();
    await checkVoltOptStatus();
    await checkOPPIndexStatus();
    await checkDThermal();
    await checkMLTweak();
    await checkDND();
    await loadCpuFreq();
    await loadCpuGovernors();
    await checkFSTrim();
    await checkBypassChargeStatus();
    await checkScreenEnh();
    await checkSFL();
    await checkKillLog(),
    await checklogger();
    await checkPerfMode();

    document.getElementById("startButton").addEventListener("click", startService);
    document.getElementById("disablevsync").addEventListener("click", applydisablevsync);
    document.getElementById("killService").addEventListener("click", stopService);
    
    document.getElementById("VoltOpt").addEventListener("change", function () {
        setVoltOptStatus(this.checked);
    });
    document.getElementById("SFL").addEventListener("change", function () {
        setSFL(this.checked);
    });
    document.getElementById("perfmode").addEventListener("change", function () {
        setPerfMode(this.checked);
    });
    document.getElementById("DThermal").addEventListener("change", function () {
        setDThermal(this.checked);
    });
    document.getElementById("OPPIndex").addEventListener("change", function () {
        setOPPIndexStatus(this.checked);
    });
    document.getElementById("ScreenEnh").addEventListener("change", function () {
        setScreenEnh(this.checked);
    });
    document.getElementById("logger").addEventListener("change", function () {
        setlogger(this.checked);
    });
    document.getElementById("MLTweak").addEventListener("change", function () {
        setMLTweak(this.checked);
    });
    document.getElementById("DoNoDis").addEventListener("change", function () {
        setDND(this.checked);
    });
    document.getElementById("FSTrim").addEventListener("change", function () {
        setFSTrim(this.checked);
    });
    document.getElementById("logd").addEventListener("change", function () {
        setKillLog(this.checked);
    });
    document.getElementById("Zepass").addEventListener("change", function () {
        setBypassChargeStatus(this.checked);
    });
    document.getElementById("cpuGovernor").addEventListener("change", function () {
        setDefaultCpuGovernor(this.value);
    });
    document.getElementById("editGamelistButton").addEventListener("click", showGameListModal);
    document.getElementById("cpuFreq").addEventListener("change", function () {
        setCpuFreqOffsets(this.value);
    });
    document.getElementById("cancelButton").addEventListener("click", function () {
        document.getElementById("gamelistModal").classList.add("hidden");
    });
    document.getElementById("saveGamelistButton").addEventListener("click", async function () {
        await saveGameList();
        document.getElementById("gamelistModal").classList.add("hidden");
    });
});