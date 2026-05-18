<?php
require_once "auth.php";
check_auth();
handle_logout();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generador de Pillars Salt</title>
    <style>
        :root { --bg: #0f172a; --panel: #111827; --border: #334155; --muted: #cbd5e1; --accent: #38bdf8; }
        body { font-family: system-ui, sans-serif; background: linear-gradient(180deg, #0f172a, #111827); color: #f8fafc; margin: 0; padding: 24px; }
        .wrap { max-width: 1100px; margin: 0 auto; }
        .top { display: flex; justify-content: space-between; align-items: center; gap: 16px; margin-bottom: 18px; }
        .top a { color: #7dd3fc; text-decoration: none; }
        .panel { background: rgba(17,24,39,.95); border: 1px solid var(--border); border-radius: 18px; padding: 22px; margin-bottom: 18px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; }
        .wide { grid-column: 1 / -1; }
        label { display: block; color: var(--muted); margin: 0 0 6px; }
        input, select { width: 100%; box-sizing: border-box; padding: 11px; border-radius: 10px; border: 1px solid #475569; background: #0b1220; color: #fff; }
        fieldset { border: none; padding: 0; margin: 0; }
        legend { font-weight: 800; font-size: 1.15rem; color: var(--accent); margin-bottom: 16px; }
        .checks { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; }
        .checks label { display: flex; gap: 10px; align-items: center; background: #0b1220; padding: 10px 12px; border: 1px solid #334155; border-radius: 10px; }
        .checks input { width: auto; }
        button { width: 100%; padding: 14px; border: none; border-radius: 12px; background: var(--accent); color: #082f49; font-weight: 800; cursor: pointer; }
        .small { font-size: .92rem; color: #94a3b8; }
        .note { color: #93c5fd; font-size: .92rem; margin: 0 0 14px; }
        .state-panel { display: none; }
    </style>
</head>
<body>
<div class="wrap">
    <div class="top">
        <div>
            <h1>Generador de Pillars Salt</h1>
            <p class="small">Usuario: <?php echo htmlspecialchars($_SESSION["username"]); ?> | Genera ficheros compatibles con este laboratorio.</p>
        </div>
        <a href="?logout=1">Cerrar sesión</a>
    </div>

    <form action="recibir.php" method="POST" autocomplete="off">
        <input type="hidden" name="csrf_token" value="<?php echo generate_csrf_token(); ?>">
        <div class="panel">
            <fieldset>
                <legend>Proyecto</legend>
                <div class="grid">
                    <div>
                        <label>ID cliente/proyecto</label>
                        <input type="text" name="company" required pattern="[a-zA-Z0-9_-]+" placeholder="ej. aitor">
                    </div>
                </div>
            </fieldset>
        </div>

        <div class="panel">
            <fieldset>
                <legend>Estados previstos</legend>
                <div class="checks">
                    <label><input type="checkbox" name="states[]" value="firewall" data-target="state-firewall"> firewall</label>
                    <label><input type="checkbox" name="states[]" value="dns" data-target="state-dns"> dns</label>
                    <label><input type="checkbox" name="states[]" value="proxy" data-target="state-proxy"> proxy</label>
                    <label><input type="checkbox" name="states[]" value="BDD" data-target="state-bdd"> BDD</label>
                    <label><input type="checkbox" name="states[]" value="dhcp" data-target="state-dhcp"> dhcp</label>
                    <label><input type="checkbox" name="states[]" value="pkica" data-target="state-pkica"> pkica</label>
                    <label><input type="checkbox" name="states[]" value="wireguard" data-target="state-wireguard"> wireguard</label>
                    <label><input type="checkbox" name="states[]" value="webserver" data-target="state-webserver"> webserver</label>
                    <label><input type="checkbox" name="states[]" value="zabbix-server" data-target="state-zabbix"> zabbix-server</label>
                    <label><input type="checkbox" name="states[]" value="restic-server" data-target="state-restic"> restic-server</label>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-firewall">
            <fieldset>
                <legend>Firewall</legend>
                <div class="grid">
                    <div><label>WAN IP</label><input type="text" name="firewall[wan][ip]" value="10.1.105.151"></div>
                    <div><label>WAN máscara CIDR</label><input type="number" name="firewall[wan][mask]" value="24"></div>
                    <div><label>WAN gateway</label><input type="text" name="firewall[wan][gateway]" value="10.1.105.1"></div>
                    <div><label>WAN interfaz</label><input type="text" name="firewall[wan][interface]" value="enp0s3"></div>
                    <div><label>LAN IP</label><input type="text" name="firewall[lan][ip]" value="192.168.0.1"></div>
                    <div><label>LAN máscara CIDR</label><input type="number" name="firewall[lan][mask]" value="24"></div>
                    <div><label>LAN interfaz</label><input type="text" name="firewall[lan][interface]" value="enp0s8"></div>
                    <div><label>DMZ IP</label><input type="text" name="firewall[dmz][ip]" value="192.168.1.1"></div>
                    <div><label>DMZ máscara CIDR</label><input type="number" name="firewall[dmz][mask]" value="24"></div>
                    <div><label>DMZ interfaz</label><input type="text" name="firewall[dmz][interface]" value="enp0s9"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-proxy">
            <fieldset>
                <legend>Proxy</legend>
                <div class="grid">
                    <div><label>IP proxy DMZ</label><input type="text" name="proxy[ip]" value="192.168.1.10"></div>
                    <div><label>Puerto proxy</label><input type="number" name="proxy[puerto_customizado]" value="80"></div>
                    <div><label>Interfaz proxy</label><input type="text" name="proxy[interface]" value="enp0s3"></div>
                    <div><label>Máscara proxy CIDR</label><input type="number" name="proxy[mask]" value="24"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-webserver">
            <fieldset>
                <legend>Webserver</legend>
                <p class="note">Este bloque genera los datos para desplegar Apache, MariaDB local y WordPress ya instalado, sin pasar por install.php.</p>
                <div class="grid">
                    <div><label>Hostname</label><input type="text" name="web-server[hostname]" value="serv-web"></div>
                    <div><label>Dominio</label><input type="text" name="web-server[domain]" value="server.es"></div>
                    <div><label>Webroot</label><input type="text" name="web-server[webroot]" value="/var/www/user/server/html"></div>
                    <div><label>Interfaz</label><input type="text" name="web-server[network][interface]" value="enp0s3"></div>
                    <div><label>IP servidor web</label><input type="text" name="web-server[network][address]" value="192.168.0.10"></div>
                    <div><label>Máscara CIDR</label><input type="number" name="web-server[network][mask]" value="24"></div>
                    <div><label>Gateway</label><input type="text" name="web-server[network][gateway]" value="192.168.0.1"></div>
                    <div><label>DNS</label><input type="text" name="web-server[network][dns]" value="192.168.0.1"></div>
                    <div><label>Certificado</label><input type="text" name="web-server[ssl][cert]" value="server.crt"></div>
                    <div><label>Clave</label><input type="text" name="web-server[ssl][key]" value="server.key"></div>
                    <div><label>Puerto SSH</label><input type="number" name="web-server[ssh][port]" value="22"></div>
                    <div><label>PermitRootLogin</label><select name="web-server[ssh][permit_root_login]"><option value="yes">yes</option><option value="no" selected>no</option></select></div>
                    <div><label>WordPress DB name</label><input type="text" name="wordpress[db_name]" value="wordpress"></div>
                    <div><label>WordPress DB user</label><input type="text" name="wordpress[db_user]" value="wordpress"></div>
                    <div><label>WordPress DB pass</label><input type="text" name="wordpress[db_pass]" value="WordPress_2026!"></div>
                    <div><label>WordPress admin user</label><input type="text" name="wordpress[admin_user]" value="admin"></div>
                    <div><label>WordPress admin pass</label><input type="text" name="wordpress[admin_pass]" value="admin"></div>
                    <div><label>WordPress admin email</label><input type="text" name="wordpress[admin_email]" value="admin@server.es"></div>
                    <div><label>WordPress URL</label><input type="text" name="wordpress[site_url]" value="http://10.1.105.151"></div>
                    <div class="wide"><label>WordPress titulo</label><input type="text" name="wordpress[title]" value="Bienvenido a mi sitio"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-dns">
            <fieldset>
                <legend>DNS</legend>
                <p class="note">Si activas `dns`, revisa tambien los bloques `webserver`, `dhcp`, `wireguard` y `pkica`, porque las zonas DNS usan esos datos.</p>
                <div class="grid">
                    <div><label>Recursion</label><select name="dns[recursion]"><option value="yes" selected>yes</option><option value="no">no</option></select></div>
                    <div class="wide"><label>allow_query</label><input type="text" name="dns[allow_query]" value="192.168.0.0/24; 192.168.1.0/24; 10.66.66.0/24"></div>
                    <div><label>Forwarder 1</label><input type="text" name="dns[forwarders][0]" value="10.1.105.1"></div>
                    <div><label>Forwarder 2</label><input type="text" name="dns[forwarders][1]" value="10.1.105.1"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-dhcp">
            <fieldset>
                <legend>DHCP</legend>
                <div class="grid">
                    <div><label>IP servidor DHCP</label><input type="text" name="dhcp[server_ip]" value="192.168.0.10"></div>
                    <div><label>Interfaz servidor DHCP</label><input type="text" name="dhcp[server_interface]" value="enp0s3"></div>
                    <div><label>Log DHCP</label><select name="dhcp[log]"><option value="true" selected>true</option><option value="false">false</option></select></div>
                    <div><label>LAN interfaz</label><input type="text" name="dhcp[interfaces][lan][name]" value="enp0s3"></div>
                    <div><label>LAN range start</label><input type="text" name="dhcp[interfaces][lan][range_start]" value="192.168.0.50"></div>
                    <div><label>LAN range end</label><input type="text" name="dhcp[interfaces][lan][range_end]" value="192.168.0.200"></div>
                    <div><label>LAN netmask</label><input type="text" name="dhcp[interfaces][lan][netmask]" value="255.255.255.0"></div>
                    <div><label>LAN lease time</label><input type="text" name="dhcp[interfaces][lan][lease_time]" value="24h"></div>
                    <div><label>DMZ interfaz</label><input type="text" name="dhcp[interfaces][dmz][name]" value="enp0s3"></div>
                    <div><label>DMZ range start</label><input type="text" name="dhcp[interfaces][dmz][range_start]" value="192.168.1.50"></div>
                    <div><label>DMZ range end</label><input type="text" name="dhcp[interfaces][dmz][range_end]" value="192.168.1.200"></div>
                    <div><label>DMZ netmask</label><input type="text" name="dhcp[interfaces][dmz][netmask]" value="255.255.255.0"></div>
                    <div><label>DMZ lease time</label><input type="text" name="dhcp[interfaces][dmz][lease_time]" value="24h"></div>
                    <div><label>Gateway 0</label><input type="text" name="dhcp[options][gateway][0]" value="192.168.0.1"></div>
                    <div><label>Gateway 1</label><input type="text" name="dhcp[options][gateway][1]" value="192.168.1.1"></div>
                    <div><label>DNS 0</label><input type="text" name="dhcp[options][dns][0]" value="192.168.0.1"></div>
                    <div><label>DNS 1</label><input type="text" name="dhcp[options][dns][1]" value="192.168.1.1"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-pkica">
            <fieldset>
                <legend>PKI</legend>
                <div class="grid">
                    <div><label>Base dir</label><input type="text" name="pkica[base_dir]" value="/etc/pki/ca"></div>
                    <div><label>Country</label><input type="text" name="pkica[ca][country]" value="ES"></div>
                    <div><label>State</label><input type="text" name="pkica[ca][state]" value="Madrid"></div>
                    <div><label>Locality</label><input type="text" name="pkica[ca][locality]" value="Madrid"></div>
                    <div><label>Organization</label><input type="text" name="pkica[ca][organization]" value="MiOrg"></div>
                    <div><label>OU</label><input type="text" name="pkica[ca][organizational_unit]" value="IT"></div>
                    <div><label>Common Name</label><input type="text" name="pkica[ca][common_name]" value="mi-ca"></div>
                    <div><label>Días validez</label><input type="number" name="pkica[ca][days_valid]" value="3650"></div>
                    <div><label>Key size</label><input type="number" name="pkica[ca][key_size]" value="4096"></div>
                    <div><label>Digest</label><input type="text" name="pkica[ca][digest]" value="sha256"></div>
                    <div><label>Index file</label><input type="text" name="pkica[files][index]" value="/etc/pki/ca/index.txt"></div>
                    <div><label>Serial file</label><input type="text" name="pkica[files][serial]" value="/etc/pki/ca/serial"></div>
                    <div><label>Serial start</label><input type="number" name="pkica[files][serial_start]" value="1000"></div>
                    <div><label>OpenSSL config</label><input type="text" name="pkica[files][openssl_config]" value="/etc/pki/ca/openssl.cnf"></div>
                    <div><label>Private key</label><input type="text" name="pkica[files][private_key]" value="/etc/pki/ca/private/ca.key.pem"></div>
                    <div><label>Root cert</label><input type="text" name="pkica[files][root_cert]" value="/etc/pki/ca/certs/ca.cert.pem"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-wireguard">
            <fieldset>
                <legend>WireGuard</legend>
                <p class="note">El estado admite varios peers. El formulario deja preparados dos peers fijos; si no informas la clave publica, no se incluye ese peer.</p>
                <div class="grid">
                    <div><label>Puerto</label><input type="number" name="wireguard[port]" value="51820"></div>
                    <div><label>Address CIDR</label><input type="text" name="wireguard[address]" value="10.66.66.1/24"></div>
                    <div><label>Static LAN IP</label><input type="text" name="wireguard[static_lan_ip]" value="192.168.0.10/24"></div>
                    <div><label>WAN interfaz</label><input type="text" name="wireguard[wan_interface]" value="enp0s3"></div>
                    <div><label>Peer 1 nombre</label><input type="text" name="wireguard[peers][cliente_externo][name]" value="cliente_externo"></div>
                    <div><label>Peer 1 public key</label><input type="text" name="wireguard[peers][cliente_externo][public_key]" value=""></div>
                    <div><label>Peer 1 allowed IPs</label><input type="text" name="wireguard[peers][cliente_externo][allowed_ips]" value="10.66.66.5/32"></div>
                    <div><label>Peer 2 nombre</label><input type="text" name="wireguard[peers][cliente_admin][name]" value="cliente_admin"></div>
                    <div><label>Peer 2 public key</label><input type="text" name="wireguard[peers][cliente_admin][public_key]" value=""></div>
                    <div><label>Peer 2 allowed IPs</label><input type="text" name="wireguard[peers][cliente_admin][allowed_ips]" value="10.66.66.6/32"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel state-panel" id="state-bdd">
            <fieldset>
                <legend>BDD / MySQL</legend>
                <p class="note">Este estado tambien crea la base y usuario de Zabbix. Aqui puedes dejarlo parametrizado en lugar de usar los defaults del estado.</p>
                <div class="grid">
                    <div><label>MySQL root password</label><input type="text" name="mysql[root_password]" value="M@r1aDB_R00t_2026!"></div>
                    <div><label>Host logs</label><input type="text" name="mysql[host]" value="192.168.0.10"></div>
                    <div><label>Port</label><input type="number" name="mysql[port]" value="3306"></div>
                    <div><label>User logs</label><input type="text" name="mysql[user]" value="saltlogger"></div>
                    <div><label>Password logs</label><input type="text" name="mysql[password]" value="S@ltL0gg3r_2026!"></div>
                    <div><label>Database logs</label><input type="text" name="mysql[database]" value="salt_logs"></div>
                    <div><label>Zabbix DB name</label><input type="text" name="zabbix[db_name]" value="zabbix"></div>
                    <div><label>Zabbix DB user</label><input type="text" name="zabbix[db_user]" value="zabbix"></div>
                    <div><label>Zabbix DB pass</label><input type="text" name="zabbix[db_pass]" value="Unclick2026"></div>
                </div>
            </fieldset>
        </div>

        <!-- ======== ZABBIX ======== -->
        <div class="panel state-panel" id="state-zabbix">
            <fieldset>
                <legend>Monitoreo - Zabbix</legend>
                <p class="note">Sistema de monitorización centralizado. El servidor recoge métricas y el agente se despliega automáticamente en cada minion con servicios activos.</p>
                <div class="grid">
                    <div><label>DB host</label><input type="text" name="zabbix[db_host]" value="192.168.0.10"></div>
                    <div><label>DB port</label><input type="number" name="zabbix[db_port]" value="3306"></div>
                    <div><label>DB name</label><input type="text" name="zabbix[db_name]" value="zabbix"></div>
                    <div><label>DB user</label><input type="text" name="zabbix[db_user]" value="zabbix"></div>
                    <div><label>DB password</label><input type="text" name="zabbix[db_pass]" value="Z@bb1x_2026!"></div>
                    <div><label>DB root password</label><input type="text" name="zabbix[db_root]" value="M@r1aDB_R00t_2026!"></div>
                    <div><label>Server IP</label><input type="text" name="zabbix[server_ip]" value="192.168.0.151"></div>
                    <div><label>Agent port</label><input type="number" name="zabbix[agent_port]" value="10050"></div>
                    <div><label>Discovery network</label><input type="text" name="zabbix[discovery_network]" value="192.168.0.0/24"></div>
                </div>
            </fieldset>
        </div>

        <!-- ======== RESTIC ======== -->
        <div class="panel state-panel" id="state-restic">
            <fieldset>
                <legend>Backups - Restic</legend>
                <p class="note">Sistema de copias de seguridad incremental. El servidor almacena los backups y el cliente se despliega automáticamente en cada minion con servicios activos.</p>
                <div class="grid">
                    <div><label>Contraseña repositorio</label><input type="text" name="restic[password]" value="R3st1c_Backup_2026!"></div>
                    <div><label>URL repositorio</label><input type="text" name="restic[repository]" value="rest:http://192.168.0.151:8000/"></div>
                    <div><label>Puerto REST server</label><input type="number" name="restic[port]" value="8000"></div>
                    <div><label>Cron minuto</label><input type="text" name="restic[cron_minute]" value="0"></div>
                    <div><label>Cron hora</label><input type="text" name="restic[cron_hour]" value="1"></div>
                    <div class="wide"><label>Rutas de backup (separadas por coma)</label><input type="text" name="restic[backup_paths]" value="/var/www,/etc"></div>
                </div>
                <p class="note" style="margin-top:14px;">Base de datos de logging</p>
                <div class="grid">
                    <div><label>MySQL host</label><input type="text" name="restic[mysql][host]" value="192.168.0.10"></div>
                    <div><label>MySQL port</label><input type="number" name="restic[mysql][port]" value="3306"></div>
                    <div><label>MySQL root password</label><input type="text" name="restic[mysql][root_password]" value="M@r1aDB_R00t_2026!"></div>
                    <div><label>MySQL user</label><input type="text" name="restic[mysql][user]" value="saltlogger"></div>
                    <div><label>MySQL password</label><input type="text" name="restic[mysql][password]" value="S@ltL0gg3r_2026!"></div>
                    <div><label>MySQL database</label><input type="text" name="restic[mysql][database]" value="salt_logs"></div>
                </div>
            </fieldset>
        </div>

        <div class="panel">
            <button type="submit">Generar pillars del laboratorio</button>
        </div>
    </form>
</div>
<script>
    function setPanelInputsDisabled(panel, disabled) {
        panel.querySelectorAll("input, select, textarea").forEach((field) => {
            field.disabled = disabled;
        });
    }

    function toggleStatePanel(changedCheckbox) {
        const targetId = changedCheckbox.dataset.target;
        if (!targetId) return;
        const panel = document.getElementById(targetId);
        if (!panel) return;
        // Panel visible si ALGÚN checkbox con ese target está marcado
        const anyChecked = Array.from(document.querySelectorAll('[data-target="' + targetId + '"]')).some(cb => cb.checked);
        panel.style.display = anyChecked ? "block" : "none";
        setPanelInputsDisabled(panel, !anyChecked);
    }

    document.querySelectorAll('input[name="states[]"]').forEach((checkbox) => {
        checkbox.checked = false;
        checkbox.addEventListener("change", () => toggleStatePanel(checkbox));
        toggleStatePanel(checkbox);
    });
</script>
</body>
</html>
