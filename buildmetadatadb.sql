-- db optimization
PRAGMA temp_store_directory = '.';
pragma page_size=16384;
pragma default_cache_size=3000;
pragma journal_size_limit = 10000000;
pragma legacy_file_format = false;
pragma synchronous = 1 ;
pragma auto_vacuum=2; 

-- import and preparation
create temp table tempinput
as select id, j2s(authorsurnames) as authorsurnames,j2s(authorfirstnames) as authorfirstnames, title, publisher, publicationYear as year from (setschema 'id, authorsurnames,authorfirstnames, title, publisher, publicationYear' select jdictsplit(c1, 'id', 'authorsurnames','authorfirstnames' , 'title', 'publisher', 'publicationYear') from stdinput()); 

create temp table metadata 
as select id, authorsurnames, authorfirstnames, stripchars(normalizetext(lower(title)),"_") as title, publisher, year from tempinput where title like "% % %";


-- triple creation
create temp table triples 
as select id,middle as words, comprspaces(j2s(prev,middle,next)) as title from (setschema 'id, prev, middle, next' select id,textwindow2s(title,15,3,15) from metadata) group by id, words, title;


-- singularly distinguished titles
create temp table uniquesplittitles 
as select words,titles,ids from (select words,jgroup(title) as titles, jgroup(id) as ids ,count(distinct(id)) as num from triples group by words) where num = 1;

create temp table uniquetitleswithtriples 
as select words,titles,ids from (select max(length(words)) as len,words,titles,ids from uniquesplittitles group by ids);

create index uniquetitleswithtriples_index 
on uniquetitleswithtriples(words,titles,ids);

delete from triples where id in (select ids as id from uniquesplittitles group by id);


-- plurally distinguished titles
create temp table splittitles 
as select words,titles,ids from (select words,jgroup(title) as titles, jgroup(id) as ids ,count(distinct(id)) as num from triples group by words) 
where num <= (select * from (select jgroupuniquelimit(ids,n,(select count(distinct id) from triples)/2) from (select jgroup(id) as ids,count(id) as n from triples group by words order by n asc)));

delete from triples where id in (select id from (select jsplitv(ids) as id from splittitles) group by id);

insert into splittitles 
select words,titles,ids from (select words,jgroup(title) as titles, jgroup(id) as ids ,count(distinct(id)) as num from triples group by words) 
where num <= (select * from (select jgroupuniquelimit(ids,n,(select count(distinct id) from triples)/2) from (select jgroup(id) as ids,count(id) as n from triples group by words order by n asc)));

delete from triples where id in (select id from (select jsplitv(ids) as id from splittitles) group by id);

insert into splittitles
select words,titles,ids from (select words,jgroup(title) as titles, jgroup(id) as ids ,count(distinct(id)) as num from triples group by words);

create temp table titleswithtriplesmaxwords 
as select words,titles,ids from (select max(length(words)) as len,words,titles,ids from splittitles group by ids);


-- id bag of words creation and normalization
create temp table bagofwordsforids 
as select id, title, year,lower(publisher) as publisher,lower(authorsurnames) as authorsurnames, lower(authorfirstnames) as authorfirstnames from metadata;

update bagofwordsforids 
set year = jmergeregexp(jset(s2j(comprspaces(filterstopwords(regexpr('\b\w{1,3}\b',regexpr('\W|_',year,' '),'')))))), publisher = jmergeregexp(jset(s2j(comprspaces(filterstopwords(regexpr('\b\w{1,3}\b',regexpr('\W|_',publisher,' '),'')))))), authorsurnames = jmergeregexp(jset(s2j(comprspaces(filterstopwords(regexpr('\b\w{1,3}\b',regexpr('\W|_',authorsurnames,' '),'')))))),authorfirstnames = jmergeregexp(jset(s2j(comprspaces(filterstopwords(regexpr('\b\w{1,3}\b',regexpr('\W|_',authorfirstnames,' '),''))))));

create index bagofwords_index on bagofwordsforids(id,title,authorsurnames,year,authorfirstnames,publisher);


-- Connect singularly distinguished titles with their bag of words
create temp table uniquetitleswithtriples_bagofwords 
as select id,titles,words , year,publisher,authorsurnames,authorfirstnames from uniquetitleswithtriples, bagofwordsforids where ids = id;

create index uniquetitleswithtriples_bagofwords_index 
on uniquetitleswithtriples_bagofwords(words,titles,year,publisher,authorsurnames,authorfirstnames);


-- Extract singularly distinguished titles from multiple distinguished titles, connect with bag of words and insert into unique titles

insert into uniquetitleswithtriples_bagofwords
select id, titles, words , year, publisher, authorsurnames,authorfirstnames 
from (select * from titleswithtriplesmaxwords where jlen(titles)=1), bagofwordsforids 
where ids = id ;

delete from titleswithtriplesmaxwords where jlen(titles) = 1;


-- Split vertically multiple distinguished titles
create temp table titles 
as select words,titles from titleswithtriplesmaxwords;

create temp table idswords 
as select words,ids from titleswithtriplesmaxwords;

create temp table jsplittitles
as select words,jsplitv(titles) as titles from titles;

create temp table jsplitids 
as select words,jsplitv(ids) as ids from idswords;

create temp table jsplittitlesids 
as select jsplitids.words as words,jsplitids.ids as ids,jsplittitles.titles from jsplitids,jsplittitles where jsplittitles.rowid = jsplitids.rowid;

create temp table distincttitlesidswords 
as select words,titles,ids from (select max(length(words)),words,titles,ids from jsplittitlesids group by titles);

create temp table distincttitlesidswords_bag 
as select id, titles,words,year,publisher,authorsurnames,authorfirstnames from distincttitlesidswords,bagofwordsforids where distincttitlesidswords.ids = bagofwordsforids.id;

create index distincttitlesidswords_index 
on distincttitlesidswords_bag(words,titles,year,publisher,authorsurnames,authorfirstnames);


-- Merge everything into one table
insert into distincttitlesidswords_bag
select * from uniquetitleswithtriples_bagofwords;

create temp table titlesandtriples1 
as select id,titles,words,year,publisher,authorsurnames,authorfirstnames from (select id, max(length(words)),words,year,publisher,authorsurnames,authorfirstnames,titles from distincttitlesidswords_bag group by titles);

drop table if exists titlesandtriples;
create table titlesandtriples 
as select id, lower(titles) as titles, lower(words) as words,year,publisher,authorsurnames,authorfirstnames from (select id, max(length(words)),words,year,publisher,authorsurnames,authorfirstnames,titles from titlesandtriples1  group by id);


create index titlestriples_index 
on titlesandtriples(words,titles,year,publisher,authorsurnames,authorfirstnames);
