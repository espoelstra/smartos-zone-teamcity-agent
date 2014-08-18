#!/bin/bash

if [ -z $1 ]; then
  echo "No teamcity project id (name) given"
  exit 1
fi

if [ -z $3 ]; then
  echo "No git branch (name) given"
  exit 1
fi


# don't change these, they are used in the nginx.conf file.
NGINX_DIR='/opt/local/etc/nginx/' # @todo simplify these variables
NGINX_CONFIG='/opt/local/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/opt/local/etc/nginx/sites-enabled'
NGINX_EXTRA_CONFIG='/opt/local/etc/nginx/conf.d' #not really used yet
WEB_DIR="/home/admin/BuildAgent/work/www/$1/$3"

SED=`which sed`

#CURRENT_DIR=`dirname $0`


DOMAIN=$2

if [ -z $2 ]; then
  echo "No domain name given"
  exit 1
fi
 
#backup previous nginx config file
NGINX_MAIN_FILE='nginx.conf' 
if [[ -e $NGINX_MAIN_FILE.ext ]] ; then
    i=0
    while [[ -e $NGINX_MAIN_FILE-$i.ext ]] ; do
        let i++
    done
    NGINX_MAIN_FILE=$NGINX_MAIN_FILE-$i
fi
mv $NGINX_DIR/nginx.conf $NGINX_DIR/NGINX_MAIN_FILE

wget https://raw.githubusercontent.com/that0n3guy/smartos-zone-java-ssl/master/nginx.conf.template
mv nginx.conf.template $NGINX_DIR/nginx.conf
rm nginx.conf.template

mkdir -p $NGINX_CONFIG
mkdir -p $NGINX_SITES_ENABLED
mkdir -p $NGINX_EXTRA_CONFIG

# check the domain is roughly valid!
PATTERN="^([[:alnum:]]([[:alnum:]\-]{0,61}[[:alnum:]])?\.)+[[:alpha:]]{2,6}$"
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Creating hosting for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi

#Replace dots with underscores
SITE_DIR=`echo $DOMAIN | $SED 's/\./_/g'`

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$DOMAIN

wget https://raw.githubusercontent.com/that0n3guy/smartos-zone-java-ssl/master/virtual_host.template
cp virtual_host.template $CONFIG
rm virtual_host.template

sudo $SED -i "s/DOMAIN/$DOMAIN/g" $CONFIG
sudo $SED -i "s!ROOT!$WEB_DIR!g" $CONFIG

# set up web root
#sudo mkdir $WEB_DIR/$SITE_DIR
sudo chown nginx:nginx -R $WEB_DIR
sudo chmod 600 $CONFIG

# create symlink to enable site
sudo ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN

# reload Nginx to pull in new config
nginx -s reload

# put the template index.html file into the new domains web dir
#sudo cp $CURRENT_DIR/index.html.template $WEB_DIR/$SITE_DIR/index.html
#sudo $SED -i "s/SITE/$DOMAIN/g" $WEB_DIR/$SITE_DIR/index.html
#sudo chown nginx:nginx $WEB_DIR/$SITE_DIR/index.html

ln -s $NGINX_CONFIG/$DOMAIN $NGINX_SITES_ENABLED/$DOMAIN

echo "Site Created for $DOMAIN"