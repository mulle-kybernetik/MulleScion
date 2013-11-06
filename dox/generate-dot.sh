#! /bin/sh  -x
# ###########################################################################
# $Id$
# (c) 2013 Mulle kybernetiK
# coded by Nat!
# ###########################################################################

input=${1:-"../src/MulleScionObjectModel.h"}
shift
open=${1:-yes}
shift


create_dot_header()
{
   name="$1"
   shift
   orientation="$1"
   shift

   echo "digraph $name
{"
   if [ "$orientation" = "LR" ]
   then
      echo "   rankdir=LR;"
   fi

   echo "" 
}


create_dot_footer()
{
   echo "}"
}


create_dot()
{
   local name

   name=`basename "$1"`
   name=`basename "$name" .h`
   create_dot_header "name" "$2"

   grep @interface "$1" | awk '{ print $2 "-> " $4 ";" }' 

   create_dot_footer 
}


output=dox/`basename "$input" .h`.dot

create_dot "$input" "LR" i > "$output"

if [ "$open" = "yes" ]
then
   open "$output" 
fi
 
