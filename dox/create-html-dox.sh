#! /bin/sh

# grab all files

if [ ! -d "../dox" ]
then
   echo "must be run in dox folder" 1>&2
   exit 1
fi

# stop on failure
set -e

cp -rp *.scion /tmp/MulleScionDox
mulle-scion -w &
PID=$#

sleep 2
wget -E -nd -P html -m http://127.0.0.1:18048

cd html
for i in *wrapper=_wrapper.scion*
do
   file=`echo "$i" | sed 's/^\(.*\)\.scion\?wrapper=_wrapper.scion\(.*\)/\1\2/'`
   mv "$i" "$file"
done

for i in *.html
do
   mv "$i" "$i.orig"
   cat "$i.orig" | sed 's/\([A-Za-z0-9_|!]*\)\.scion\?wrapper=_wrapper.scion/\1.html/g' > "$i"
   rm "$i.orig"
done


kill $PID

