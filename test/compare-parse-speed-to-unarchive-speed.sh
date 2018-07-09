#! /bin/bash 

template=$1
shift

# template must have .scion suffix

name=`basename "$template" .scion`
if [ "$name" = "$template" ]
then
  exit 1
fi

if [ ! -f "$template" ]
then
  exit 1
fi

mulle-scion -z "$template" none /tmp/unkeyed.scionz
mulle-scion -Z "$template" none /tmp/keyed.scionz


test()
{
   local template
   local i

   template="$1"
   shift
   echo "$template.." 
   for i in {1..100}
   do
     mulle-scion -z "$template" none /tmp/xxx.scionz
   done
}

echo "Compile plaintext"
time test "$template"
echo "Compile unkeyed"
time test "/tmp/unkeyed.scionz"
echo "Compile keyed"
time test "/tmp/keyed.scionz"
 
