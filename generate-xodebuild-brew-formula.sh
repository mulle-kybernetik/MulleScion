#! /bin/sh
# 
# Generate a formula for mulle-scion stand alone
#
VERSION=${1:-`mulle-agvtool vers -terse | awk -F. '{ print $1 }'`}
shift
PROJECT=${1:-`basename ${PWD}`}
shift
TARGET=${1:-"mulle-scion"}
shift

ARCHIVE="${VERSION}.tar.gz"
ARCHIVEURL="https://github.com/mulle-nat/${PROJECT}/archive/${ARCHIVE}"
HOMEPAGE="http://www.mulle-kybernetik.com/software/git/${PROJECT}"

TMPARCHIVE="/tmp/${PROJECT}-${ARCHIVE}"

if [ ! -f  "${TMPARCHIVE}" ]
then
   curl -s -L -o "${TMPARCHIVE}" "${ARCHIVEURL}"
   if [ $? -ne 0 -o ! -f "${TMPARCHIVE}" ] 
   then
      echo "Download failed" >&2
      exit 1
   fi
else
   echo "using cached file ${TMPARCHIVE} instead of downloading again" >&2
fi

#
# anything less than 17 KB is wrong 
#
size=`du -k "${TMPARCHIVE}" | awk '{ print $ 1}'`
if [ $size -lt 17 ]
then
   echo "Archive truncated or missing" >&2
   cat "${TMPARCHIVE}" >&2
   rm "${TMPARCHIVE}"
   exit 1
fi

HASH=`shasum -p -a 256 "${TMPARCHIVE}" | awk '{ print $1 }'`

cat <<EOF  
class ${PROJECT} < Formula
  homepage "${HOMEPAGE}"
  url "${ARCHIVEURL}"
  version "${VERSION}"
  sha256 "${HASH}"

  depends_on :xcode => :build
#  depends_on "zlib"

  def install
    system "xcodebuild", "-target", "${TARGET}", "DEPLOYMENT_LOCATION=YES", "DSTROOT=/", "INSTALL_PATH=#{bin}"
  end

  test do
    system  "(", "cd", tests", ";", "./run-all-scion-tests.sh" , "#{bin}/${TARGET}", ")"
  end
end
EOF
