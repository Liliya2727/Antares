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
    "The sky is really pretty today... did you notice?",
    "Sparkles make everything better ✨",
    "You’re doing your best, and that’s enough~",
    "It’s okay to rest. Even stars need time to shine.",
    "A warm drink, a deep breath… everything will be alright.",
    "Soft clouds, quiet hearts. Let’s take it slow today~",
    "You don’t need a reason to smile — just smile~",
    "Even little steps can lead to big dreams~",
    "The wind feels gentle today… like a hug from the world.",
    "You’re like a small flower growing through the cracks — beautiful and brave.",
    "I believe in you~ even if the world feels heavy sometimes.",
    "Let’s chase the light, even if the path is slow.",
    "The stars are always watching… and they’re proud of you.",
    "You sparkle more than you think ✨",
    "Sometimes doing nothing is the bravest thing of all.",
    "Let the sun kiss your cheeks and your worries fade away.",
    "Moonlight doesn’t rush, and neither should you~",
    "Hold my hand, even just in your thoughts~",
    "Gentle mornings start with a smile — even a sleepy one.",
    "Float like a cloud, soft and free~",
    "You’re a soft melody in a world that rushes — take your time.",
    "Cup of tea, cozy socks, and a heart that’s healing~",
    "Rainy days are for dreaming softly under blankets~",
    "Flowers bloom quietly — you will too.",
    "The sky doesn’t ask for permission to be beautiful, and neither should you.",
    "You are made of soft light and quiet courage~",
    "Stargazing isn’t procrastinating — it’s soul-healing.",
    "It's okay to have quiet days. The moon does too.",
    "Today’s vibe: calm skies, warm tea, soft heart.",
    "You don’t have to glow loud — some stars shine in silence ✨",
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
window.onload = function () {
    showRandomMessage();        
    checkAvailableRAM(); 
    checkProfile();
    checkServiceStatus();
    checkGPreload();
    checkCPUFrequencies();
    setInterval(checkCPUFrequencies, 700);
    setInterval(checkServiceStatus, 1000);
    setInterval(checkProfile, 1000);
    setInterval(showRandomMessage, 10000);
    setInterval(checkAvailableRAM, 3000); 
};


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
        let { errno: c, stdout: s } = await executeCommand("echo 'Version :' && grep \"version=\" /data/adb/modules/AZenith/module.prop | awk -F'=' '{print $2}'");
        0 === c && (document.getElementById("moduleVer").textContent = s.trim());
    } catch {}
}
async function checkProfile() {
    try {
        let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/current_profile");
        if (c === 0) {
            let profileNum = s.trim();
            let l = document.getElementById("CurProfile");

            // Convert number to word
            let profileMap = {
                "0": "Initializing...",    // initialize
                "1": "Performance",   // hot red
                "2": "Balanced",        // light blue-green
                "3": "ECO Mode"      // eco cyan-green
            };

            let profileName = profileMap[profileNum] || "Unknown";
            l.textContent = profileName;

            // Set custom colors
            switch (profileName) {
                case "Performance":
                    l.style.color = "#ef4444"; // hot red
                    break;
                case "ECO Mode":
                    l.style.color = "#5eead4"; // eco cyan-green
                    break;
                case "Balanced":
                    l.style.color = "#7dd3fc"; // light blue-green
                    break;
                case "Initializing...":
                    l.style.color = "#60a5fa"; // light blue
                    break;
                default:
                    l.style.color = "#ffffff"; // fallback
            }
        }
    } catch (err) {
        console.error("Error checking profile:", err);
    }
}

async function checkAvailableRAM() {
    try {
        let { stdout: meminfoOut } = await executeCommand("cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'");
        let lines = meminfoOut.trim().split("\n");

        let memTotalKB = 0, memAvailableKB = 0;

        for (let line of lines) {
            if (line.includes("MemTotal")) {
                memTotalKB = parseInt(line.match(/\d+/)[0]);
            } else if (line.includes("MemAvailable")) {
                memAvailableKB = parseInt(line.match(/\d+/)[0]);
            }
        }

        if (memTotalKB && memAvailableKB) {
            let usedKB = memTotalKB - memAvailableKB;
            let usedMB = (usedKB / 1024).toFixed(1);
            let totalMB = (memTotalKB / 1024).toFixed(1);
            let availableMB = (memAvailableKB / 1024).toFixed(1);
            let usagePercent = ((usedKB / memTotalKB) * 100).toFixed(0);

            document.getElementById("ramInfo").textContent =
                `${usedMB} MB / ${totalMB} MB (${usagePercent}%) — Available: ${availableMB} MB`;
        } else {
            document.getElementById("ramInfo").textContent = "Error reading memory";
        }
    } catch (e) {
        document.getElementById("ramInfo").textContent = "Error";
    }
}

async function checkCPUFrequencies() {
    const cpuInfoEl = document.getElementById("cpuFreqInfo");
    let result = "";

    try {
        let { stdout: policiesOut } = await executeCommand("ls /sys/devices/system/cpu/cpufreq/ | grep policy");
        let policies = policiesOut.trim().split("\n").filter(Boolean);

        for (let policy of policies) {
            let basePath = `/sys/devices/system/cpu/cpufreq/${policy}`;
            let freqCmd = `cat ${basePath}/scaling_cur_freq`;
            let cpusCmd = `cat ${basePath}/related_cpus`;

            let [{ stdout: freqOut }, { stdout: cpusOut }] = await Promise.all([
                executeCommand(freqCmd),
                executeCommand(cpusCmd)
            ]);

            let freqMHz = (parseInt(freqOut.trim()) / 1000).toFixed(0);
            let cores = cpusOut.trim().split(" ").join(", ");

            result += `Cluster ${cores}: ${freqMHz} MHz<br>`;
        }

        cpuInfoEl.innerHTML = result.trim();
    } catch (err) {
        cpuInfoEl.innerHTML = "Failed to read CPU frequencies.";
    }
}

async function fetchSOCDatabase() {
    if (!cachedSOCData)
        try {
            cachedSOCData = await (await fetch("soc.json")).json();
        } catch {
            cachedSOCData = {};
        }
    return cachedSOCData;
}
async function checkCPUInfo() {
    try {
        let { errno: c, stdout: s } = await executeCommand("getprop ro.soc.model");
        if (0 === c) {
            let r = s.trim(),
                d = await fetchSOCDatabase(),
                l = d[r];
            if (!l)
                for (let h = 8; h >= 6; h--) {
                    let m = r.substring(0, h);
                    if (d[m]) {
                        l = d[m];
                        break;
                    }
                }
            (l = l || `MediaTek ${r}`), (document.getElementById("cpuInfo").textContent = l);
        }
    } catch {
        document.getElementById("cpuInfo").textContent = "Error fetching CPU info";
    }
}


let cachedSOCData = null;

async function checkKernelVersion() {
    try {
        let { errno: c, stdout: s } = await executeCommand("uname -r");
        if (0 === c && s.trim()) document.getElementById("kernelInfo").textContent = s.trim();
        else {
            let r = await executeCommand("cat /proc/version");
            0 === r.errno && r.stdout.trim() ? (document.getElementById("kernelInfo").textContent = r.stdout.trim()) : (document.getElementById("kernelInfo").textContent = "Unknown Kernel");
        }
    } catch {
        document.getElementById("kernelInfo").textContent = "Error";
    }
}
async function getAndroidVersion() {
    try {
        let { errno: c, stdout: s } = await executeCommand("echo Android && getprop ro.build.version.release");
        0 === c && (document.getElementById("android").textContent = s.trim());
    } catch {}
}
async function checkServiceStatus() {
    let { errno: c, stdout: s } = await executeCommand("/system/bin/toybox pidof AZenith");
    let statusEl = document.getElementById("serviceStatus");
    let pidEl = document.getElementById("servicePID");

    if (c === 0 && s.trim() !== "0") {
        let pid = s.trim();
        let { stdout: profileOut } = await executeCommand("cat /data/adb/.config/AZenith/current_profile"); // Adjust path as needed
        let profile = profileOut.trim();

        if (profile === "0") {
            statusEl.textContent = "Initializing...\uD83C\uDF31"; // 🌱
            pidEl.textContent = "Service PID: " + pid;
        } else if (["1", "2", "3"].includes(profile)) {
            statusEl.textContent = "Running\uD83C\uDF43"; // 🍃
            pidEl.textContent = "Service PID: " + pid;
        } else {
            statusEl.textContent = "Unknown Profile";
            pidEl.textContent = "Service PID: " + pid;
        }
    } else {
        statusEl.textContent = "Suspended\uD83D\uDCA4"; // 💤
        pidEl.textContent = "Service PID: null";
    }
}
async function checkfpsged() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/fpsged");
    0 === c && (document.getElementById("fpsged").checked = "1" === s.trim());
}
async function setfpsged(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/fpsged" : "echo 0 >/data/adb/.config/AZenith/fpsged");
}
async function checkDND() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/dnd");
    0 === c && (document.getElementById("DoNoDis").checked = "1" === s.trim());
}
async function setDND(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/dnd" : "echo 0 >/data/adb/.config/AZenith/dnd");
}
async function checkBypassChargeStatus() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/bypass_charge");
    0 === c && (document.getElementById("Zepass").checked = "1" === s.trim());
}
async function setBypassChargeStatus(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/bypass_charge" : "echo 0 >/data/adb/.config/AZenith/bypass_charge");
}
async function checkOPPIndexStatus() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/cpulimit");
    0 === c && (document.getElementById("OPPIndex").checked = "1" === s.trim());
}
async function setOPPIndexStatus(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/cpulimit" : "echo 0 >/data/adb/.config/AZenith/cpulimit");
}
async function checkDThermal() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/DThermal");
    0 === c && (document.getElementById("DThermal").checked = "1" === s.trim());
}
async function setDThermal(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/DThermal" : "echo 0 >/data/adb/.config/AZenith/DThermal");
}
async function checkSFL() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/SFL");
    0 === c && (document.getElementById("SFL").checked = "1" === s.trim());
}
async function setSFL(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/SFL" : "echo 0 >/data/adb/.config/AZenith/SFL");
}
async function checkschedtunes() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/schedtunes");
    0 === c && (document.getElementById("schedtunes").checked = "1" === s.trim());
}
async function setschedtunes(c) {
    await executeCommand(c ? "echo 1 > /data/adb/.config/AZenith/schedtunes" : "echo 0 > /data/adb/.config/AZenith/schedtunes");
}
async function checkiosched() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/iosched");
    0 === c && (document.getElementById("iosched").checked = "1" === s.trim());
}
async function setiosched(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/iosched" : "echo 0 >/data/adb/.config/AZenith/iosched");
}
async function applydisablevsync() {
    await executeCommand("service call SurfaceFlinger 1035 i32 0"), showToast("Applied!");
}
async function checkFSTrim() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/FSTrim");
    0 === c && (document.getElementById("FSTrim").checked = "1" === s.trim());
}
async function setFSTrim(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/FSTrim" : "echo 0 >/data/adb/.config/AZenith/FSTrim");
}
async function setDefaultCpuGovernor(selectedGovernor) {
    const configPath = "/data/adb/.config/AZenith";
    const profilePath = `${configPath}/current_profile`;

    // Save the selected governor for Powersave mode
    await executeCommand(`echo ${selectedGovernor} > ${configPath}/custom_default_cpu_gov`);

    // Check current profile
    let { errno, stdout } = await executeCommand(`cat ${profilePath}`);
    if (errno === 0) {
        let currentProfile = stdout.trim();
        if (currentProfile === "2") {
            // Profile is "Powersave", apply selected governor immediately
            await executeCommand(`echo ${selectedGovernor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`);
        }
    }
}

async function loadCpuGovernors() {
    let { errno, stdout } = await executeCommand(
        "chmod 644 scaling_available_governors && cat scaling_available_governors",
        { cwd: "/sys/devices/system/cpu/cpu0/cpufreq" }
    );

    if (errno === 0) {
        let governors = stdout.trim().split(/\s+/);
        let dropdown = document.getElementById("cpuGovernor");
        dropdown.innerHTML = "";

        governors.forEach((gov) => {
            let option = document.createElement("option");
            option.value = gov;
            option.textContent = gov;
            dropdown.appendChild(option);
        });

        // Load saved governor (custom or fallback to default)
        let { errno: gErr, stdout: gOut } = await executeCommand(
            "[ -f custom_default_cpu_gov ] && cat custom_default_cpu_gov || cat default_cpu_gov",
            { cwd: "/data/adb/.config/AZenith" }
        );
        if (gErr === 0) {
            dropdown.value = gOut.trim();
        }
    }
}
async function setGovernorPowersave(selectedGovernor) {
    const configPath = "/data/adb/.config/AZenith";
    const profilePath = `${configPath}/current_profile`;

    // Save the selected governor for Powersave mode
    await executeCommand(`echo ${selectedGovernor} > ${configPath}/custom_powersave_cpu_gov`);

    // Check current profile
    let { errno, stdout } = await executeCommand(`cat ${profilePath}`);
    if (errno === 0) {
        let currentProfile = stdout.trim();
        if (currentProfile === "3") {
            // Profile is "Powersave", apply selected governor immediately
            await executeCommand(`echo ${selectedGovernor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`);
        }
    }
}

async function GovernorPowersave() {
    let { errno, stdout } = await executeCommand(
        "chmod 644 scaling_available_governors && cat scaling_available_governors",
        { cwd: "/sys/devices/system/cpu/cpu0/cpufreq" }
    );

    if (errno === 0) {
        let governors = stdout.trim().split(/\s+/);
        let dropdown = document.getElementById("GovernorPowersave");
        dropdown.innerHTML = "";

        governors.forEach((gov) => {
            let option = document.createElement("option");
            option.value = gov;
            option.textContent = gov;
            dropdown.appendChild(option);
        });

        // Load saved governor (custom or fallback to default)
        let { errno: gErr, stdout: gOut } = await executeCommand(
            "[ -f custom_powersave_cpu_gov ] && cat custom_powersave_cpu_gov || cat powersave_cpu_gov",
            { cwd: "/data/adb/.config/AZenith" }
        );
        if (gErr === 0) {
            dropdown.value = gOut.trim();
        }
    }
}
function hideGameListModal() {
    let c = document.getElementById("gamelistModal");
    c.classList.remove("show"), document.body.classList.remove("modal-open"), c._resizeHandler && (window.removeEventListener("resize", c._resizeHandler), delete c._resizeHandler);
}
async function showGameListModal() {
    let c = document.getElementById("gamelistModal"),
        s = document.getElementById("gamelistInput"),
        r = c.querySelector(".gamelist-content"),
        { errno: d, stdout: l } = await executeCommand("cat /data/adb/.config/AZenith/gamelist.txt");
    0 === d && (s.value = l.trim().replace(/\|/g, "\n")), c.classList.add("show"), document.body.classList.add("modal-open"), setTimeout(() => s.focus(), 100);
    let h = window.innerHeight,
        m = () => {
            window.innerHeight < h - 150 ? (r.style.transform = "translateY(-10%) scale(1)") : (r.style.transform = "translateY(0) scale(1)");
        };
    window.addEventListener("resize", m, { passive: !0 }), (c._resizeHandler = m), m();
}
async function saveGameList() {
    await executeCommand(`echo "${document.getElementById("gamelistInput").value.trim().replace(/\n+/g, "/").replace(/"/g, '\\"')}" | tr '/' '|' > /data/adb/.config/AZenith/gamelist.txt`), showToast("Gamelist saved."), hideGameListModal();
}
async function checklogger() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/logger");
    0 === c && (document.getElementById("logger").checked = "1" === s.trim());
}
async function setlogger(c) {
    await executeCommand(c ? "echo 1 > /data/adb/.config/AZenith/logger" : "echo 0 > /data/adb/.config/AZenith/logger");
}
async function setCpuFreqOffsets(c) {
    await executeCommand(`echo ${c} >/data/adb/.config/AZenith/customFreqOffset`);
}
async function loadCpuFreq() {
    let { errno: c, stdout: s } = await executeCommand("cat availableFreq", { cwd: "/data/adb/.config/AZenith" });
    if (0 === c) {
        let r = s.trim().split(/\s+/),
            d = document.getElementById("cpuFreq");
        (d.innerHTML = ""),
            r.forEach((c) => {
                let s = document.createElement("option");
                (s.value = c), (s.textContent = c), d.appendChild(s);
            });
        let { errno: l, stdout: h } = await executeCommand("[ -f customFreqOffset ] && cat customFreqOffset", { cwd: "/data/adb/.config/AZenith" });
        0 === l && (d.value = h.trim());
    }
}
async function checkKillLog() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/logd");
    0 === c && (document.getElementById("logd").checked = "1" === s.trim());
}
async function setKillLog(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/logd" : "echo 0 >/data/adb/.config/AZenith/logd");
}
async function startService() {
    showToast("Restarting Daemon"),    
    await executeCommand("rm -f /data/adb/.config/AZenith/AZenithVerbose.log"),
    await executeCommand("rm -f /data/adb/.config/AZenith/AZenith.log"),
    await executeCommand("pkill -9 AZenith && su -c 'AZenith > /dev/null 2>&1 & disown'"), 
    await checkServiceStatus();
}
async function checkGPreload() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/APreload");
    0 === c && (document.getElementById("GPreload").checked = "1" === s.trim());
}
async function setGPreloadStatus(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/APreload" : "echo 0 >/data/adb/.config/AZenith/APreload");
}
async function checkRamBoost() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/clearbg");
    0 === c && (document.getElementById("clearbg").checked = "1" === s.trim());
}
async function setRamBoostStatus(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/clearbg" : "echo 0 >/data/adb/.config/AZenith/clearbg");
}
async function checkmalisched() {
    let { errno: c, stdout: s } = await executeCommand("cat /data/adb/.config/AZenith/malisched");
    0 === c && (document.getElementById("malisched").checked = "1" === s.trim());
}
async function setmalisched(c) {
    await executeCommand(c ? "echo 1 >/data/adb/.config/AZenith/malisched" : "echo 0 >/data/adb/.config/AZenith/malisched");
}





async function showColorScheme() {
    const modal = document.getElementById("schemeModal");
    const modalContent = modal.querySelector(".scheme-content");

    // Lock scroll
    document.body.classList.add("modal-open");
    modal.classList.add("show");

    // Animate based on keyboard visibility
    const h = window.innerHeight;
    const adjust = () => {
        if (window.innerHeight < h - 150) {
            modalContent.style.transform = "translateY(-10%) scale(1)";
        } else {
            modalContent.style.transform = "translateY(0) scale(1)";
        }
    };

    window.addEventListener("resize", adjust, { passive: true });
    modal._resizeHandler = adjust;
    adjust();
}

function hidecolorscheme() {
    let c = document.getElementById("schemeModal");
    c.classList.remove("show"), document.body.classList.remove("modal-open"), showToast("Saved color scheme settings."), c._resizeHandler && (window.removeEventListener("resize", c._resizeHandler), delete c._resizeHandler);
}


const CACHE_FILE_PATH = "/data/adb/.config/AZenith/color_scheme";
function saveDisplaySettings(c, s, r, d) {
    let l = `sh -c 'echo "${c} ${s} ${r} ${d}" > ${CACHE_FILE_PATH}'`;
    executeCommand(l);
}
async function loadDisplaySettings() {
    try {
        let c = await executeCommand(`sh -c "cat '${CACHE_FILE_PATH}'"`),
            s = "object" == typeof c && c.stdout ? c.stdout.trim() : String(c).trim(),
            [r, d, l, h] = s.split(/\s+/).map(Number);
        if ([r, d, l, h].some(isNaN)) return showToast("Invalid color_scheme format. Using safe defaults."), { red: 1e3, green: 1e3, blue: 1e3, saturation: 1e3 };
        return { red: r, green: d, blue: l, saturation: h };
    } catch (m) {
        return console.log("Error reading display settings:", m), showToast("color_scheme not found. Using defaults."), { red: 1e3, green: 1e3, blue: 1e3, saturation: 1e3 };
    }
}
async function setRGB(c, s, r) {
    await executeCommand(`service call SurfaceFlinger 1015 i32 1 f ${c / 1e3} f 0 f 0 f 0 f 0 f ${s / 1e3} f 0 f 0 f 0 f 0 f ${r / 1e3} f 0 f 0 f 0 f 0 f 1`);
}
async function setSaturation(c) {
    await executeCommand(`service call SurfaceFlinger 1022 f ${c / 1e3}`);
}
async function resetDisplaySettings() {
    await executeCommand("service call SurfaceFlinger 1015 i32 1 f 1 f 0 f 0 f 0 f 0 f 1 f 0 f 0 f 0 f 0 f 1 f 0 f 0 f 0 f 0 f 1"),
        await executeCommand("service call SurfaceFlinger 1022 f 1"),
        saveDisplaySettings(1e3, 1e3, 1e3, 1e3),
        (document.getElementById("red").value = 1e3),
        (document.getElementById("green").value = 1e3),
        (document.getElementById("blue").value = 1e3),
        (document.getElementById("saturation").value = 1e3),
        showToast("Display settings reset!");
}
document.addEventListener("DOMContentLoaded", async () => {
    let c = document.getElementById("red"),
        s = document.getElementById("green"),
        r = document.getElementById("blue"),
        d = document.getElementById("saturation"),
        l = document.getElementById("reset-btn"),
        h = await loadDisplaySettings();
    async function m() {
        let l = parseInt(c.value),
            h = parseInt(s.value),
            m = parseInt(r.value),
            f = parseInt(d.value);
        await setRGB(l, h, m), saveDisplaySettings(l, h, m, f);
    }
    async function f() {
        let l = parseInt(d.value),
            h = parseInt(c.value),
            m = parseInt(s.value),
            f = parseInt(r.value);
        await setSaturation(l), saveDisplaySettings(h, m, f, l);
    }
    (c.value = h.red),
        (s.value = h.green),
        (r.value = h.blue),
        (d.value = h.saturation),
        await setRGB(h.red, h.green, h.blue),
        await setSaturation(h.saturation),
        c.addEventListener("input", m),
        s.addEventListener("input", m),
        r.addEventListener("input", m),
        d.addEventListener("input", f),
        l.addEventListener("click", resetDisplaySettings),
    await Promise.all([
        checkModuleVersion(),
        
        checkCPUInfo(),        
        checkKernelVersion(),
        getAndroidVersion(),
        checkfpsged(),
        checkOPPIndexStatus(),
        checkDThermal(),
        checkiosched(),
        checkmalisched(),
        checkDND(),
        loadCpuFreq(),
        loadCpuGovernors(),
        GovernorPowersave(),
        checkFSTrim(),
        checkBypassChargeStatus(),
        checkschedtunes(),
        checkSFL(),
        checkKillLog(),
  
        checklogger(),
        checkRamBoost(),
    ]),
        document.getElementById("loading-screen").classList.add("hidden"),
        document.getElementById("startButton").addEventListener("click", startService),
        document.getElementById("disablevsync").addEventListener("click", applydisablevsync),
        document.getElementById("fpsged").addEventListener("change", function () {
            setfpsged(this.checked);
        }),
        document.getElementById("GPreload").addEventListener("change", function () {
            setGPreloadStatus(this.checked);
        }),
        document.getElementById("clearbg").addEventListener("change", function () {
            setRamBoostStatus(this.checked);
        }),
        document.getElementById("SFL").addEventListener("change", function () {
            setSFL(this.checked);
        }),
        document.getElementById("DThermal").addEventListener("change", function () {
            setDThermal(this.checked);
        }),
        document.getElementById("OPPIndex").addEventListener("change", function () {
            setOPPIndexStatus(this.checked);
        }),
        document.getElementById("schedtunes").addEventListener("change", function () {
            setschedtunes(this.checked);
        }),
        document.getElementById("logger").addEventListener("change", function () {
            setlogger(this.checked);
        }),
        document.getElementById("iosched").addEventListener("change", function () {
            setiosched(this.checked);
        }),
        document.getElementById("malisched").addEventListener("change", function () {
            setmalisched(this.checked);
        }),
        document.getElementById("DoNoDis").addEventListener("change", function () {
            setDND(this.checked);
        }),
        document.getElementById("FSTrim").addEventListener("change", function () {
            setFSTrim(this.checked);
        }),
        document.getElementById("logd").addEventListener("change", function () {
            setKillLog(this.checked);
        }),
        document.getElementById("Zepass").addEventListener("change", function () {
            setBypassChargeStatus(this.checked);
        }),
        document.getElementById("cpuGovernor").addEventListener("change", function () {
            setDefaultCpuGovernor(this.value);
        }),
        document.getElementById("GovernorPowersave").addEventListener("change", function () {
            setGovernorPowersave(this.value);
        }),
        document.getElementById("cpuFreq").addEventListener("change", function () {
            setCpuFreqOffsets(this.value);
        }),
        
        
        document.getElementById("colorschemebutton").addEventListener("click", showColorScheme),   
        document.getElementById("applybutton").addEventListener("click", hidecolorscheme),   
        
        
        
        document.getElementById("editGamelistButton").addEventListener("click", showGameListModal),        
        document.getElementById("cancelButton").addEventListener("click", hideGameListModal),
        document.getElementById("saveGamelistButton").addEventListener("click", saveGameList);        
});
