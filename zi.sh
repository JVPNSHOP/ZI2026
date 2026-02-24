#!/bin/bash
Zivpn Premium Management System (Full Fixed Version 2.0)
Author: Gemini
Supports: AMD & Intel (x86_64)
Color variables
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RED='\e[1;31m'
NC='\e[0m'
clear
echo -e "{BLUE}=========================================={NC}"
echo -e "{GREEN}    ZIVPN PREMIUM FULL SYSTEM (FIXED)     ${NC}"
echo -e "${BLUE}=========================================={NC}"
1. User Setup
echo -e "{YELLOW}[ Panel Login အချက်အလက် သတ်မှတ်ပါ ]{NC}"
read -p "Admin Username: " ADMIN_USER
read -p "Admin Password: " ADMIN_PASS
read -p "Panel Port (Default 81): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-81}
2. Server Preparation
echo -e "\n${CYAN}Dependencies များအား Install လုပ်နေသည်...${NC}"
apt-get update -y
apt-get install -y python3 python3-pip python3-flask python3-flask-cors curl wget openssl iptables ufw jq
3. Zivpn Installation
echo -e "{CYAN}Zivpn Binary အား တပ်ဆင်နေသည်...{NC}"
systemctl stop zivpn.service 2>/dev/null
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn
Initial Config (Fixed Sync Format)
if [ ! -f /etc/zivpn/config.json ]; then
echo '{"server": ":5667", "config": ["zi"]}' > /etc/zivpn/config.json
fi
4. Create Systemd Service for Zivpn
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
5. Create Web UI (Enhanced with Income Tracking & Fixed Icons)
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
.glass { background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(10px); }
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
        <!-- Stats Dashboard -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            <div class="bg-gradient-to-br from-blue-600 to-blue-700 p-6 rounded-3xl text-white shadow-lg shadow-blue-100">
                <p class="text-sm font-bold opacity-80 uppercase tracking-widest">ယနေ့ရောင်းရငွေ (Today)</p>
                <h2 class="text-3xl font-black mt-2"><span id="income-today">0</span> <span class="text-lg">MMK</span></h2>
            </div>
            <div class="bg-gradient-to-br from-slate-800 to-slate-900 p-6 rounded-3xl text-white shadow-lg shadow-slate-200">
                <p class="text-sm font-bold opacity-80 uppercase tracking-widest">စုစုပေါင်းရောင်းရငွေ (Total)</p>
                <h2 class="text-3xl font-black mt-2"><span id="income-total">0</span> <span class="text-lg">MMK</span></h2>
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
            <button onclick="openAdd()" class="w-full md:w-auto bg-blue-600 text-white px-8 py-4 rounded-2xl font-black flex items-center justify-center gap-2 shadow-xl shadow-blue-200 hover:bg-blue-700 transition">
                <i data-lucide="plus-circle"></i> CREATE ACCOUNT
            </button>
        </div>

        <!-- User Grid -->
        <div id="grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-8"></div>
    </div>
</div>

<!-- Modal -->
<div id="modal" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
    <div class="bg-white rounded-[2.5rem] w-full max-w-md p-8 shadow-2xl scale-in">
        <h3 id="modal-title" class="text-2xl font-black mb-8 flex items-center gap-3"><i data-lucide="user-plus" class="text-blue-600"></i> New Account</h3>
        <div class="space-y-5">
            <input type="hidden" id="edit-id">
            <div>
                <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Username</label>
                <input type="text" id="in-u" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none focus:ring-2 focus:ring-blue-500 font-bold">
            </div>
            <div>
                <label class="block text-xs font-black uppercase text-slate-400 mb-2 px-1">Password</label>
                <input type="text" id="in-p" class="w-full p-4 border rounded-2xl bg-slate-50 outline-none focus:ring-2 focus:ring-blue-500 font-bold">
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
        <div class="w-20 h-20 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-inner"><i data-lucide="check-circle" size="48"></i></div>
        <h3 class="text-2xl font-black mb-2 tracking-tight">Account Ready!</h3>
        <p class="text-slate-400 mb-8 font-medium">အကောင့်အား အောင်မြင်စွာ ဖန်တီးပြီးပါပြီ။</p>
        <div id="alert-msg" class="text-left bg-slate-50 p-6 rounded-3xl text-sm space-y-4 mb-8 border border-slate-100 font-medium"></div>
        <button onclick="toggleAlert(false)" class="w-full bg-slate-900 text-white font-black py-5 rounded-2xl hover:bg-black transition shadow-xl">သဘောတူသည်</button>
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
            updateStats();
            render();
        } catch(e) { console.error("Fetch error", e); }
    }

    function login() {
        if(document.getElementById('adm-u').value === ADM_U && document.getElementById('adm-p').value === ADM_P) {
            document.getElementById('login-ui').classList.add('hidden');
            document.getElementById('panel-ui').classList.remove('hidden');
            fetchUsers();
        } else {
            alert('Login Failed! အချက်အလက်များ ပြန်စစ်ပါ။');
        }
    }

    function updateStats() {
        // Counts
        document.getElementById('count-all').innerText = users.length;
        document.getElementById('count-active').innerText = users.filter(u => u.status === 'active').length;
        document.getElementById('count-inactive').innerText = users.filter(u => u.status === 'inactive').length;
        document.getElementById('count-offline').innerText = users.filter(u => u.status === 'offline').length;

        // Income Logic
        const today = new Date().toISOString().split('T')[0];
        let total = 0;
        let daily = 0;

        users.forEach(u => {
            const price = parseInt(u.price) || 0;
            total += price;
            if(u.created_at === today) daily += price;
        });

        document.getElementById('income-total').innerText = total.toLocaleString();
        document.getElementById('income-today').innerText = daily.toLocaleString();
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
        const today = new Date().toISOString().split('T')[0];
        const data = {
            username: document.getElementById('in-u').value,
            password: document.getElementById('in-p').value,
            expired: document.getElementById('in-d').value || 'Unlimited',
            price: document.getElementById('in-pr').value || '0',
            status: document.getElementById('in-s').checked ? 'active' : 'inactive',
            ip: window.location.hostname,
            created_at: id ? users.find(x => x.id == id).created_at : today
        };

        if(!data.username || !data.password) return alert('User နှင့် Pass ဖြည့်ပါ။');

        const method = id ? 'PUT' : 'POST';
        const url = id ? '/api/users/'+id : '/api/users';

        await fetch(url, { method, headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) });
        closeModal();
        fetchUsers();

        if(!id) {
            document.getElementById('alert-msg').innerHTML = \`
                <div class="flex justify-between items-center border-b pb-2"><span>IP Address:</span> <div class="flex items-center gap-2 font-black text-slate-800">\${data.ip} <button onclick="copy('\${data.ip}')" class="text-blue-600 bg-blue-50 p-1 rounded-md"><i data-lucide="copy" size="14"></i></button></div></div>
                <div class="flex justify-between items-center border-b pb-2"><span>Password:</span> <div class="flex items-center gap-2 font-black text-slate-800">\${data.password} <button onclick="copy('\${data.password}')" class="text-blue-600 bg-blue-50 p-1 rounded-md"><i data-lucide="copy" size="14"></i></button></div></div>
                <div class="flex justify-between items-center border-b pb-2"><span>Expired:</span> <span class="font-bold text-slate-800">\${data.expired}</span></div>
                <div class="flex justify-between items-center"><span>Status:</span> <span class="font-black text-green-600 uppercase">\${data.status}</span></div>
            \`;
            toggleAlert(true);
            lucide.createIcons();
        }
    }

    async function del(id) {
        if(confirm('ဖျက်ရန် သေချာပါသလား?')) {
            await fetch('/api/users/'+id, { method: 'DELETE' });
            fetchUsers();
        }
    }

    function copy(text) {
        const el = document.createElement('textarea');
        el.value = text;
        document.body.appendChild(el);
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
        const toast = document.createElement('div');
        toast.className = "fixed bottom-10 left-1/2 -translate-x-1/2 bg-slate-900 text-white px-6 py-3 rounded-full text-sm font-bold shadow-2xl z-[100]";
        toast.innerText = "Copied to clipboard!";
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 2000);
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

    function getDaysLeft(dateStr) {
        if(!dateStr || dateStr === 'Unlimited') return 'Unlimited';
        const diff = new Date(dateStr) - new Date();
        const days = Math.ceil(diff / (1000 * 60 * 60 * 24));
        return days > 0 ? days + ' Days' : 'Expired';
    }

    function render() {
        const g = document.getElementById('grid');
        g.innerHTML = '';
        let filtered = curTab === 'all' ? users : users.filter(x => x.status === curTab);

        if(filtered.length === 0) {
            g.innerHTML = '<div class="col-span-full py-20 text-center text-slate-400 font-bold"><i data-lucide="folder-open" class="mx-auto mb-4 opacity-20" size="64"></i> No accounts found here</div>';
            lucide.createIcons();
            return;
        }

        filtered.forEach(u => {
            const days = getDaysLeft(u.expired);
            const isExpired = days === 'Expired';
            const statusClass = u.status === 'active' ? 'bg-green-100 text-green-600' : (isExpired ? 'bg-red-100 text-red-600' : 'bg-slate-100 text-slate-500');

            const card = document.createElement('div');
            card.className = "bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm hover:shadow-xl transition-all duration-300 relative group overflow-hidden";
            card.innerHTML = \`
                <div class="flex justify-between items-center mb-8">
                    <div class="bg-blue-50 text-blue-600 p-4 rounded-2xl shadow-inner"><i data-lucide="user"></i></div>
                    <span class="text-[10px] font-black uppercase px-4 py-1.5 rounded-full tracking-widest \${statusClass}">\${isExpired ? 'OFFLINE' : u.status}</span>
                </div>
                <div class="space-y-4 mb-10">
                    <h4 class="text-2xl font-black text-slate-800 truncate">\${u.username}</h4>
                    <div class="space-y-3 text-sm">
                        <div class="flex justify-between items-center group/item">
                            <span class="text-slate-400 font-bold uppercase text-[10px]">IP Address</span>
                            <div class="flex items-center gap-2 font-black text-slate-700 font-mono">\${u.ip} <button onclick="copy('\${u.ip}')" class="text-blue-500 bg-blue-50 p-1 rounded-md opacity-100 md:opacity-0 md:group-hover:opacity-100 transition"><i data-lucide="copy" size="14"></i></button></div>
                        </div>
                        <div class="flex justify-between items-center group/item">
                            <span class="text-slate-400 font-bold uppercase text-[10px]">Password</span>
                            <div class="flex items-center gap-2 font-black text-slate-700 font-mono">\${u.password} <button onclick="copy('\${u.password}')" class="text-blue-500 bg-blue-50 p-1 rounded-md opacity-100 md:opacity-0 md:group-hover:opacity-100 transition"><i data-lucide="copy" size="14"></i></button></div>
                        </div>
                        <div class="flex justify-between items-center group/item">
                            <span class="text-slate-400 font-bold uppercase text-[10px]">Expired At</span>
                            <span class="font-black text-slate-700">\${u.expired}</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-slate-400 font-bold uppercase text-[10px]">Price</span>
                            <span class="font-black text-blue-600 font-mono">\${u.price} MMK</span>
                        </div>
                    </div>
                </div>
                <div class="flex items-center justify-between pt-6 border-t border-slate-50">
                    <div class="px-4 py-2 bg-orange-50 text-orange-600 text-xs font-black rounded-xl">\${days} Left</div>
                    <div class="flex gap-2">
                        <button onclick="edit('\${u.id}')" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition"><i data-lucide="edit-3" size="18"></i></button>
                        <button onclick="del('\${u.id}')" class="p-3 bg-red-50 text-red-500 rounded-xl hover:bg-red-100 transition"><i data-lucide="trash-2" size="18"></i></button>
                    </div>
                </div>
            \`;
            g.appendChild(card);
        });
        lucide.createIcons();
    }
    window.onload = fetchUsers;
</script>

</body>
</html>
EOF
6. Python Flask API Server (Fixed Zivpn Sync Logic)
cat <<EOF > /etc/zivpn/panel_api.py
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json, os, subprocess, datetime
app = Flask(name)
CORS(app)
DB_PATH = '/etc/zivpn/users_db.json'
CONFIG_PATH = '/etc/zivpn/config.json'
def load_db():
if not os.path.exists(DB_PATH): return []
with open(DB_PATH, 'r') as f:
try:
data = json.load(f)
except:
return []
    # Auto-Expiry Logic
    now = datetime.date.today()
    changed = False
    for u in data:
        if u.get('expired') and u['expired'] != 'Unlimited':
            try:
                exp_date = datetime.datetime.strptime(u['expired'], '%Y-%m-%d').date()
                if exp_date < now and u['status'] != 'offline':
                    u['status'] = 'offline'
                    changed = True
            except:
                pass
    if changed:
        save_db(data, sync=True)
    return data

def save_db(data, sync=True):
with open(DB_PATH, 'w') as f:
json.dump(data, f, indent=4)
if sync:
    # Fixed Zivpn config logic
    active_passwords = [u['password'] for u in data if u['status'] == 'active']
    # Default password if empty
    if not active_passwords:
        active_passwords = ["zi"]
    
    # Correct format for udp-zivpn
    config_data = {
        "server": ":5667",
        "config": active_passwords
    }
    
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config_data, f, indent=4)
    
    # Restart binary to load new passwords
    subprocess.run(["systemctl", "restart", "zivpn"])

@app.route('/')
def index(): return send_from_directory('.', 'panel.html')
@app.route('/api/users', methods=['GET'])
def get_users(): return jsonify(load_db())
@app.route('/api/users', methods=['POST'])
def add_user():
db = load_db()
new_u = request.json
new_u['id'] = str(max([int(u['id']) for u in db]) + 1) if db else "1"
db.append(new_u)
save_db(db)
return jsonify({"status": "ok"})
@app.route('/api/users/<uid>', methods=['PUT'])
def edit_user(uid):
db = load_db()
for u in db:
if u['id'] == uid:
u.update(request.json)
save_db(db)
return jsonify({"status": "ok"})
@app.route('/api/users/<uid>', methods=['DELETE'])
def del_user(uid):
db = [u for u in load_db() if u['id'] != uid]
save_db(db)
return jsonify({"status": "ok"})
if name == 'main':
app.run(host='0.0.0.0', port=$PANEL_PORT)
EOF
7. Setup Systemd Service for API Panel
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
8. Firewall & Activation
echo -e "{CYAN}Service များကို စတင်နေသည်...{NC}"
systemctl daemon-reload
systemctl enable zivpn zivpn-panel
systemctl restart zivpn zivpn-panel
IPTables for UDP (Ensure kernel allows forwarding)
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp
ufw allow $PANEL_PORT/tcp
MY_IP=$(curl -s ifconfig.me)
clear
echo -e "{GREEN}=========================================={NC}"
echo -e "{GREEN}    ZIVPN SYSTEM INSTALL COMPLETED        ${NC}"
echo -e "${GREEN}=========================================={NC}"
echo -e "\n${YELLOW}Panel URL: {CYAN}http://$MY\_IP:$PANEL_PORT${NC}"
echo -e "${YELLOW}Username: ${NC}$ADMIN\_USER"
echo -e "${YELLOW}Password: ${NC}$ADMIN\_PASS"
echo -e "\\n${BLUE}Fixed Update:${NC}"
echo -e "${CYAN}- Income Tracking System (Today & Total){NC}"
echo -e "{CYAN}- Zivpn Config Sync Fix (Connection OK){NC}"
echo -e "{CYAN}- Copy Buttons & UI Icons visibility improved{NC}"
echo -e "{BLUE}=========================================={NC}"
