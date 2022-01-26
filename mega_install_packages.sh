#!/bin/sh
for i in $@
	do
		if [ -z "$(apt-cache madison $i 2>/dev/null)" ]; then
			echo " > Package $i not available on repo."
			echo "Package Not Found: $i" >> /Unknown_Packages
		else
			echo " > Add package $i to the install list"
			packages="$packages $i"
		fi
	done
echo "$packages" #you could comment this.
apt-get -y install $packages
