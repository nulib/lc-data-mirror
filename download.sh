#!/bin/bash
dl() {
  local url=https://id.loc.gov/download/$1
  local dest=data/$1
  curl -L -o $dest $url
}

for t in \
  authorities/names \
  authorities/subjects \
  authorities/childrensSubjects \
  authorities/genreForms \
  authorities/performanceMediums \
  authorities/demographicTerms \
  vocabularies/cataloging \
  vocabularies/relators \
  vocabularies/languages \
  vocabularies/iso639-1 \
  vocabularies/iso639-2 \
  vocabularies/iso639-5 \
  vocabularies/countries \
  vocabularies/geographicAreas \
  vocabularies/organizations \
  vocabularies/graphicMaterials \
  vocabularies/ethnographicTerms; do
    dl $t.madsrdf.ttl.gz
done
dl resources/hubs.bibframe.ttl.gz
dl externallinks.nt.gz
