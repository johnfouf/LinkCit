# ReCital
Open Source implementation of a Relational Citation Matching Algorithm

Instructions

1. Installation
   Requirements: 
   * Python 2.6.x or 2.7.x. You can download a windows distribution of Python from http://www.python.org/download/releases/ .
   You need to download the latest Python in the 2.6 or 2.7 series. ReCital doesn't work with Python 3.0.
   * APSW. If you use Ubuntu, install the python-apsw package: 
            
           sudo apt-get install python-apsw 
     
     If you are using MAC, you have to install APSW and readline via easy_install:

           *easy_install apsw
           *easy_install readline
     
     Otherwise, download APSW from https://github.com/rogerbinns/apsw and install it following the instructions.

2. Creating a metadata database:

./preprocess.sh ../metadata.json metadata.db

The metadata.json contains the publication metadata as follows:
{"id":"idgivenhere","authorsurnames":"author surnames separated by white space","authorfirstnames":"author first names separated by whitespace","title":"Publication title","publisher":"publisher","publicationYear":"2005"}

3. Processing:

./linkcitations.sh PATH_TO_FULLTEXTS metadata.db

The PATH_TO_FULLTEXTS is a directory which contains just the plaintext files to be matched.
The output is in JSON format and contains the name of the text file and the citation id.

