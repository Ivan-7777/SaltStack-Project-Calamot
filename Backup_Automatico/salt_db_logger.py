#!/usr/bin/env python3
# salt_db_logger.py
import mysql.connector
import json
import os
import sys

# Leer datos de Salt (JSON desde stdin)
data = json.load(sys.stdin)

HOSTNAME = data.get('id', os.uname()[1])
STATE = data.get('fun', 'unknown')
RESULT = data.get('result', False)
CHANGES = str(data.get('changes', {}))

# Conectar a la BDD central
conn = mysql.connector.connect(
    host='',          # IP de la BDD central
    user='saltlogger',
    password='PASSWORD_SEGURA',
    database='salt_logs'
)

cursor = conn.cursor()
cursor.execute("""
    INSERT INTO salt_state_logs(hostname, state_name, result, changes)
    VALUES (%s, %s, %s, %s)
""", (HOSTNAME, STATE, RESULT, CHANGES))

conn.commit()
cursor.close()
conn.close()
