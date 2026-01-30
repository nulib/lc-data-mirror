#!/bin/bash
dl() {
  local url=https://id.loc.gov/download/$1
  local dest=data/$1

  echo -n "Downloading $url to $dest"
  mkdir -p "$(dirname "$dest")"

  local inm=()
  if [ -f "$dest.etag" ]; then
    # Read ETag from file
    local etag=$(cat "$dest.etag")
    inm=(-H "If-None-Match: $etag")
  fi
  echo ""

  # Download the file, save headers to a temp file
  local headerfile
  headerfile=$(mktemp)
  curl -L -D "$headerfile" "${inm[@]}" -o "$dest" "$url"
  
  # Save ETag header if present
  local etag
  etag=$(grep -i '^ETag:' "$headerfile" | sed 's/ETag: //I' | tr -d '\r')
  if [ -n "$etag" ]; then
    echo -n "$etag" > "$dest.etag"
  fi

  rm -f "$headerfile"
}

for t in \
  authorities/names \
  authorities/subjects \
  authorities/childrensSubjects \
  authorities/genreForms \
  authorities/performanceMediums \
  authorities/demographicTerms \
  vocabulary/cataloging \
  vocabulary/relators \
  vocabulary/languages \
  vocabulary/iso639-1 \
  vocabulary/iso639-2 \
  vocabulary/iso639-5 \
  vocabulary/countries \
  vocabulary/geographicAreas \
  vocabulary/organizations \
  vocabulary/graphicMaterials \
  vocabulary/ethnographicTerms; do
    dl $t.madsrdf.ttl.gz
    dl $t.skosrdf.ttl.gz
done
dl resources/hubs.bibframe.ttl.gz
dl externallinks.nt.gz
