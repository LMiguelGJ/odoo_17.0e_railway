# Utiliza una imagen base de Odoo
FROM dwiorderfaz/odoo-enterprise:17.0

WORKDIR /app

# Copia el archivo .env y otros archivos necesarios al contenedor
COPY . .

# Establece el usuario root
USER root

# Crea el directorio de inicio si no existe y asigna permisos
RUN mkdir -p /opt/odoo && \
    chown -R odoo:odoo /opt/odoo

# Asigna permisos adecuados a los archivos
RUN chmod +x /app/init-script.sh

# Expone los puertos necesarios
EXPOSE 8085 8069
EXPOSE 8086 8072

# Cambia al usuario 'odoo' y ejecuta el script de inicialización
USER odoo

# Punto de entrada
ENTRYPOINT ["/bin/bash", "-c", "/app/init-script.sh"]
