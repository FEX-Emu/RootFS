#!/bin/sh
for i in $@
do
  if [ -z "$(pacman -Ss ^$i\$ 2>/dev/null)" ]; then
    echo " > Package $i not available on repo."
    echo "Package Not Found: $i" >> /Unknown_Packages
  else
    echo " > Add package $i to the install list"
    packages="$packages $i"
  fi
done

echo "$packages" #you could comment this.
cat /Unknown_Packages
pacman --noconfirm -S $packages
