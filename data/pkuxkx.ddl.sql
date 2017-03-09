create table if not exists rooms (
  id integer primary key AUTOINCREMENT,
  name text,
  code text,
  description text,
  exits text,
  zone text,
  mapinfo text
);
create table if not exists paths (
  startid integer,
  endid integer,
  path text,
  endcode text
);
create index if not exists idx_paths on paths (startid, endid);

create table if not exists pinyin2chr (
  pinyin text primary key,
  chr text
);
create table if not exists chr2pinyin (
  chr text primary key,
  pinyin text
);

insert into rooms (id, name, code, description, exits, zone, mapinfo)
select nodeno, nodename, nodeid, description, exits, zone, relation
from mud_node;

insert into paths (startid, endid, path, endcode)
select nodeno, linknodeno, path, linknodeid
from mud_links;

--.separator ':'
--.import char2pinyin.csv chr2pinyin
--.import pinyin2char.csv pinyin2chr
