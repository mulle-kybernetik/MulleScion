#! /bin/sh


get_version()
{
   if [ -x "./build/Products/Debug/mulle-scion" ]
   then
     ./build/Products/Debug/mulle-scion --version
   fi
}


PROJECT="mulle-scion"
TAG="${1:-`get_version`}"

[ -z "${TAG}" ] && exit 1



git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      echo "\"${name}\" is not a git repository" >&2
      exit 1
   fi

   clean=`git status -s`
   if [ "${clean}" != "" ]
   then
      echo "repository \"${name}\" is tainted" >&2
      exit 1
   fi
}


set -e

git_must_be_clean
git push public master

# seperate step, as it's tedious to remove tag when
# previous push fails

git tag "${TAG}"
git push public master --tags

./generate-brew-formula.sh "${VERSION}" > "../homebrew-software/${PROJECT}.rb"
(
	cd ../homebrew-software ; \
 	git commit -m "${TAG} release of ${PROJECT}" "${PROJECT}.rb" ; \
 	git push origin master
)

