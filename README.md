# LinkCit
Open Source Citation Matching Software

Instructions

1. MadCit is a subset of madIS database systems. 
You can install MadCit, if you follow the instructions at http://madgik.github.io/madis/install.html

2. Creating a metadata database:

./preprocess.sh ../metadata.json metadata.db

The metadata.json contains the publication metadata as follows:
{"id":"idgivenhere","authorsurnames":"author surnames separated by white space","authorfirstnames":"author first names separated by whitespace","title":"Publication title","publisher":"publisher","publicationYear":"2005"}

3. Processing:

./linkcitations.sh PATH_TO_FULLTEXTS metadata.db

The PATH_TO_FULLTEXTS is a directory which contains just the plaintext files to be matched.
The output is in JSON format and contains the name of the text file and the citation id.

