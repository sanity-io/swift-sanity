files=$@
if [ "$#" -eq 0 ]; then
    files=(Sources/ Tests/ Example/)
fi

copyright="\
\n\
The MIT License (MIT)\nCopyright (C) 2021 - `date +'%Y'`.\n\
"

swiftformat \
    --swiftversion 5.4 \
    --disable redundantSelf,enumNamespaces,redundantFileprivate \
    --header "$copyright" \
    "${files[@]}"
