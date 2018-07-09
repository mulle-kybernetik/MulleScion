# Tests

Fairly simple. There is a .scion file with the template, that is run through
mulle-scion. If there is a .plist file of the same name it is used as the
datasource. Otherwise the default.plist is used.

There will be some output produced by mulle-scion. This output will then be
compared with .stdout and .stderr, which are in the expect subfolder.
 If one a files is missing, the respective output will not be compared.

The test script will search through subfolders recursively.
