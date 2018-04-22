#!/bin/bash
ips=$(ip -o addr show up primary scope global |
      while read -r num dev fam addr rest; do echo ${addr%/*}; done)
hostnamectl set-hostname $1
sudo apt-get update
sudo apt-get install haproxy
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get install python-certbot-apache 
sudo certbot certonly --manual --preffered-challenges dns 
sudo mkdir /etc/haproxy/certs/
sudo cp /etc/letsencrypt/live/$1/*.* /etc/haproxy/
sudo cat /etc/haproxy/fullchain.pem /etc/haproxy/privkey.pem > /etc/haproxy/certs/mykey.pem
sudo rm -rf /etc/haproxy/*.pem 
sudo chown haproxy:haproxy /etc/haproxy/certs/
sudo chmod 500 /etc/haproxy/certs/

sudo echo "
frontend www-http										#το fronted αυτό είναι για μην κρυτπογραφημένη κίνηση "
sudo echo "		bind 	"
sudo echo $ips+":80								#χρησιμοπιείται για τα updates γενικά γιατί πολλοί 
   	reqadd 	X-Forwarded-Proto:\ http					#update clients και των windows δεν υποστηρίζουν
   	default_backend cacheupdates 						#κρυπτογραφημένη κίνηση μεταξύ πελάτη και proxy 
frontend www-https										#Το fronted αυτό είναι για κρυπτογραφημένη κίνηση
   	bind 	"
sudo echo $ips+":443 ssl crt /etc/haproxy/certs/mykey.pem #το πιστοποιητικό για την κρυπτογράφηση 
	reqadd 	X-Forwarded-Proto:\ https					#πρέπει να συμφωνεί με το όνομα της υπηρεσίας
   	default_backend 	cacheboxes						#και να είναι από κανονική αρχή πιστοποίησης (no self-signed)
backend cacheboxes										#Το κανονικό backend με authentication ldap
	cookie SERVERID insert indirect nocache #εισάγω cookie για sticky sessions
	balance uri whole						#το γενικό loadbalance είναι με το hash του url 
	hash-type consistent					
	balance leastconn if {ssl_fc} 			#αν το πρωτόκολλο είναι https κάνω load balance με τις λιγότερες συνδέσεις 
   	server cache03 194.63.239.233:3128	check	cookie cache03
	server cache04 194.63.239.234:3128	check	cookie cache04
	server cache05 194.63.239.235:3128	check	cookie cache05
	server cache06 194.63.239.236:3128	check	cookie cache06
	server cache07 194.63.239.237:3128	check	cookie cache07
	server cache08 194.63.239.238:3128	check	cookie cache08
	server cache09 194.63.239.239:3128	check	cookie cache09
	server cache10 194.63.239.240:3128	check	cookie cache10
	server cache11 194.63.239.241:3128	check	cookie cache11
	server cache12 194.63.239.242:3128	check	cookie cache12
	server cache13 194.63.239.243:3128	check	cookie cache13
	server cache14 194.63.239.244:3128	check	cookie cache14
	server cache15 194.63.239.245:3128	check	cookie cache15
	server cache16 194.63.239.246:3128	check	cookie cache16
backend cacheupdates									#το backend που είναι καθαρά για updates
	balance uri											#δεν χρειάζεται αυθεντικοποίηση αλλα επιτρέπει 
	hash-type consistent								#μόνο κίνηση προς τους update servers 
	server cache01 194.63.239.231:3128	check   		#που έχουν ρυθμιστεί στον squid 
	server cache02 194.63.239.232:3128	check" >> /etc/haproxy/haproxy.cfg
sudo service haproxy restart
