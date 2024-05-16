#!/bin/sh
# Check if package is available
CheckPackage() {
  $(dnf info $1 > /dev/null 2>&1)
  echo $?
}

for i in $@
do
  PACKAGE_AVAILABLE=$(CheckPackage $i)

  if [ $PACKAGE_AVAILABLE -eq 1 ]; then
    echo " > Package $i not available on repo."
    echo "Package Not Found: $i" >> /Unknown_Packages
  else
    echo " > Adding package $i to the install list"
    packages="$packages $i"
  fi
done

echo "$packages" #you could comment this.
cat /Unknown_Packages
dnf install -y $packages
