<?php
require_once 'auth.php';
check_auth();
handle_logout();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generador de Pilares Salt - Premium</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-gradient: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
            --glass-bg: rgba(255, 255, 255, 0.05);
            --glass-border: rgba(255, 255, 255, 0.1);
            --glass-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3);
            --accent: #38bdf8;
            --accent-hover: #0ea5e9;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --input-bg: #0f172a;
        }
        body { font-family: 'Outfit', sans-serif; background: var(--bg-gradient); color: var(--text-main); min-height: 100vh; margin: 0; padding: 40px 20px; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 950px; }
        .header { text-align: center; margin-bottom: 40px; position: relative; }
        .logout-btn { position: absolute; right: 0; top: 0; color: var(--text-muted); text-decoration: none; font-size: 0.9rem; border: 1px solid var(--glass-border); padding: 8px 15px; border-radius: 8px; transition: 0.3s; }
        .logout-btn:hover { color: var(--text-main); border-color: var(--accent); }
        .header h1 { font-weight: 800; font-size: 2.8rem; margin: 0; background: linear-gradient(to right, #38bdf8, #818cf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .glass-panel { background: var(--glass-bg); backdrop-filter: blur(12px); border: 1px solid var(--glass-border); border-radius: 20px; padding: 30px; box-shadow: var(--glass-shadow); margin-bottom: 25px; display: flex; flex-direction: column; align-items: stretch; animation: fadeInUp 0.6s ease-out backwards; }
        fieldset { border: none; padding: 0; margin: 0; width: 100%; }
        legend { font-size: 1.4rem; font-weight: 600; color: var(--accent); margin-bottom: 20px; width: 100%; border-bottom: 1px solid var(--glass-border); padding-bottom: 10px; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; align-items: stretch; }
        .form-group { display: flex; flex-direction: column; gap: 8px; }
        label { font-size: 0.9rem; color: var(--text-muted); }
        input, select { background: var(--input-bg); border: 1px solid var(--glass-border); border-radius: 8px; padding: 12px 15px; color: var(--text-main); font-family: inherit; font-size: 0.95rem; }
        select option { background-color: #1e1b4b; color: white; }
        input:focus, select:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.2); }
        .checkbox-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .checkbox-label { display: flex; align-items: center; gap: 10px; cursor: pointer; padding: 15px; background: rgba(0, 0, 0, 0.1); border: 1px solid var(--glass-border); border-radius: 12px; transition: 0.3s; height: 100%; box-sizing: border-box; }
        .checkbox-label:hover { background: rgba(255, 255, 255, 0.05); border-color: var(--accent); }
        .collapsible-section { display: none; opacity: 0; transform: translateY(-10px); transition: 0.4s ease; }
        .collapsible-section.visible { display: block; opacity: 1; transform: translateY(0); }
        h4 { color: var(--text-main); margin: 25px 0 10px 0; font-size: 1rem; border-left: 3px solid var(--accent); padding-left: 10px; grid-column: 1 / -1; }
        button[type="submit"] { background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; border: none; border-radius: 12px; padding: 18px; font-size: 1.1rem; font-weight: 700; cursor: pointer; width: 100%; margin-top: 20px; transition: 0.3s; }
        button[type="submit"]:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(56, 189, 248, 0.4); }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</head>
<body>
<div class="container">
    <div class="header">
        <a href="?logout=1" class="logout-btn">Cerrar Sesión</a>
        <h1>SaltStack Admin</h1>
        <p>Dashboard de Configuración - Usuario: <b><?php echo htmlspecialchars($_SESSION['username']); ?></b></p>
    </div>

    <form action="recibir.php" method="POST">
        <!-- GLOBAL -->
        <div class="glass-panel">
            <fieldset>
                <legend>Identificación</legend>
                <div class="form-group">
                    <label>ID de Empresa / Proyecto</label>
                    <input type="text" name="company" placeholder="ej. aitor_corp" required pattern="[a-zA-Z0-9_-]+">
                </div>
            </fieldset>
        </div>

        <!-- SERVICIOS -->
        <div class="glass-panel">
            <fieldset>
                <legend>Módulos de Infraestructura</legend>
                <div class="checkbox-grid">
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="wireguard" onchange="toggle('wireguard', this)"> VPN WireGuard</label>
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="firewall" onchange="toggle('firewall', this)"> Firewall (nftables)</label>
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="dhcp" onchange="toggle('dhcp', this)"> DHCP Server</label>
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="web" onchange="toggle('web', this)"> Web Server (Nginx)</label>
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="pkica" onchange="toggle('pkica', this)"> PKI Authority</label>
                    <label class="checkbox-label"><input type="checkbox" name="services[]" value="dns" onchange="toggle('dns', this)"> DNS (Bind9)</label>
                </div>
            </fieldset>
        </div>

        <!-- WIREGUARD -->
        <div class="glass-panel collapsible-section" id="wireguard-section">
            <fieldset>
                <legend>WireGuard Settings</legend>
                <div class="form-grid">
                    <div class="form-group"><label>Puerto Público</label><input type="number" name="wireguard[port]" value="51820"></div>
                    <div class="form-group"><label>Red de Túnel (CIDR)</label><input type="text" name="wireguard[address]" value="10.66.66.1/24" readonly></div>
                    <div class="form-group"><label>IP LAN Privada</label><input type="text" name="wireguard[static_lan_ip]" placeholder="192.168.0.10/24"></div>
                    <div class="form-group"><label>Interfaz Salida (WAN)</label>
                        <select name="wireguard[wan_interface]">
                            <option value="enp0s3" selected>enp0s3 (NAT)</option>
                            <option value="enp0s8">enp0s8 (Internal)</option>
                        </select>
                    </div>
                </div>
            </fieldset>
        </div>

        <!-- FIREWALL -->
        <div class="glass-panel collapsible-section" id="firewall-section">
            <fieldset>
                <legend>Firewall & Routing</legend>
                <div class="form-grid">
                    <h4>Core WAN</h4>
                    <div class="form-group"><label>IP WAN</label><input type="text" name="firewall[wan][ip]" placeholder="10.1.105.62"></div>
                    <div class="form-group"><label>Máscara (CIDR)</label><input type="number" name="firewall[wan][mask]" value="24"></div>
                    <div class="form-group"><label>Puerta de Enlace</label><input type="text" name="firewall[wan][gateway]" value="10.1.105.1"></div>
                    <div class="form-group"><label>Interfaz WAN</label><input type="text" name="firewall[wan][interface]" value="enp0s3"></div>
                    
                    <h4>Networking LAN</h4>
                    <div class="form-group"><label>IP Puerta LAN</label><input type="text" name="firewall[lan][ip]" value="192.168.0.5"></div>
                    <div class="form-group"><label>Máscara LAN</label><input type="number" name="firewall[lan][mask]" value="24"></div>
                    <div class="form-group"><label>Interfaz LAN</label><input type="text" name="firewall[lan][interface]" value="enp0s8"></div>

                    <h4>Segmento DMZ</h4>
                    <div class="form-group"><label>IP Puerta DMZ</label><input type="text" name="firewall[dmz][ip]" value="10.2.0.5"></div>
                    <div class="form-group"><label>Máscara DMZ</label><input type="number" name="firewall[dmz][mask]" value="24"></div>
                    <div class="form-group"><label>Interfaz DMZ</label><input type="text" name="firewall[dmz][interface]" value="enp0s9"></div>
                </div>
            </fieldset>
        </div>

        <!-- DHCP -->
        <div class="glass-panel collapsible-section" id="dhcp-section">
            <fieldset>
                <legend>DHCP Dynamic Allocator</legend>
                <div class="form-grid">
                    <div class="form-group"><label>IP del Servidor</label><input type="text" name="dhcp[server_ip]" value="192.168.0.50"></div>
                    <div class="form-group"><label>Máscara Red</label><input type="number" name="dhcp[mask]" value="24"></div>
                    <div class="form-group"><label>Interfaz Escucha</label><input type="text" name="dhcp[server_interface]" value="enp0s3"></div>
                    <label class="checkbox-label" style="grid-column:1/-1"><input type="checkbox" name="dhcp[log]" value="true" checked> Habilitar Logs de Arrendamiento</label>

                    <h4>Subred LAN</h4>
                    <div class="form-group"><label>Interfaz LAN</label><input type="text" name="dhcp[interfaces][lan][name]" value="enp0s3"></div>
                    <div class="form-group"><label>Rango Inicio</label><input type="text" name="dhcp[interfaces][lan][range_start]" value="192.168.0.50"></div>
                    <div class="form-group"><label>Rango Fin</label><input type="text" name="dhcp[interfaces][lan][range_end]" value="192.168.0.200"></div>
                    <div class="form-group"><label>Máscara Decimal</label><input type="text" name="dhcp[interfaces][lan][netmask]" value="255.255.255.0"></div>
                    <div class="form-group"><label>Tiempo de Concesión</label><input type="text" name="dhcp[interfaces][lan][lease_time]" value="24h"></div>

                    <h4>Opciones Especiales (Scope)</h4>
                    <div class="form-group"><label>Default Gateway (0)</label><input type="text" name="dhcp[options][gateway][0]" value="192.168.0.5"></div>
                    <div class="form-group"><label>Secondary Gateway (1)</label><input type="text" name="dhcp[options][gateway][1]" placeholder="Opcional"></div>
                    <div class="form-group"><label>Primary DNS (0)</label><input type="text" name="dhcp[options][dns][0]" value="192.168.0.5"></div>
                    <div class="form-group"><label>Secondary DNS (1)</label><input type="text" name="dhcp[options][dns][1]" value="10.2.0.5"></div>
                </div>
            </fieldset>
        </div>

        <!-- WEB SERVER -->
        <div class="glass-panel collapsible-section" id="web-section">
            <fieldset>
                <legend>Web Server (Nginx + SSL)</legend>
                <div class="form-grid">
                    <div class="form-group"><label>Dominio (FQDN)</label><input type="text" name="web-server[domain]" value="server.es"></div>
                    <div class="form-group"><label>Webroot Path</label><input type="text" name="web-server[webroot]" value="/var/www/user/server/html"></div>
                    <div class="form-group"><label>Certificado (.crt)</label><input type="text" name="web-server[ssl][cert]" value="server.crt"></div>
                    <div class="form-group"><label>Llave Privada (.key)</label><input type="text" name="web-server[ssl][key]" value="server.key"></div>
                    
                    <h4>Network Interface</h4>
                    <div class="form-group"><label>Interfaz</label><input type="text" name="web-server[network][interface]" value="enp0s8"></div>
                    <div class="form-group"><label>IP Estática</label><input type="text" name="web-server[network][address]" value="192.168.0.10"></div>
                    <div class="form-group"><label>Gateway</label><input type="text" name="web-server[network][gateway]" value="192.168.0.5"></div>
                    
                    <h4>SSH Control</h4>
                    <div class="form-group"><label>Puerto SSH</label><input type="number" name="web-server[ssh][port]" value="22"></div>
                    <div class="form-group"><label>Root Login</label>
                        <select name="web-server[ssh][permit_root_login]">
                            <option value="yes" selected>Permitido (yes)</option>
                            <option value="no">Denegado (no)</option>
                        </select>
                    </div>
                </div>
            </fieldset>
        </div>

        <!-- PKI CA -->
        <div class="glass-panel collapsible-section" id="pkica-section">
            <fieldset>
                <legend>PKI Infrastructure</legend>
                <div class="form-grid">
                    <div class="form-group" style="grid-column: 1/-1;"><label>Directorio Base CA</label><input type="text" name="pkica[base_dir]" value="/etc/pki/ca"></div>
                    
                    <h4>Authority DN</h4>
                    <div class="form-group"><label>C (Country)</label><input type="text" name="pkica[ca][country]" value="ES"></div>
                    <div class="form-group"><label>ST (State)</label><input type="text" name="pkica[ca][state]" value="Madrid"></div>
                    <div class="form-group"><label>O (Organization)</label><input type="text" name="pkica[ca][organization]" value="SaltOrg"></div>
                    <div class="form-group"><label>CN (Common Name)</label><input type="text" name="pkica[ca][common_name]" value="master-ca"></div>
                    
                    <h4>Security</h4>
                    <div class="form-group"><label>Días Validez</label><input type="number" name="pkica[ca][days_valid]" value="3650"></div>
                    <div class="form-group"><label>Key Size (bits)</label><input type="number" name="pkica[ca][key_size]" value="4096"></div>
                    <div class="form-group"><label>Digest Algorithm</label>
                        <select name="pkica[ca][digest]">
                            <option value="sha256" selected>sha256</option>
                            <option value="sha512">sha512</option>
                        </select>
                    </div>

                    <h4>Internal Paths</h4>
                    <div class="form-group"><label>Index File</label><input type="text" name="pkica[files][index]" value="/etc/pki/ca/index.txt"></div>
                    <div class="form-group"><label>Serial File</label><input type="text" name="pkica[files][serial]" value="/etc/pki/ca/serial"></div>
                    <div class="form-group"><label>Root Cert Path</label><input type="text" name="pkica[files][root_cert]" value="/etc/pki/ca/certs/ca.cert.pem"></div>
                </div>
            </fieldset>
        </div>

        <!-- DNS -->
        <div class="glass-panel collapsible-section" id="dns-section">
            <fieldset>
                <legend>DNS Core (Bind9)</legend>
                <div class="form-grid">
                    <div class="form-group"><label>Recursión Activa</label>
                        <select name="dns[recursion]">
                            <option value="yes" selected>Sí (yes)</option>
                            <option value="no">No</option>
                        </select>
                    </div>
                    <div class="form-group" style="grid-column: 1/-1;"><label>Allow Query ACL</label><input type="text" name="dns[allow_query]" value="192.168.0.0/24; 10.66.66.0/24"></div>
                    <div class="form-group"><label>Forwarder Primario</label><input type="text" name="dns[forwarders][0]" value="8.8.8.8"></div>
                    <div class="form-group"><label>Forwarder Secundario</label><input type="text" name="dns[forwarders][1]" value="8.8.4.4"></div>
                </div>
            </fieldset>
        </div>

        <button type="submit">Desplegar Infraestructura</button>
    </form>
</div>

<script>
    function toggle(name, el) {
        const sec = document.getElementById(name + '-section');
        if(el.checked) { sec.style.display = 'block'; setTimeout(() => sec.classList.add('visible'), 10); }
        else { sec.classList.remove('visible'); setTimeout(() => sec.style.display = 'none', 400); }
    }
</script>
</body>
</html>
