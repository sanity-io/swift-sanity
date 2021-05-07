files=$@
if [ "$#" -eq 0 ]; then
    files=(Sources/ Tests/ Example/)
fi

swiftformat "${files[@]}"
