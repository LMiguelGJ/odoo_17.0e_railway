# Utiliza una imagen base de Odoo
FROM dwiorderfaz/odoo-enterprise:17.0

WORKDIR /app

# Copia el archivo .env y otros archivos necesarios al contenedor
COPY ./.env /etc/odoo/.env
COPY ./addons /mnt/extra-addons
COPY ./init-script.sh /init-script.sh
COPY ./init-db.sql /init-db.sql

# Asigna permisos adecuados a los archivos
RUN chmod 644 /etc/odoo/.env && \
    chmod +x /init-script.sh

# Establece el usuario root
USER root

# Expone los puertos necesarios
EXPOSE 8085 8069
EXPOSE 8086 8072

# Punto de entrada
ENTRYPOINT ["/bin/bash", "-c", "/init-script.sh"]
