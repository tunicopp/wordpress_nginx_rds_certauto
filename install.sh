#!/bin/bash
# ATUALIZAR REPO
sudo apt update -y 
# INSTALAR NGINX
sudo apt install -y nginx
# INSTALAR ~PHP
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php && sudo apt update -y 
sudo apt install -y php-fpm php-mysql
#sudo apt install -y php7.4-curl php7.4-gd php7.4-mbstring php7.4-zip php7.4-imagick php7.4-dom
#sudo apt install -y php8.0-curl php8.0-gd php8.0-mbstring php8.0-zip php8.0-imagick php8.0-dom
sudo apt install php7.4-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip,soap,cli,xmlrpc,imagick,unzip,dom,redis} -y
sudo apt install php8.0-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip,soap,cli,xmlrpc,imagick,unzip,dom,redis} -y

# ADICIONAR REPO ~LETSENCRYPT E ATUALIZAR
sudo install -y software-properties-common 
sudo apt update -y 
# INSTALAR CERTBOT
sudo apt install -y certbot 
# INSTALAR PYTHON CERTBOT
sudo apt install -y python-certbot-nginx 
# BAIXAR CONFIGURACAO BASE DO WORDPRESS PARA NGINX
wget https://raw.githubusercontent.com/aldeiacloud/wordpress_nginx_rds_certauto/main/default.conf
# COPIAR ARQUIVO DE CONFIGURACAO PARA "SITES AVAILABLE"
sudo cp default.conf /etc/nginx/sites-available/wordpress
# CRIANDO LINK DA CONFIGURACAO PARA "SITES ENABLED"
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
# UNLINK DEFAULT
sudo unlink /etc/nginx/sites-enabled/default

#INSTALANDO EFS NA INSTANCIA
mkdir -p /var/www/html/tmp/
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-09c727790621482a5.efs.us-east-1.amazonaws.com:/ /var/www/html

# ABRIR PASTA TEMPORARIA
cd /var/www/html/tmp/
# BAIXAR ULTIMA VERSAO DO WORDPRESS
curl -LO https://wordpress.org/latest-pt_BR.tar.gz
# DESCOMPACTAR PASTA DO WORDPRESS
tar xzvf latest-pt_BR.tar.gz
# COPIAR ARQUIVOS DO WORDPRESS PARA PASTA PADRÃO DO NGINX
sudo cp -a /var/www/html/tmp/wordpress/. /var/www/html
# TROCANDO DONO E GRUPO DA PASTA, PARA WWW-DATA (WORDRPRESS)
sudo chown -R www-data:www-data /var/www/html
# REINICIANDO O PHP
sudo systemctl restart php7.4-fpm
/etc/init.d/php8.0-fpm restart
# REINICIANDO CONFIGURACOES DO NGINX
sudo systemctl reload nginx
# HABILITANDO NGINX PARA INICIAR COM SISTEMA OPERACIONAL
sudo systemctl enable nginx
# CONFIGURAR HORARIO (BUENOS AIRES = BRASILIA SEM HORARIO DE VERAO)
timedatectl set-timezone America/Argentina/Buenos_Aires
# CRIAR SWAP (MEMORIA DE ESCAPE)
sudo fallocate -l 2G /swapfile
# CONFIGURANDO PERMISSAO DE LEITURA E ESCRITA PARA O DONO E NENHUMA PERMISSAO PARA GRUPO E OUTROS NO "/SWAPFILE"
#sudo chmod 600 /swapfile
sudo chmod 764 /swapfile
# CONFIGURANDO SWAP NO ARQUIVO CRIADO
sudo mkswap /swapfile
# SUBINDO SWAP
sudo swapon /swapfile
# ADICIONANDO PONTO DE MONTAGEM DO SWAP NO FSTAB (PARA INICIAR COM SISTEMA OPERACIONAL)
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
echo "fs-09c727790621482a5.efs.us-east-1.amazonaws.com:/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0
" >> /etc/fstab
# ADICIONAR RENOVACAO AUTOMATICA DO CERTIFICADO
echo "SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root certbot -q renew --nginx" >> /etc/cron.d/certbot
