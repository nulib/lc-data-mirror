# Using the LC Data Mirror

## Virtuoso

This documentation uses the [Virtuoso RDF Open-Source Edition](https://vos.openlinksw.com/owiki/wiki/VOS/VOSRDF) triplestore to create a highly performant database that can be queried efficiently using SPARQL.

### Starting the server

1. Make sure you have sufficient space for the database, which will take around 30GB when fully loaded and indexed.
2. Edit the [config file](virtuoso/virtuoso.ini) to best reflect your system's resources, using the guidelines on lines 85-109.
3. Start the server:
    ```shell
    cd virtuoso
    docker compose up -d
    ```

### Loading data

Most of the data can be loaded and indexed in a matter of minutes, but loading and indexing the Name Authority File (`authorities/names.skosrdf.ttl.gz`) can take many hours due to its size.

1. Start the command-line iSQL interface:
    ```
    docker compose exec virtuoso isql
    ```
2. Configure the `labels` index:
    ```
    RDF_OBJ_FT_RULE_DEL (NULL, NULL, 'ALL');
    RDF_OBJ_FT_RULE_DEL (NULL, NULL, 'All');
    RDF_OBJ_FT_RULE_ADD (NULL, 'http://www.w3.org/2004/02/skos/core#prefLabel', 'labels');
    RDF_OBJ_FT_RULE_ADD (NULL, 'http://www.w3.org/2004/02/skos/core#altLabel', 'labels');
    VT_BATCH_UPDATE ('DB.DBA.RDF_OBJ', 'ON', 120);
    ```
3. Tell virtuoso which files to bulk load:
    ```
    ld_dir('/data/authorities', 'names.skosrdf.ttl.gz', 'http://id.loc.gov/authorities/names');
    ld_dir('/data/authorities', 'subjects.skosrdf.ttl.gz', 'http://id.loc.gov/authorities/subjects');
    ld_dir('/data/authorities', 'genreForms.skosrdf.ttl.gz', 'http://id.loc.gov/authorities/genreForms');
    ld_dir('/data/vocabulary', 'languages.skosrdf.ttl.gz', 'http://id.loc.gov/vocabulary/languages');
    ```
4. Run the bulk loader:
    ```
    rdf_loader_run();
    ```
    ***Note:** On an 8-core, 32GB Linux system, this load took about 20 minutes.*
5. When the bulk loader finishes, set a checkpoint and build the index:
    ```
    checkpoint;
    ```

### Querying data

SPARQL requests can be sent to the virtuoso server on `http://localhost:8890/sparql` (or whatever hostname your server is listening on), e.g.:

```http
POST /sparql
Accept: application/json
Content-Type: application/sparql-query

SELECT ?s ?p ?o
LIMIT 100
```

#### Fetching the label and variants for a specific ID

```sparql
SELECT ?id ?label (GROUP_CONCAT(DISTINCT ?variant; separator="|") AS ?variants)
WHERE {
  VALUES ?id { <http://id.loc.gov/authorities/subjects/sh85017416> }

  OPTIONAL {  
    ?id skos:prefLabel ?label_en .
    FILTER(LANGMATCHES(LANG(?label_en), "en"))
  }
  ?id skos:prefLabel ?label_any .
  BIND(COALESCE(?label_en, ?label_any) AS ?label)

  OPTIONAL {
    ?id skos:altLabel ?variant .
    FILTER(LANGMATCHES(LANG(?variant), "en"))
  }
}
```

#### Searching for a particular label (or variant) based on a left-anchored stem
```sparql
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
  
SELECT ?id ?label (GROUP_CONCAT(DISTINCT ?variant; separator="|") AS ?variants)
WHERE {
  GRAPH <http://id.loc.gov/authorities/subjects> {
    {
      ?id skos:prefLabel ?label .
      ?label bif:contains "'apple*'" OPTION (score ?sc) .
      FILTER(STRSTARTS(LCASE(?label), "apple"))
      OPTIONAL {
        ?id skos:altLabel ?variant .
        FILTER(LANGMATCHES(LANG(?variant), "en"))
      }
    } UNION {
      ?id skos:prefLabel ?label .
      ?id skos:altLabel ?variant_match .
      ?variant_match bif:contains "'apple*'" OPTION (score ?sc) .
      FILTER(STRSTARTS(LCASE(?variant_match), "apple"))        
      ?id skos:altLabel ?variant .
      FILTER(LANGMATCHES(LANG(?variant), "en"))
    }
  }
}
ORDER BY DESC(?sc)
LIMIT 20
```