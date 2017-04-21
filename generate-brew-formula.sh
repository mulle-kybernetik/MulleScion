#! /bin/sh -x
#
# Generate a formula for mulle-scion stand alone
#
PROJECT=MulleScion
TARGET=mulle-scion

HOMEPAGE="https://www.mulle-kybernetik.com/software/git/${PROJECT}"
DESC="Templating Engine in Objective-C"

VERSION="$1"
[ $# -eq 0 ] || shift
ARCHIVEURL="${1:-https://www.mulle-kybernetik.com/software/git/${PROJECT}/tarball/$VERSION}"
[ $# -eq 0 ] || shift
CURLOPTIONS="-s -L"  # -k broken on OS X

usage()
{
   echo "generate-brew-formula.sh VERSION ARCHIVEURL" >&2
   exit 1
}


[ ! -z "$VERSION"     ] || usage
[ ! -z "$ARCHIVEURL"  ] || usage


TMPARCHIVE="/tmp/${PROJECT}-${VERSION}-archive"

if [ ! -f "${TMPARCHIVE}" ]
then
   curl ${CURLOPTIONS} -o "${TMPARCHIVE}" "${ARCHIVEURL}"
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
size="`du -k "${TMPARCHIVE}" | awk '{ print $ 1}'`"
if [ $size -lt 17 ]
then
   echo "Archive truncated or missing" >&2
   cat "${TMPARCHIVE}" >&2
   rm "${TMPARCHIVE}"
   exit 1
fi

HASH="`shasum -p -a 256 "${TMPARCHIVE}" | awk '{ print $1 }'`"

cat <<EOF
class ${PROJECT} < Formula
  homepage "${HOMEPAGE}"
  desc "${DESC}"
  url "${ARCHIVEURL}"
  version "${VERSION}"
  sha256 "${HASH}"

  depends_on "mulle-kybernetik/software/mulle-bootstrap"
  depends_on :xcode => :build
  depends_on :macos => :snow_leopard

#  depends_on "zlib"
  def install
     system "mulle-bootstrap"
     xcodebuild, "install", "-target", "${TARGET}", "DSTROOT=/", "INSTALL_PATH=#{bin}"
  end

  test do
    system pwd
    system "(", "cd tests", ";", "./run-all-scion-tests.sh", "#{bin}/${TARGET}", ")"
  end
end
# FORMULA ${TARGET}.rb
EOF
