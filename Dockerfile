# Utiliza una imagen base de Odoo
FROM dwiorderfaz/odoo-enterprise:17.0

WORKDIR /app

# Copia el archivo .env y otros archivos necesarios al contenedor
COPY . .

# Establece el usuario root
USER root

# Asigna permisos adecuados a los archivos
RUN chmod +x /app/init-script.sh

# Expone los puertos necesarios
EXPOSE 8085 8069
EXPOSE 8086 8072

# Punto de entrada
ENTRYPOINT ["/bin/bash", "-c", "/app/init-script.sh"]