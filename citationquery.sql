PRAGMA temp_store_directory = '.';

create temp table docs
as select * from (setschema 'id, text' select c1 as id, execprogram(null,'cat',c2) as text from dirfiles(.)) where text <>'' and text not null;

create temp table results as select * from (select docid, id, confidence from 
( select docid, id, 

((10*regexpcountdistance(authorsurnames,comprspaces(regexpr("\b(\w{1,2})\b",regexpr(titles||"(.+)",lower(context||" l"))," "))) + 
  10*regexpcountdistance(authorsurnames,comprspaces(regexpr("\b(\w{1,2})\b",regexpr("(.+)"||titles,lower("l "||context))," ")),1) + 
10*regexpcountdistance(authorfirstnames,comprspaces(regexpr("\b(\w{1,2})\b",regexpr(titles||"(.+)",lower(context||" l"))," "))) + 
  10*regexpcountdistance(authorfirstnames,comprspaces(regexpr("\b(\w{1,2})\b",regexpr("(.+)"||titles,lower("l "||context))," ")),1) + 
10*regexpcountdistance(publisher,comprspaces(regexpr("\b(\w{1,2})\b",regexpr(titles||"(.+)",lower(context||" l"))," "))) + 
  10*regexpcountdistance(publisher,comprspaces(regexpr("\b(\w{1,2})\b",regexpr("(.+)"||titles,lower("l "||context))," ")),1) +
   3*regexpcountdistance(year,comprspaces(regexpr("\b(\w{1,2})\b",regexpr(titles||"(.+)",lower(context||" l"))," "))) + 
   3*regexpcountdistance(year,comprspaces(regexpr("\b(\w{1,2})\b",regexpr("(.+)"||titles,lower("l "||context))," ")),1))*1.0
  /(10*calc((regexpcountwords("\s",comprspaces(context)) - regexpcountwords("\s",titles)))) 
 + (regexpcountwords("\s",titles)+1)*1.0/(regexpcountwords("\s",comprspaces(context))+1))*1.0/2 
  as confidence,

authorsurnames,authorfirstnames,titles,year, 
regexprmatches(titles,lower(context)) as match, titles, context 

from     (select docid, lower(stripchars(middle,'_')) as mystart,     prev||' '||middle||' '||next as context   from     (setschema 'docid,prev,middle,next' select id as docid, textwindow2s(normalizetext(textreferences(text,8)),15,3,15) from docs)     ) ,titlesandtriples where mystart = words and match));

select jdict('documentId', docid, 'citationId', id, 'confidenceLevel', confidence) from results where confidence > 0.10;
