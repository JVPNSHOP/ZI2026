#!/bin/bash
# Zivpn Premium Management System (Connection Fixed & Income Tracking)
# Author: Gemini
# Supports: AMD & Intel (x86_64)

# Color variables
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RED='\e[1;31m'
NC='\e[0m'

clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}    ZIVPN PREMIUM FULL SYSTEM (FIXED)     ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. User Setup
echo -e "${YELLOW}[ Panel Login အချက်အလက် သတ်မှတ်ပါ ]${NC}"
read -p "Admin Username: " ADMIN_USER
read -p "Admin Password: " ADMIN_PASS
read -p "Panel Port (Default 81): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-81}

# 2. Server Preparation
echo -e "\n${CYAN}Dependencies များအား Install လုပ်နေသည်...${NC}"
apt-get update -y
apt-get install -y python3 python3-pip python3-flask python3-flask-cors curl wget openssl iptables ufw jq

# 3. Enable IP Forwarding (Critical for UDP Tunneling)
echo -e "${CYAN}Kernel Optimization လုပ်ဆောင်နေသည်...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 4. Zivpn Installation
echo -e "${CYAN}Zivpn Binary အား တပ်ဆင်နေသည်...${NC}"
systemctl stop zivpn.service 2>/dev/null
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn

# Initial Config
if [ ! -f /etc/zivpn/config.json ]; then
    echo '{"server": ":5667", "config": ["zi"]}' > /etc/zivpn/config.json
fi

# 5. Create Systemd Service for Zivpn
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
EOF

# 6. Create Web UI (With Income & Fixed Copy Icons)
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
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;900&display=swap');
        body { font-family: 'Inter', sans-serif; }
        .tab-active { border-bottom: 3px solid #3b82f6; color: #3b82f6; font-weight: 800; }
        .scrollbar-hide::-webkit-scrollbar { display: none; }
    </style>
</head>
<body class="bg-slate-50 text-slate-900 min-h-screen">

    <!-- Login Area -->
    <div id="login-ui" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-100">
        <div class="bg-white p-8 rounded-[2rem] shadow-2xl w-full max-w-sm border border-slate-200">
            <div class="flex justify-center mb-6"><div class="bg-blue-600 p-4 rounded-2xl text-white shadow-lg"><i data-lucide="shield-check" size="40"></i></div></div>
            <h1 class="text-2xl font-black text-center mb-8">ZIVPN LOGIN</h1>
            <div class="space-y-4">
                <input type="text" id="adm-u" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none focus:ring-2 focus:ring-blue-500" placeholder="Username">
                <input type="password" id="adm-p" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none focus:ring-2 focus:ring-blue-500" placeholder="Password">
                <button onclick="login()" class="w-full bg-blue-600 text-white font-bold py-4 rounded-2xl hover:bg-blue-700 shadow-lg shadow-blue-200 transition">LOGIN</button>
            </div>
        </div>
    </div>

    <!-- Main Panel -->
    <div id="panel-ui" class="hidden">
        <nav class="bg-white border-b h-20 px-6 flex justify-between items-center sticky top-0 z-40">
            <div class="flex items-center gap-2 font-black text-2xl text-blue-600 uppercase tracking-tight">
                <i data-lucide="zap"></i> ZIVPN PANEL
            </div>
            <button onclick="location.reload()" class="bg-red-50 text-red-500 px-4 py-2 rounded-xl font-bold flex items-center gap-2">
                <i data-lucide="power" size="18"></i> Logout
            </button>
        </nav>

        <div class="max-w-7xl mx-auto p-4 md:p-8">
            <!-- Income Summary Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                <div class="bg-gradient-to-br from-blue-600 to-blue-700 p-6 rounded-[2rem] text-white shadow-xl">
                    <p class="text-blue-100 text-xs font-black uppercase tracking-widest mb-2">Today Sales (ယနေ့ရောင်းရငွေ)</p>
                    <h3 class="text-3xl font-black" id="income-today">0 MMK</h3>
                </div>
                <div class="bg-gradient-to-br from-slate-800 to-slate-900 p-6 rounded-[2rem] text-white shadow-xl">
                    <p class="text-slate-400 text-xs font-black uppercase tracking-widest mb-2">Total Sales (စုစုပေါင်းရောင်းရငွေ)</p>
                    <h3 class="text-3xl font-black" id="income-total">0 MMK</h3>
                </div>
            </div>

            <!-- Tabs with Counts -->
            <div class="flex gap-8 mb-10 border-b overflow-x-auto pb-1 scrollbar-hide">
                <button onclick="setTab('all')" id="t-all" class="pb-4 flex items-center gap-2 tab-active whitespace-nowrap"><i data-lucide="layers"></i> All (<span id="count-all">0</span>)</button>
                <button onclick="setTab('active')" id="t-active" class="pb-4 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="play-circle"></i> Active (<span id="count-active">0</span>)</button>
                <button onclick="setTab('inactive')" id="t-inactive" class="pb-4 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="pause-circle"></i> Inactive (<span id="count-inactive">0</span>)</button>
                <button onclick="setTab('offline')" id="t-offline" class="pb-4 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="wifi-off"></i> Offline (<span id="count-offline">0</span>)</button>
            </div>

            <div class="flex flex-col md:flex-row justify-between items-center gap-4 mb-10">
                <h2 class="text-3xl font-black text-slate-800 tracking-tight">Accounts Management</h2>
                <button onclick="openAdd()" class="w-full md:w-auto bg-blue-600 text-white px-8 py-4 rounded-2xl font-black flex items-center justify-center gap-2 shadow-xl shadow-blue-200">
                    <i data-lucide="plus-circle"></i> CREATE ACCOUNT
                </button>
            </div>

            <!-- User Grid -->
            <div id="grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"></div>
        </div>
    </div>

    <!-- Modal -->
    <div id="modal" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
        <div class="bg-white rounded-[2.5rem] w-full max-w-md p-8 shadow-2xl">
            <h3 id="modal-title" class="text-2xl font-black mb-8 flex items-center gap-3"><i data-lucide="user-plus" class="text-blue-600"></i> New Account</h3>
            <div class="space-y-5">
                <input type="hidden" id="edit-id">
                <div>
                    <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Username</label>
                    <input type="text" id="in-u" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none font-bold">
                </div>
                <div>
                    <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Password</label>
                    <input type="text" id="in-p" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none font-bold">
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Expired Date</label>
                        <input type="date" id="in-d" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none font-bold text-sm">
                    </div>
                    <div>
                        <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Price (MMK)</label>
                        <input type="number" id="in-pr" placeholder="1000" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none font-bold">
                    </div>
                </div>
                <div class="flex items-center gap-3 p-4 bg-slate-50 rounded-2xl border border-slate-100">
                    <input type="checkbox" id="in-s" checked class="w-6 h-6 rounded-lg accent-blue-600">
                    <label class="font-black text-slate-700">Active Status</label>
                </div>
                <div class="flex gap-4 pt-6">
                    <button onclick="closeModal()" class="flex-1 font-bold py-4 text-slate-400">Cancel</button>
                    <button onclick="save()" class="flex-1 bg-blue-600 text-white py-4 rounded-2xl font-black shadow-lg shadow-blue-100">CONFIRM</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Alert Success -->
    <div id="alert" class="hidden fixed inset-0 z-[60] bg-black/70 backdrop-blur flex items-center justify-center p-4">
        <div class="bg-white rounded-[2.5rem] w-full max-w-sm p-8 text-center shadow-2xl border-b-[12px] border-blue-600">
            <div class="w-20 h-20 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6"><i data-lucide="check-circle" size="48"></i></div>
            <h3 class="text-2xl font-black mb-2">Account Ready!</h3>
            <p class="text-slate-400 mb-8">အကောင့်အား အောင်မြင်စွာ ဖန်တီးပြီးပါပြီ။</p>
            <div id="alert-msg" class="text-left bg-slate-50 p-6 rounded-3xl text-sm space-y-4 mb-8 border border-slate-100 font-medium"></div>
            <button onclick="toggleAlert(false)" class="w-full bg-slate-900 text-white font-black py-5 rounded-2xl shadow-xl">OK</button>
        </div>
    </div>

    <script>
        const ADM_U = "${ADMIN_USER}";
        const ADM_P = "${ADMIN_PASS}";
        let users = [];
        let curTab = 'all';

        async function fetchUsers() {
            try {
                const res = await fetch('/api/users');
                users = await res.json();
                updateCounts();
                calculateIncome();
                render();
            } catch(e) { console.error("Fetch error", e); }
        }

        function login() {
            if(document.getElementById('adm-u').value === ADM_U && document.getElementById('adm-p').value === ADM_P) {
                document.getElementById('login-ui').classList.add('hidden');
                document.getElementById('panel-ui').classList.remove('hidden');
                fetchUsers();
            } else { alert('Login Failed!'); }
        }

        function updateCounts() {
            document.getElementById('count-all').innerText = users.length;
            document.getElementById('count-active').innerText = users.filter(u => u.status === 'active').length;
            document.getElementById('count-inactive').innerText = users.filter(u => u.status === 'inactive').length;
            document.getElementById('count-offline').innerText = users.filter(u => u.status === 'offline').length;
        }

        function calculateIncome() {
            const today = new Date().toISOString().split('T')[0];
            let todayTotal = 0;
            let grandTotal = 0;
            users.forEach(u => {
                const p = parseInt(u.price) || 0;
                grandTotal += p;
                if(u.created_at === today) todayTotal += p;
            });
            document.getElementById('income-today').innerText = todayTotal.toLocaleString() + ' MMK';
            document.getElementById('income-total').innerText = grandTotal.toLocaleString() + ' MMK';
        }

        function setTab(t) {
            curTab = t;
            ['all', 'active', 'inactive', 'offline'].forEach(x => {
                document.getElementById('t-'+x).className = (x===t) ? 'pb-4 flex items-center gap-2 tab-active whitespace-nowrap' : 'pb-4 flex items-center gap-2 text-slate-400 whitespace-nowrap';
            });
            render();
        }

        function openAdd() {
            document.getElementById('modal-title').innerHTML = '<i data-lucide="user-plus" class="text-blue-600"></i> New Account';
            document.getElementById('edit-id').value = "";
            document.getElementById('in-u').value = "";
            document.getElementById('in-p').value = "";
            document.getElementById('in-pr').value = "";
            document.getElementById('modal').classList.remove('hidden');
            lucide.createIcons();
        }

        function closeModal() { document.getElementById('modal').classList.add('hidden'); }
        function toggleAlert(s) { document.getElementById('alert').classList.toggle('hidden', !s); }

        async function save() {
            const id = document.getElementById('edit-id').value;
            const data = {
                username: document.getElementById('in-u').value,
                password: document.getElementById('in-p').value,
                expired: document.getElementById('in-d').value || 'Unlimited',
                price: document.getElementById('in-pr').value || '0',
                status: document.getElementById('in-s').checked ? 'active' : 'inactive',
                ip: window.location.hostname,
                created_at: new Date().toISOString().split('T')[0]
            };

            if(!data.username || !data.password) return alert('Username & Password required!');

            const method = id ? 'PUT' : 'POST';
            const url = id ? '/api/users/'+id : '/api/users';

            await fetch(url, { method, headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) });
            closeModal();
            fetchUsers();

            if(!id) {
                document.getElementById('alert-msg').innerHTML = \`
                    <div class="flex justify-between items-center border-b pb-2"><span>IP:</span> <div class="flex items-center gap-2 font-black">\${data.ip} <button onclick="copy('\${data.ip}')" class="text-blue-600"><i data-lucide="copy" size="16"></i></button></div></div>
                    <div class="flex justify-between items-center border-b pb-2"><span>Pass:</span> <div class="flex items-center gap-2 font-black">\${data.password} <button onclick="copy('\${data.password}')" class="text-blue-600"><i data-lucide="copy" size="16"></i></button></div></div>
                \`;
                toggleAlert(true);
                lucide.createIcons();
            }
        }

        async function del(id) {
            if(confirm('Delete?')) { await fetch('/api/users/'+id, { method: 'DELETE' }); fetchUsers(); }
        }

        function copy(text) {
            const el = document.createElement('textarea');
            el.value = text;
            document.body.appendChild(el);
            el.select();
            document.execCommand('copy');
            document.body.removeChild(el);
            const t = document.createElement('div');
            t.className = "fixed bottom-10 left-1/2 -translate-x-1/2 bg-slate-900 text-white px-6 py-3 rounded-full text-xs font-bold z-[100] animate-bounce";
            t.innerText = "Copied!";
            document.body.appendChild(t);
            setTimeout(() => t.remove(), 1500);
        }

        function edit(id) {
            const u = users.find(x => x.id == id);
            document.getElementById('modal-title').innerHTML = '<i data-lucide="edit-3" class="text-blue-600"></i> Edit Account';
            document.getElementById('edit-id').value = u.id;
            document.getElementById('in-u').value = u.username;
            document.getElementById('in-p').value = u.password;
            document.getElementById('in-d').value = u.expired === 'Unlimited' ? '' : u.expired;
            document.getElementById('in-pr').value = u.price;
            document.getElementById('in-s').checked = (u.status === 'active');
            document.getElementById('modal').classList.remove('hidden');
            lucide.createIcons();
        }

        function render() {
            const g = document.getElementById('grid');
            g.innerHTML = '';
            let filtered = curTab === 'all' ? users : users.filter(x => x.status === curTab);

            if(filtered.length === 0) {
                g.innerHTML = '<div class="col-span-full py-20 text-center text-slate-400 font-bold">No accounts found</div>';
                return;
            }

            filtered.forEach(u => {
                const diff = new Date(u.expired) - new Date();
                const days = u.expired === 'Unlimited' ? 'Unlimited' : Math.ceil(diff / (1000 * 60 * 60 * 24)) + ' Days';
                const statusClass = u.status === 'active' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600';

                const card = document.createElement('div');
                card.className = "bg-white p-6 rounded-[2rem] border border-slate-100 shadow-sm relative";
                card.innerHTML = \`
                    <div class="flex justify-between items-center mb-6">
                        <div class="bg-blue-50 text-blue-600 p-3 rounded-xl"><i data-lucide="user"></i></div>
                        <span class="text-[10px] font-black px-3 py-1 rounded-full \${statusClass}">\${u.status.toUpperCase()}</span>
                    </div>
                    <h4 class="text-xl font-black text-slate-800 mb-6 truncate">\${u.username}</h4>
                    <div class="space-y-3 text-xs mb-8">
                        <div class="flex justify-between items-center">
                            <span class="text-slate-400 font-bold">IP ADDRESS</span>
                            <div class="flex items-center gap-2 font-black text-slate-700">\${u.ip} <button onclick="copy('\${u.ip}')" class="text-blue-500"><i data-lucide="copy" size="14"></i></button></div>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-slate-400 font-bold">PASSWORD</span>
                            <div class="flex items-center gap-2 font-black text-slate-700">\${u.password} <button onclick="copy('\${u.password}')" class="text-blue-500"><i data-lucide="copy" size="14"></i></button></div>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-slate-400 font-bold">EXPIRED</span>
                            <span class="font-black text-slate-700">\${u.expired}</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-slate-400 font-bold">PRICE</span>
                            <span class="font-black text-blue-600">\${parseInt(u.price).toLocaleString()} MMK</span>
                        </div>
                    </div>
                    <div class="flex items-center justify-between pt-4 border-t border-slate-50">
                        <div class="px-3 py-1 bg-orange-50 text-orange-600 text-[10px] font-black rounded-lg">\${days} Left</div>
                        <div class="flex gap-2">
                            <button onclick="edit('\${u.id}')" class="p-2 bg-blue-50 text-blue-600 rounded-lg"><i data-lucide="edit-3" size="16"></i></button>
                            <button onclick="del('\${u.id}')" class="p-2 bg-red-50 text-red-500 rounded-lg"><i data-lucide="trash-2" size="16"></i></button>
                        </div>
                    </div>
                \`;
                g.appendChild(card);
            });
            lucide.createIcons();
        }
        lucide.createIcons();
    </script>
</body>
</html>
EOF

# 7. Python Flask API Server (Zivpn Fixed Sync)
cat <<EOF > /etc/zivpn/panel_api.py
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json, os, subprocess, datetime

app = Flask(__name__)
CORS(app)

DB_PATH = '/etc/zivpn/users_db.json'
CONFIG_PATH = '/etc/zivpn/config.json'

def load_db():
    if not os.path.exists(DB_PATH): return []
    try:
        with open(DB_PATH, 'r') as f:
            data = json.load(f)
            now = datetime.date.today()
            for u in data:
                if u.get('expired') and u['expired'] != 'Unlimited':
                    try:
                        exp = datetime.datetime.strptime(u['expired'], '%Y-%m-%d').date()
                        if exp < now: u['status'] = 'offline'
                    except: pass
            return data
    except: return []

def save_db(data):
    with open(DB_PATH, 'w') as f: json.dump(data, f, indent=4)
    # Important Fix: Ensure Zivpn configuration is clean
    active_passwords = [str(u['password']) for u in data if u['status'] == 'active']
    if not active_passwords: active_passwords = ["zi"]
    
    config_data = {"server": ":5667", "config": active_passwords}
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config_data, f, indent=4)
    
    # Force apply rules and restart
    subprocess.run(["systemctl", "restart", "zivpn"])
    subprocess.run(["sync"])

@app.route('/')
def index(): return send_from_directory('.', 'panel.html')

@app.route('/api/users', methods=['GET'])
def get_users(): return jsonify(load_db())

@app.route('/api/users', methods=['POST'])
def add_user():
    db = load_db()
    new_u = request.json
    new_u['id'] = str(int(db[-1]['id']) + 1) if db else "1"
    if 'created_at' not in new_u: new_u['created_at'] = datetime.date.today().isoformat()
    db.append(new_u)
    save_db(db)
    return jsonify({"status": "ok"})

@app.route('/api/users/<uid>', methods=['PUT'])
def edit_user(uid):
    db = load_db()
    for u in db:
        if u['id'] == uid: u.update(request.json)
    save_db(db)
    return jsonify({"status": "ok"})

@app.route('/api/users/<uid>', methods=['DELETE'])
def del_user(uid):
    db = [u for u in load_db() if u['id'] != uid]
    save_db(db)
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$PANEL_PORT)
EOF

# 8. Setup Systemd Service for API Panel
cat <<EOF > /etc/systemd/system/zivpn-panel.service
[Unit]
Description=Zivpn Web Panel API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /etc/zivpn/panel_api.py
WorkingDirectory=/etc/zivpn
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 9. Firewall & IPTables Fix (Critical Connection Fix)
echo -e "${CYAN}Network Rules များကို အသစ်ပြန်လည်ရေးဆွဲနေသည်...${NC}"
systemctl daemon-reload
iptables -t nat -F
iptables -t nat -A PREROUTING -p udp --dport 100:65535 -j DNAT --to-destination :5667
ufw allow 100:65535/udp
ufw allow $PANEL_PORT/tcp

systemctl enable zivpn zivpn-panel
systemctl restart zivpn zivpn-panel

MY_IP=\$(curl -s ifconfig.me)

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}    ZIVPN SYSTEM FIXED & READY            ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "\n${YELLOW}Panel URL: ${CYAN}http://\$MY_IP:$PANEL_PORT${NC}"
echo -e "${YELLOW}Admin User: ${NC}$ADMIN_USER"
echo -e "${YELLOW}Admin Pass: ${NC}$ADMIN_PASS"
echo -e "\n${BLUE}ပြင်ဆင်ထားသောအချက်များ:${NC}"
echo -e "${CYAN}1. UDP Reconnecting Error - ပြင်ဆင်ပြီး (IPTables Fixed)${NC}"
echo -e "${CYAN}2. ဝင်ငွေစာရင်း Dashboard - ထည့်သွင်းပြီး${NC}"
echo -e "${CYAN}3. Copy Icon & Visibility - ပြင်ဆင်ပြီး${NC}"
echo -e "${BLUE}==========================================${NC}"
