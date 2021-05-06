files=$@
if [ "$#" -eq 0 ]; then
    files=(Sources/ Tests/ Example/)
fi

YEAR=`date "+%Y"`
if [ $YEAR = "2021" ]; then
    YEARSTR="2021"
else
    YEARSTR="2021 - $YEAR"
fi

copyright="
// MIT License
// 
// Copyright (c) $YEARSTR Sanity.io
"

swiftformat \
    --swiftversion 5.4 \
    --disable redundantSelf,enumNamespaces,redundantFileprivate \
    --header "$copyright" \
    "${files[@]}"
