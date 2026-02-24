#!/bin/bash
# Zivpn UDP + Web Panel (Full Fixed Version)
# Supports AMD/Intel & Real-time Config Sync

GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RED='\e[1;31m'
NC='\e[0m'

clear
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}   ZIVPN FULL FIXED SYSTEM (REAL-TIME)    ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. Admin Setup
read -p "Admin Username: " ADMIN_USER
read -p "Admin Password: " ADMIN_PASS
read -p "Panel Port (Default 81): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-81}

# 2. Dependencies
echo -e "\n${CYAN}Installing Dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y python3 python3-pip curl wget openssl iptables ufw jq python3-flask python3-flask-cors

# 3. Zivpn Installation
echo -e "${CYAN}Installing Zivpn Binary...${NC}"
systemctl stop zivpn.service 1> /dev/null 2> /dev/null
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn

if [ ! -f /etc/zivpn/config.json ]; then
    echo '{"server": ":5667", "config": ["zi"]}' > /etc/zivpn/config.json
fi

# SSL
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=CA/L=LA/O=Zivpn/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt" -quiet

# 4. Zivpn Service
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

# 5. Web Panel HTML (Fixed Tabs & Copy Buttons)
cat <<EOF > /etc/zivpn/panel.html
<!DOCTYPE html>
<html lang="my">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zivpn Admin Premium</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;900&display=swap');
        body { font-family: 'Inter', sans-serif; }
        .tab-active { border-bottom: 3px solid #3b82f6; color: #3b82f6; font-weight: 800; }
        .user-card { border: 1px solid #e2e8f0; transition: 0.2s; }
        .user-card:hover { border-color: #3b82f6; box-shadow: 0 10px 15px -3px rgba(59, 130, 246, 0.1); }
    </style>
</head>
<body class="bg-gray-50 text-slate-900 min-h-screen">

    <!-- Login -->
    <div id="login-ui" class="fixed inset-0 z-50 flex items-center justify-center bg-gray-100">
        <div class="bg-white p-8 rounded-3xl shadow-xl w-full max-w-sm">
            <h1 class="text-2xl font-black text-center mb-6 text-blue-600">ZIVPN ADMIN</h1>
            <input type="text" id="adm-u" class="w-full p-4 border rounded-2xl mb-4 outline-none" placeholder="Username">
            <input type="password" id="adm-p" class="w-full p-4 border rounded-2xl mb-6 outline-none" placeholder="Password">
            <button onclick="login()" class="w-full bg-blue-600 text-white font-bold py-4 rounded-2xl">LOGIN</button>
        </div>
    </div>

    <!-- Panel -->
    <div id="panel-ui" class="hidden">
        <nav class="bg-white border-b h-20 px-6 flex justify-between items-center sticky top-0 z-40">
            <div class="flex items-center gap-2 font-black text-xl text-blue-600 italic"><i data-lucide="shield"></i> ZIVPN</div>
            <button onclick="location.reload()" class="text-red-500 font-bold flex items-center gap-1"><i data-lucide="log-out" size="18"></i> Logout</button>
        </nav>

        <div class="max-w-6xl mx-auto p-4 md:p-8">
            <div class="flex gap-6 mb-8 border-b overflow-x-auto pb-1 scrollbar-hide">
                <button onclick="setTab('all')" id="t-all" class="pb-3 flex items-center gap-2 tab-active whitespace-nowrap"><i data-lucide="users"></i> All</button>
                <button onclick="setTab('active')" id="t-active" class="pb-3 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="check-circle"></i> Active</button>
                <button onclick="setTab('inactive')" id="t-inactive" class="pb-3 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="pause-circle"></i> Inactive</button>
                <button onclick="setTab('offline')" id="t-offline" class="pb-3 flex items-center gap-2 text-slate-400 whitespace-nowrap"><i data-lucide="wifi-off"></i> Offline</button>
            </div>

            <div class="flex justify-between items-center mb-8">
                <h2 class="text-2xl font-black">User Accounts</h2>
                <button onclick="openAdd()" class="bg-blue-600 text-white px-6 py-3 rounded-2xl font-bold flex items-center gap-2 shadow-lg shadow-blue-200">
                    <i data-lucide="user-plus"></i> Create Account
                </button>
            </div>

            <div id="grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"></div>
        </div>
    </div>

    <!-- Modals -->
    <div id="modal" class="hidden fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
        <div class="bg-white rounded-3xl w-full max-w-md p-8">
            <h3 id="modal-title" class="text-xl font-bold mb-6">Create Account</h3>
            <div class="space-y-4">
                <input type="hidden" id="edit-id">
                <input type="text" id="in-u" placeholder="Username" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                <input type="text" id="in-p" placeholder="Password" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                <div class="grid grid-cols-2 gap-4">
                    <input type="date" id="in-d" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                    <input type="text" id="in-pr" placeholder="Price" class="w-full p-4 border rounded-2xl bg-gray-50 outline-none">
                </div>
                <div class="flex items-center gap-3 p-4 bg-gray-50 rounded-2xl">
                    <input type="checkbox" id="in-s" checked class="w-6 h-6">
                    <label class="font-bold">Active Status</label>
                </div>
                <div class="flex gap-4 pt-4">
                    <button onclick="closeModal()" class="flex-1 font-bold">Cancel</button>
                    <button onclick="save()" class="flex-1 bg-blue-600 text-white py-4 rounded-2xl font-bold">Confirm</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Alert Success -->
    <div id="alert" class="hidden fixed inset-0 z-[60] bg-black/60 flex items-center justify-center p-4">
        <div class="bg-white rounded-[2.5rem] w-full max-w-sm p-8 text-center shadow-2xl border-t-8 border-blue-600">
            <div class="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-4"><i data-lucide="check" size="32"></i></div>
            <h3 class="text-2xl font-black mb-2">Success!</h3>
            <div id="alert-msg" class="text-left bg-gray-50 p-6 rounded-2xl text-sm space-y-3 mb-6 border border-gray-100"></div>
            <button onclick="toggleAlert(false)" class="w-full bg-blue-600 text-white font-bold py-4 rounded-2xl">သဘောတူသည်</button>
        </div>
    </div>

    <script>
        const ADM_U = "${ADMIN_USER}";
        const ADM_P = "${ADMIN_PASS}";
        let users = [];
        let curTab = 'all';

        async function fetchUsers() {
            const res = await fetch('/api/users');
            users = await res.json();
            render();
        }

        function login() {
            if(document.getElementById('adm-u').value === ADM_U && document.getElementById('adm-p').value === ADM_P) {
                document.getElementById('login-ui').classList.add('hidden');
                document.getElementById('panel-ui').classList.remove('hidden');
                fetchUsers();
            } else alert('Error Login!');
        }

        function setTab(t) {
            curTab = t;
            ['all', 'active', 'inactive', 'offline'].forEach(x => {
                document.getElementById('t-'+x).className = (x===t) ? 'pb-3 flex items-center gap-2 tab-active whitespace-nowrap' : 'pb-3 flex items-center gap-2 text-slate-400 whitespace-nowrap';
            });
            render();
        }

        function openAdd() {
            document.getElementById('modal-title').innerText = "Create Account";
            document.getElementById('edit-id').value = "";
            document.getElementById('in-u').value = "";
            document.getElementById('in-p').value = "";
            document.getElementById('modal').classList.remove('hidden');
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
                ip: window.location.hostname
            };

            const method = id ? 'PUT' : 'POST';
            const url = id ? '/api/users/'+id : '/api/users';

            await fetch(url, { method, headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) });
            closeModal();
            fetchUsers();

            if(!id) {
                document.getElementById('alert-msg').innerHTML = \`
                    <p><i data-lucide="globe" size="14"></i> <b>IP:</b> \${data.ip}</p>
                    <p><i data-lucide="user" size="14"></i> <b>User:</b> \${data.username}</p>
                    <p><i data-lucide="key" size="14"></i> <b>Pass:</b> \${data.password}</p>
                    <p><i data-lucide="calendar" size="14"></i> <b>Exp:</b> \${data.expired}</p>
                    <p><i data-lucide="info" size="14"></i> <b>Status:</b> \${data.status}</p>
                \`;
                toggleAlert(true);
                lucide.createIcons();
            }
        }

        async function del(id) {
            if(confirm('Delete?')) {
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
            alert('Copied: ' + text);
        }

        function edit(id) {
            const u = users.find(x => x.id == id);
            document.getElementById('modal-title').innerText = "Edit Account";
            document.getElementById('edit-id').value = u.id;
            document.getElementById('in-u').value = u.username;
            document.getElementById('in-p').value = u.password;
            document.getElementById('in-d').value = u.expired;
            document.getElementById('in-pr').value = u.price;
            document.getElementById('in-s').checked = (u.status === 'active');
            document.getElementById('modal').classList.remove('hidden');
        }

        function render() {
            const g = document.getElementById('grid');
            g.innerHTML = '';
            let filtered = curTab === 'all' ? users : users.filter(x => x.status === curTab);

            filtered.forEach(u => {
                const card = document.createElement('div');
                card.className = "user-card bg-white p-6 rounded-3xl";
                card.innerHTML = \`
                    <div class="flex justify-between items-center mb-4">
                        <div class="bg-blue-50 text-blue-600 p-3 rounded-2xl"><i data-lucide="user"></i></div>
                        <span class="text-[10px] font-black uppercase px-3 py-1 rounded-full \${u.status==='active'?'bg-green-100 text-green-600':'bg-red-100 text-red-600'}">\${u.status}</span>
                    </div>
                    <div class="space-y-2 mb-6">
                        <h4 class="text-xl font-black">\${u.username}</h4>
                        <div class="text-sm text-slate-500 space-y-1">
                            <div class="flex justify-between"><span>IP:</span> <span class="text-slate-900">\${u.ip}</span></div>
                            <div class="flex justify-between"><span>Pass:</span> <span class="text-slate-900 font-bold">\${u.password}</span></div>
                            <div class="flex justify-between"><span>Price:</span> <span class="text-blue-600 font-black">\${u.price}</span></div>
                            <div class="flex justify-between"><span>Exp:</span> <span class="text-slate-900">\${u.expired}</span></div>
                        </div>
                    </div>
                    <div class="flex gap-2 pt-4 border-t">
                        <button onclick="copy('\${u.username}|\${u.password}')" class="flex-1 bg-gray-100 p-2 rounded-xl text-gray-600 hover:bg-gray-200"><i data-lucide="copy" size="16" class="mx-auto"></i></button>
                        <button onclick="edit('\${u.id}')" class="flex-1 bg-blue-50 p-2 rounded-xl text-blue-600 hover:bg-blue-100"><i data-lucide="edit-3" size="16" class="mx-auto"></i></button>
                        <button onclick="del('\${u.id}')" class="flex-1 bg-red-50 p-2 rounded-xl text-red-500 hover:bg-red-100"><i data-lucide="trash-2" size="16" class="mx-auto"></i></button>
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

# 6. Python API Server (Flask) - Manage Config & Database
cat <<EOF > /etc/zivpn/panel_api.py
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json, os, subprocess

app = Flask(__name__)
CORS(app)

DB_PATH = '/etc/zivpn/users_db.json'
CONFIG_PATH = '/etc/zivpn/config.json'

def load_db():
    if not os.path.exists(DB_PATH): return []
    with open(DB_PATH, 'r') as f: return json.load(f)

def save_db(data):
    with open(DB_PATH, 'w') as f: json.dump(data, f)
    # Sync with Zivpn config.json
    passwords = [u['password'] for u in data if u['status'] == 'active']
    if not passwords: passwords = ["zi"]
    with open(CONFIG_PATH, 'w') as f:
        json.dump({"server": ":5667", "config": passwords}, f)
    subprocess.run(["systemctl", "restart", "zivpn"])

@app.route('/')
def index(): return send_from_directory('.', 'panel.html')

@app.route('/api/users', methods=['GET'])
def get_users(): return jsonify(load_db())

@app.route('/api/users', methods=['POST'])
def add_user():
    db = load_db()
    new_u = request.json
    new_u['id'] = len(db) + 1
    db.append(new_u)
    save_db(db)
    return jsonify({"status": "ok"})

@app.route('/api/users/<int:uid>', methods=['PUT'])
def edit_user(uid):
    db = load_db()
    for u in db:
        if u['id'] == uid:
            u.update(request.json)
    save_db(db)
    return jsonify({"status": "ok"})

@app.route('/api/users/<int:uid>', methods=['DELETE'])
def del_user(uid):
    db = [u for u in load_db() if u['id'] != uid]
    save_db(db)
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$PANEL_PORT)
EOF

# 7. Services
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

systemctl daemon-reload
systemctl enable zivpn zivpn-panel
systemctl restart zivpn zivpn-panel

# Firewall
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667
ufw allow 6000:19999/udp
ufw allow 5667/udp
ufw allow $PANEL_PORT/tcp

MY_IP=$(curl -s ifconfig.me)
clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETED (FIXED VERSION) ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "\n${YELLOW}URL: ${CYAN}http://$MY_IP:$PANEL_PORT${NC}"
echo -e "${YELLOW}User: ${NC}$ADMIN_USER"
echo -e "${YELLOW}Pass: ${NC}$ADMIN_PASS"
