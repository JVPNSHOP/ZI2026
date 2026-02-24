#!/bin/bash
# Zivpn UDP Module + Web Admin Panel Universal Installer
# Compatible with both AMD and Intel VPS (x86_64)

# Color variables
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RED='\e[1;31m'
NC='\e[0m'

clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}   ZIVPN UDP + WEB PANEL (AMD & INTEL)    ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. Architecture Check
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}Error: ဤ Script သည် x86_64 (AMD/Intel) အတွက်သာ ဖြစ်သည်။ သင်၏ Architecture မှာ $ARCH ဖြစ်နေပါသည်။${NC}"
    exit 1
fi

# 2. Admin Panel Credentials Setup
echo -e "\n${YELLOW}[ Admin Panel Setup ]${NC}"
read -p "Admin Username သတ်မှတ်ပါ: " ADMIN_USER
read -p "Admin Password သတ်မှတ်ပါ: " ADMIN_PASS
read -p "Panel Port သတ်မှတ်ပါ (Default 81): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-81}

# 3. Server Preparation
echo -e "\n${CYAN}လိုအပ်သော Package များအား Install လုပ်နေသည်...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip curl wget openssl iptables ufw jq

# 4. Install Zivpn UDP (Universal Binary for x86_64)
echo -e "${CYAN}Zivpn UDP Service အား တပ်ဆင်နေသည်...${NC}"
systemctl stop zivpn.service 1> /dev/null 2> /dev/null
# x86_64 binary works for both AMD and Intel
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn 1> /dev/null 2> /dev/null
wget https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json -O /etc/zivpn/config.json 1> /dev/null 2> /dev/null

# SSL Certificate Generation
echo -e "${CYAN}SSL Certificate ထုတ်ပေးနေသည်...${NC}"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Zivpn/OU=IT/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null

# 5. Zivpn Service Configuration
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# 6. Create Web Dashboard (HTML5 + Tailwind)
cat <<EOF > /etc/zivpn/panel.html
<!DOCTYPE html>
<html lang="my">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zivpn Management Panel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Pyidaungsu&family=Inter:wght@400;600;700&display=swap');
        body { font-family: 'Inter', 'Pyidaungsu', sans-serif; }
        .tab-active { border-bottom: 3px solid #2563eb; color: #2563eb; font-weight: 700; }
        .user-card { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
        .user-card:hover { transform: translateY(-5px); box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1); }
    </style>
</head>
<body class="bg-gray-50 text-gray-900 min-h-screen">

    <!-- Login Area -->
    <div id="login-box" class="fixed inset-0 z-50 flex items-center justify-center bg-gray-100">
        <div class="bg-white p-8 rounded-3xl shadow-2xl w-full max-w-sm border border-gray-200">
            <div class="flex justify-center mb-6"><div class="bg-blue-600 p-4 rounded-2xl text-white shadow-lg"><i data-lucide="shield-check" size="40"></i></div></div>
            <h1 class="text-2xl font-bold text-center mb-8">Admin Login</h1>
            <div class="space-y-5">
                <input type="text" id="adm-u" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none focus:ring-2 focus:ring-blue-500" placeholder="Username">
                <input type="password" id="adm-p" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none focus:ring-2 focus:ring-blue-500" placeholder="Password">
                <button onclick="doLogin()" class="w-full bg-blue-600 text-white font-bold py-4 rounded-2xl hover:bg-blue-700 shadow-lg shadow-blue-200 transition">LOGIN</button>
            </div>
        </div>
    </div>

    <!-- Main App -->
    <div id="app-box" class="hidden">
        <nav class="bg-white border-b sticky top-0 z-40 px-6 h-20 flex justify-between items-center">
            <div class="flex items-center gap-3 text-blue-600 font-black text-2xl uppercase tracking-tighter">
                <i data-lucide="zap"></i> Zivpn Panel
            </div>
            <button onclick="location.reload()" class="bg-red-50 text-red-600 px-4 py-2 rounded-xl flex items-center gap-2 font-bold hover:bg-red-100"><i data-lucide="power"></i> Logout</button>
        </nav>

        <div class="max-w-6xl mx-auto p-6 lg:p-12">
            <!-- Stats Tabs -->
            <div class="flex gap-8 mb-10 border-b overflow-x-auto">
                <button onclick="setTab('all')" id="t-all" class="pb-4 flex items-center gap-2 tab-active whitespace-nowrap"><i data-lucide="users"></i> All</button>
                <button onclick="setTab('active')" id="t-active" class="pb-4 flex items-center gap-2 text-gray-500 whitespace-nowrap"><i data-lucide="zap"></i> Active</button>
                <button onclick="setTab('inactive')" id="t-inactive" class="pb-4 flex items-center gap-2 text-gray-500 whitespace-nowrap"><i data-lucide="moon"></i> Inactive</button>
                <button onclick="setTab('offline')" id="t-offline" class="pb-4 flex items-center gap-2 text-gray-500 whitespace-nowrap"><i data-lucide="wifi-off"></i> Offline</button>
            </div>

            <div class="flex flex-col sm:flex-row justify-between items-center gap-4 mb-10">
                <h2 class="text-3xl font-black text-gray-800">User Dashboard</h2>
                <button onclick="toggleModal('modal-add', true)" class="w-full sm:w-auto bg-blue-600 text-white px-8 py-4 rounded-2xl flex items-center justify-center gap-2 font-black shadow-xl shadow-blue-100 hover:bg-blue-700 transition">
                    <i data-lucide="plus-circle"></i> CREATE ACCOUNT
                </button>
            </div>

            <!-- Grid -->
            <div id="user-list" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8"></div>
        </div>
    </div>

    <!-- Create Modal -->
    <div id="modal-add" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
        <div class="bg-white rounded-3xl w-full max-w-md p-8 shadow-2xl">
            <h3 class="text-2xl font-bold mb-8 flex items-center gap-3"><i data-lucide="user-plus" class="text-blue-600"></i> New Account</h3>
            <div class="space-y-5">
                <input type="text" id="i-u" placeholder="Username" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                <input type="text" id="i-p" placeholder="Password" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                <div class="grid grid-cols-2 gap-4">
                    <input type="date" id="i-d" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                    <input type="text" id="i-pr" placeholder="Price" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                </div>
                <div class="flex items-center gap-3 p-4 bg-gray-50 rounded-2xl">
                    <input type="checkbox" id="i-s" checked class="w-6 h-6 accent-blue-600">
                    <label class="font-bold">Active Status</label>
                </div>
                <div class="flex gap-4 pt-4">
                    <button onclick="toggleModal('modal-add', false)" class="flex-1 bg-gray-200 py-4 rounded-2xl font-bold">CANCEL</button>
                    <button onclick="addAccount()" class="flex-1 bg-blue-600 text-white py-4 rounded-2xl font-bold shadow-lg shadow-blue-100">CREATE</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Alert Modal -->
    <div id="modal-alert" class="hidden fixed inset-0 z-[60] bg-black/70 backdrop-blur flex items-center justify-center p-4">
        <div class="bg-white rounded-[2rem] w-full max-w-sm p-8 text-center shadow-2xl border-b-8 border-blue-600">
            <div class="w-20 h-20 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6"><i data-lucide="badge-check" size="48"></i></div>
            <h3 class="text-2xl font-black mb-2">Account Ready!</h3>
            <p class="text-gray-500 mb-8">Account created successfully.</p>
            <div id="alert-body" class="text-left bg-gray-50 p-6 rounded-2xl space-y-4 mb-8 border border-gray-100"></div>
            <button onclick="toggleModal('modal-alert', false)" class="w-full bg-gray-900 text-white font-bold py-5 rounded-2xl hover:bg-black transition">DONE</button>
        </div>
    </div>

    <script>
        const ADM_U = "${ADMIN_USER}";
        const ADM_P = "${ADMIN_PASS}";
        let users = JSON.parse(localStorage.getItem('zivpn_universal') || '[]');
        let curTab = 'all';

        function doLogin() {
            if(document.getElementById('adm-u').value === ADM_U && document.getElementById('adm-p').value === ADM_P) {
                document.getElementById('login-box').classList.add('hidden');
                document.getElementById('app-box').classList.remove('hidden');
                render();
            } else alert('Credentials Incorrect!');
        }

        function toggleModal(id, show) { document.getElementById(id).classList.toggle('hidden', !show); }

        function setTab(t) {
            curTab = t;
            ['all', 'active', 'inactive', 'offline'].forEach(x => {
                document.getElementById('t-'+x).className = (x === t) ? 'pb-4 flex items-center gap-2 tab-active whitespace-nowrap' : 'pb-4 flex items-center gap-2 text-gray-500 whitespace-nowrap';
            });
            render();
        }

        function addAccount() {
            const u = document.getElementById('i-u').value;
            const p = document.getElementById('i-p').value;
            const d = document.getElementById('i-d').value;
            const pr = document.getElementById('i-pr').value || '0';
            const s = document.getElementById('i-s').checked;

            if(!u || !p) return alert('Username & Password required');

            const acc = {
                id: Date.now(),
                username: u, password: p, expired: d || 'Never', price: pr,
                status: s ? 'active' : 'inactive',
                ip: window.location.hostname
            };

            users.push(acc);
            localStorage.setItem('zivpn_universal', JSON.stringify(users));
            toggleModal('modal-add', false);
            render();

            document.getElementById('alert-body').innerHTML = \`
                <div class="flex items-center gap-3"><i data-lucide="monitor" size="16"></i> <b>IP:</b> \${acc.ip}</div>
                <div class="flex items-center gap-3"><i data-lucide="user" size="16"></i> <b>User:</b> \${acc.username}</div>
                <div class="flex items-center gap-3"><i data-lucide="key" size="16"></i> <b>Pass:</b> \${acc.password}</div>
                <div class="flex items-center gap-3"><i data-lucide="calendar" size="16"></i> <b>Exp:</b> \${acc.expired}</div>
                <div class="flex items-center gap-3"><i data-lucide="info" size="16"></i> <b>Status:</b> <span class="text-blue-600 font-bold">\${acc.status}</span></div>
            \`;
            toggleModal('modal-alert', true);
            lucide.createIcons();
        }

        function deleteUser(id) {
            if(confirm('ဖျက်ရန် သေချာပါသလား?')) {
                users = users.filter(x => x.id !== id);
                localStorage.setItem('zivpn_universal', JSON.stringify(users));
                render();
            }
        }

        function render() {
            const container = document.getElementById('user-list');
            container.innerHTML = '';
            let filtered = curTab === 'all' ? users : users.filter(x => x.status === curTab);

            filtered.forEach(x => {
                const card = document.createElement('div');
                card.className = "user-card bg-white p-8 rounded-3xl border border-gray-100 shadow-sm relative overflow-hidden";
                
                let daysLeft = '∞';
                if(x.expired !== 'Never') {
                    const diff = new Date(x.expired) - new Date();
                    daysLeft = Math.ceil(diff / (86400000)) + ' Days';
                }

                card.innerHTML = \`
                    <div class="flex justify-between items-start mb-6">
                        <div class="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center shadow-inner"><i data-lucide="user"></i></div>
                        <span class="px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest \${x.status === 'active' ? 'bg-green-100 text-green-600' : 'bg-gray-100 text-gray-500'}">\${x.status}</span>
                    </div>
                    <h4 class="text-xl font-black mb-1">\${x.username}</h4>
                    <div class="space-y-2 text-sm text-gray-500 mb-8 font-medium">
                        <div class="flex justify-between"><span>IP:</span> <span class="text-gray-900">\${x.ip}</span></div>
                        <div class="flex justify-between"><span>Expired:</span> <span class="text-gray-900">\${x.expired}</span></div>
                        <div class="flex justify-between"><span>Price:</span> <span class="text-blue-600 font-black">\${x.price}</span></div>
                    </div>
                    <div class="pt-6 border-t flex justify-between items-center">
                        <div class="text-xs font-black text-orange-600 bg-orange-50 px-3 py-1.5 rounded-xl">\${daysLeft} Left</div>
                        <button onclick="deleteUser(\${x.id})" class="p-3 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition"><i data-lucide="trash-2" size="20"></i></button>
                    </div>
                \`;
                container.appendChild(card);
            });
            lucide.createIcons();
        }
        lucide.createIcons();
    </script>
</body>
</html>
EOF

# 7. Web Server Engine (Python based)
cat <<EOF > /etc/zivpn/panel_server.py
import http.server, socketserver
PORT = $PANEL_PORT
class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/': self.path = 'panel.html'
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.serve_forever()
EOF

# 8. Service Deployment
cat <<EOF > /etc/systemd/system/zivpn-panel.service
[Unit]
Description=Zivpn Web Admin Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/bin/python3 /etc/zivpn/panel_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Activation
systemctl daemon-reload
systemctl enable zivpn.service zivpn-panel.service
systemctl start zivpn.service zivpn-panel.service

# Networking (Universal IPTables)
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp
ufw allow $PANEL_PORT/tcp

MY_IP=$(curl -s ifconfig.me)

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   UNIVERSAL INSTALLATION COMPLETED      ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "\n${YELLOW}Panel URL: ${CYAN}http://$MY_IP:$PANEL_PORT${NC}"
echo -e "${YELLOW}Username: ${NC}$ADMIN_USER"
echo -e "${YELLOW}Password: ${NC}$ADMIN_PASS"
echo -e "\n${BLUE}Note: ဤ Panel သည် AMD နှင့် Intel VPS နှစ်မျိုးလုံးတွင် အဆင်ပြေစွာ သုံးနိုင်ပါသည်။${NC}"
echo -e "${BLUE}==========================================${NC}"
