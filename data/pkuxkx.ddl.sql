create table if not exists rooms (
  id integer primary key AUTOINCREMENT,
  name text,
  code text,
  description text,
  exits text,
  zone text,
  mapinfo text
);
create unique index idx_rooms on rooms (code);

create table if not exists paths (
  startid integer,
  endid integer,
  path text,
  endcode text,
  weight integer default 1,
  enabled integer default 1
);
create index if not exists idx_paths on paths (startid, endid);

create table if not exists pinyin2chr (
  pinyin text primary key,
  chr text
);
create table if not exists chr2pinyin (
  chr text primary key,
  unicode integer,
  pinyin text
);
create index if not exists idx_chr2pinyin on chr2pinyin (unicode);

-- insert into rooms (id, name, code, description, exits, zone, mapinfo)
-- select nodeno, nodename, nodeid, description, exits, zone, relation
-- from mud_node;
--
-- insert into paths (startid, endid, path, endcode)
-- select nodeno, linknodeno, path, linknodeid
-- from mud_links;

create table if not exists zones (
  id integer primary key AUTOINCREMENT,
  code text unique,
  name text,
  centercode text
);

insert into zones (code, name, centercode)
values
  ('yangzhou', '扬州', 'yangzhouzhongyangguangchang'),
  ('zhongyuan', '中原', 'zhongyuanxuchang'),
  ('xiaoshancun', '小山村', 'xiaoshancundaguchang'),
  ('huashan', '华山', 'huashanshufang'),
  ('qufu', '曲阜', 'qufukongmiao'),
  ('xinyang', '信阳', 'xinyangxiaoguangchang'),
  ('quanzhen', '全真', 'quanzhenchongxuantai'),
  ('changjiangbeian', '长江北岸', 'changjiangbeianchangjiangdukou1')
;
--   ('taishan', '泰山');

create table if not exists zone_connectivity (
  startcode text,
  endcode text,
  weight integer,
  primary key (startcode, endcode)
);

insert into zone_connectivity (startcode, endcode, weight)
values
  ('huashan', 'xiaoshancun', 20),
  ('xiaoshancun', 'huashan', 20),
  ('xiaoshancun', 'zhongyuan', 8),
  ('zhongyuan', 'xiaoshancun', 8),
  ('zhongyuan', 'yangzhou', 10),
  ('yangzhou', 'zhongyuan', 10),
  ('yangzhou', 'qufu', 10),
  ('qufu', 'yangzhou', 10),
  ('qufu', 'zhongyuan', 12),
  ('zhongyuan', 'qufu', 12),
  ('xinyang', 'yangzhou', 10),
  ('yangzhou', 'xinyang', 10),
  ('xinyang', 'zhongyuan', 6),
  ('zhongyuan', 'xinyang', 6),
  ('xiaoshancun', 'quanzhen', 13),
  ('quanzhen', 'xiaoshancun', 13),
  ('changjiangbeian', 'yangzhou', 12),
  ('yangzhou', 'changjiangbeian', 12),
  ('changjiangbeian', 'xinyang', 15),
  ('xinyang', 'changjiangbeian', 15)
;


--.separator ':'
--.import char2pinyin.csv chr2pinyin
--.import pinyin2char.csv pinyin2chr
