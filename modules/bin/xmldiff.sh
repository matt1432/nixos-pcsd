# Dependencies
# - diffutils
# - libxml2

if cmp -s <(xmllint --c14n "$1") <(xmllint --c14n "$1"); then
    echo "same"
else
    echo "different"
fi
