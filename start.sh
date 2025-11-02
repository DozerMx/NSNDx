#!/data/data/com.termux/files/usr/bin/bash

# Directorio del script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Archivo PID
PID_FILE="$DIR/.daemon.pid"

# Función para limpiar proceso anterior
cleanup() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill -9 "$OLD_PID" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
    pkill -9 -f "python.*main.py" 2>/dev/null
    pkill -9 -f "cloudflared" 2>/dev/null
}

# Limpiar procesos anteriores
cleanup

# Función que mantiene el proceso vivo
keep_alive() {
    while true; do
        python3 obfuscated.py > /dev/null 2>&1
        sleep 2
    done
}

# Ejecutar en segundo plano completamente desacoplado
setsid nohup bash -c "
    while true; do
        python3 '$DIR/obfuscated.py' > /dev/null 2>&1
        sleep 2
    done
" > /dev/null 2>&1 &

# Guardar PID
echo $! > "$PID_FILE"

# Desacoplar del shell actual
disown

exit 0
