#
# For documentation and help see:
#    https://github.com/mulle-sde/mulle-project
#
#

generate_brew_formula_build()
{
   local project="$1"
   local name="$2"
   local version="$3"

   generate_brew_cmake_formula_build
#   generate_brew_configure_formula_build
#   generate_script_brew_formula_build
#   generate_xcodebuild_brew_formula_build
}


####
#### Example code
####
generate_brew_configure_formula_build()
{
  cat <<EOF

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system "false"
  end
EOF
}


generate_brew_cmake_formula_build()
{
  cat <<EOF

  def install
    system "mulle-sde", "fetch"
    system "xcodebuild", "-configuration", "Release", "DSTROOT=#{prefix}", "install"
  end

  test do
    system "false"
  end
EOF
}


generate_script_brew_formula_build()
{
   cat <<EOF
def install
  system "./bin/installer", "#{prefix}"
end
EOF
}


generate_xcodebuild_brew_formula_build()
{
   cat <<EOF
def install
  system "xcodebuild", "-configuration", "Release", "DSTROOT=#{prefix}", "install"
end
EOF
}



