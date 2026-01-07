#!/bin/bash
dl() {
  local url=https://id.loc.gov/download/$1
  local dest=data/$1

  mkdir -p "$(dirname "$dest")"

  local ims=()
  if [ -f "$dest" ]; then
    # Get the file's last modified time in HTTP-date format
    ims=(-H "If-Modified-Since: $(date -R -r "$dest")")
  fi

  # Download the file, save headers to a temp file
  local headerfile
  headerfile=$(mktemp)
  curl -L -D "$headerfile" "${ims[@]}" -o "$dest" "$url"
  
  # Get Last-Modified header and set file mtime if present
  local lm
  lm=$(grep -i '^Last-Modified:' "$headerfile" | sed 's/Last-Modified: //I' | tr -d '\r')
  if [ -n "$lm" ]; then
    touch -d "$lm" "$dest"
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
done
dl resources/hubs.bibframe.ttl.gz
dl externallinks.nt.gz
