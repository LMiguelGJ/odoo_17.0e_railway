#!/bin/bash

# Instalar herramientas necesarias
echo "Instalando herramientas necesarias..."
apt-get update >> /tmp/log.txt 2>&1
apt-get install -y netcat curl postgresql-client >> /tmp/log.txt 2>&1


# Función para cambiar de usuario
drop_privileges() {
    local user_name="$1"

    # Obtener el UID y GID del usuario
    user_uid=$(id -u "$user_name")
    user_gid=$(id -g "$user_name")

    # Cambiar el GID primero
    if ! setgid "$user_gid"; then
        echo "Fallo al cambiar el GID" >&2
        exit 1
    fi

    # Cambiar el UID después
    if ! setuid "$user_uid"; then
        echo "Fallo al cambiar el UID" >&2
        exit 1
    fi

    # Establecer la variable de entorno HOME para el usuario no root
    export HOME=$(getent passwd "$user_name" | cut -d: -f6)

    # Verificación: no debería ser root (UID 0)
    if [ "$(id -u)" -eq 0 ]; then
        echo "Error: No se pudo cambiar al usuario no root." >&2
        exit 1
    fi
}

# Comprobar si el script se está ejecutando como root
if [ "$(id -u)" -eq 0 ]; then
    # Nombre del usuario no root
    odoo_user="odoo"

    # Comprobar si el usuario existe, si no, crear el usuario
    if ! id "$odoo_user" &>/dev/null; then
        # Crear usuario odoo
        useradd --system --home /opt/odoo --shell /bin/bash "$odoo_user"
        mkdir -p /opt/odoo
        chown -R "$odoo_user:$odoo_user" /opt/odoo
    fi

    # Cambiar al usuario 'odoo'
    drop_privileges "$odoo_user"
else
    echo "Este script debe ser ejecutado como root." >&2
    exit 1
fi


# Ejecutar Odoo en segundo plano
echo "Iniciando Odoo..."
/usr/bin/odoo -r ${db_user} -w ${db_password} --db_host ${pg_host} --db_port ${pg_port} -d ${db_name} -i web_enterprise 
# >> /tmp/log.txt 2>&1 &

# Esperar a que Odoo esté completamente disponible
echo "Esperando a que Odoo esté disponible..."
until curl -s http://web:8069/web/login | grep -q "Odoo"
do
  echo "Odoo no está disponible aún. Esperando..."
  sleep 5
done

echo "Odoo está disponible."

# Función para ejecutar comandos SQL con reintentos
execute_sql_with_retries() {
  local max_retries=5
  local retry_interval=10
  local attempt=1

  while [ $attempt -le $max_retries ]
  do
    echo "Intento $attempt de $max_retries para ejecutar comandos SQL en la base de datos..."

    export PGPASSWORD=${db_password}
    if psql -h db -U ${db_user} -d ${db_name} -f /init-db.sql; then
      echo "Comandos SQL ejecutados con éxito."
      return 0
    else
      echo "Error al ejecutar comandos SQL. Intentando de nuevo en $retry_interval segundos..."
      sleep $retry_interval
      attempt=$((attempt + 1))
    fi
  done

  echo "Falló la ejecución de comandos SQL después de $max_retries intentos."
  return 1
}

# Ejecutar comandos SQL en la base de datos con reintentos
echo "Ejecutando comandos SQL en la base de datos..."
execute_sql_with_retries

sleep 5

# Detener Odoo
echo "Deteniendo Odoo..."
pkill -f 'odoo -c /etc/odoo/.env'

sleep 5

# Reiniciar Odoo
echo "Reiniciando Odoo..."
/usr/bin/odoo -r ${db_user} -w ${db_password} --db_host ${pghost} --db_port ${pgport} -d ${PGDATABASE} -i web_enterprise
