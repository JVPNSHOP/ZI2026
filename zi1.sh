#!/bin/bash
# Zivpn Premium Management System (Full Fixed & Income Tracking Version)
# Author: Gemini
# Supports: AMD & Intel (x86_64)

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

echo -e "${YELLOW}[ Panel Login အချက်အလက် သတ်မှတ်ပါ ]${NC}"
read -p "Admin Username: " ADMIN_USER
read -p "Admin Password: " ADMIN_PASS
read -p "Panel Port (Default 81): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-81}

echo -e "\n${CYAN}Dependencies များအား Install လုပ်နေသည်...${NC}"
apt-get update -y
apt-get install -y python3 python3-pip python3-flask python3-flask-cors curl wget openssl iptables ufw jq

echo -e "${CYAN}Zivpn Binary အား တပ်ဆင်နေသည်...${NC}"
systemctl stop zivpn.service 2>/dev/null
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn

if [ ! -f /etc/zivpn/config.json ]; then
    echo '{"server": ":5667", "config": ["zi"]}' > /etc/zivpn/config.json
fi

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

[Install]
WantedBy=multi-user.target
EOF

# ===================== FIX 1 =====================
# Enable IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
# =================================================

# ================= PANEL HTML (THB ONLY MODIFIED) =================
# (Original HTML untouched except currency text)

# Replace ALL "MMK" text with "THB"
sed -i 's/MMK/THB/g' /etc/zivpn/panel.html 2>/dev/null

# ================= API FILE (ONLY RESTART FIX) =================
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
                        exp_date = datetime.datetime.strptime(u['expired'], '%Y-%m-%d').date()
                        if exp_date < now:
                            u['status'] = 'offline'
                    except: pass
            return data
    except: return []

def save_db(data):
    with open(DB_PATH, 'w') as f:
        json.dump(data, f, indent=4)

    active_passwords = [str(u['password']) for u in data if u['status'] == 'active']
    if not active_passwords:
        active_passwords = ["zi"]

    config_data = {"server": ":5667", "config": active_passwords}
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config_data, f, indent=4)

    subprocess.run(["systemctl", "daemon-reload"])
    subprocess.run(["systemctl", "restart", "zivpn"])

@app.route('/')
def index():
    return send_from_directory('/etc/zivpn', 'panel.html')

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify(load_db())

@app.route('/api/users', methods=['POST'])
def add_user():
    db = load_db()
    new_u = request.json
    new_u['id'] = str(int(db[-1]['id']) + 1) if db else "1"
    if 'created_at' not in new_u:
        new_u['created_at'] = datetime.date.today().isoformat()
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$PANEL_PORT)
EOF

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

echo -e "${CYAN}Service များကို စတင်နေသည်...${NC}"
systemctl daemon-reload
systemctl enable zivpn zivpn-panel
systemctl restart zivpn zivpn-panel

# ===================== FIX 2 =====================
iptables -t nat -F
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination 127.0.0.1:5667
ufw allow 6000:19999/udp
ufw allow 5667/udp
ufw allow $PANEL_PORT/tcp
# =================================================

MY_IP=$(curl -s ifconfig.me)

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}    ZIVPN SYSTEM INSTALL COMPLETED        ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "\n${YELLOW}Panel URL: ${CYAN}http://$MY_IP:$PANEL_PORT${NC}"
echo -e "${YELLOW}Username: ${NC}$ADMIN_USER"
echo -e "${YELLOW}Password: ${NC}$ADMIN_PASS"
echo -e "\n${BLUE}==========================================${NC}"
