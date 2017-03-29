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
  enabled integer default 1,
  category integer default 1,
  mapchange integer default 0
);
create index if not exists idx_paths on paths (startid, endid);

create table if not exists path_category (
  id integer primary key AUTOINCREMENT ,
  name text,
  description text
);
create index idx_path_category_name on path_category (name);
insert into path_category (id, name, description) values
  (1, 'normal', '��������'),
  (2, 'multiple', '������ʹ�÷ֺŸ���'),
  (3, 'busy', '�������������busy״̬��������Ҫ����ظ�ִ��'),
  (4, 'boat', '�˴�����');

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
  ('yangzhou', '����', 'yangzhouzhongyangguangchang'),
  ('zhongyuan', '��ԭ', 'zhongyuanxuchang'),
  ('xiaoshancun', 'Сɽ��', 'xiaoshancundaguchang'),
  ('huashan', '��ɽ', 'huashanshufang'),
  ('qufu', '����', 'qufukongmiao'),
  ('xinyang', '����', 'xinyangxiaoguangchang'),
  ('quanzhen', 'ȫ��', 'quanzhenchongxuantai'),
  ('changjiangbei', '��������', 'changjiangbeichangjiangdukou1'),
  ('huanghenan', '�ƺ��ϰ�', 'huanghenanmengjindu'),
  ('luoyang', '����', 'luoyangzhongxingguangchang'),
  ('changan', '����', 'changanzhuquedajie'),
  ('chengdu', '�ɶ�', 'chengduzongdufumenqian'),
  ('tianlongsi', '������', 'tianlongsisanyuangong'),
  ('dali', '����', 'dalizhongxinguangchang'),
  ('yueyang', '����', 'yueyangchengzhongxin'),
  ('jiangzhou', '����', 'jiangzhouzhongyangguangchang'),
  ('nanchang', '�ϲ�', 'nanchangchengzhongxin'),
  ('quanzhou', 'Ȫ��', 'quanzhouchengzhongxin'),
  ('fuzhou', '����', 'fuzhouchengzhongxin'),
  ('jiaxing', '����', 'jiaxingjiaxingcheng'),
  ('yashan', '��ɽ', 'yashanyashanwanzhongxin'),
  ('mingzhou', '����', 'mingzhoumingzhoufu'),
  ('suzhou', '����', 'suzhoubaodaiqiao'),
  ('zhenjiang', '��', 'zhenjiangguangchang'),
  ('dufu', '����', 'dufudating'),
  ('jiankang', '����', 'jiankangzhongcheng'),
  ('linan', '�ٰ�', 'linanfudalisi'),
  ('changjiangnan', '�����ϰ�', 'changjiangnanyanziji'),
  ('lingzhou', '����', 'lingzhouchengzhongxin'),
  ('dalunsi', '������', 'dalunsizhudubadian'),
  ('huizuxiaozhen', '����С��', 'huizuxiaozhenxiaozhen'),
  ('qilincun', '�����', 'qilincunxiaoguangchang'),
  ('kunming', '����', 'kunmingzhongxinguangchang'),
  ('pingxiwangfu', 'ƽ������', 'pingxiwangfupingxiwangfudamen')
;
--   ('taishan', '̩ɽ');

create table if not exists zone_connectivity (
  startcode text,
  endcode text,
  weight integer,
  busy integer not null default 0,
  boat integer not null default 0,
  primary key (startcode, endcode)
);

insert into zone_connectivity (startcode, endcode, weight)
values
  ('huashan', 'xiaoshancun', 13),    -- use 13 or 20?
  ('xiaoshancun', 'huashan', 13),
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
  ('changjiangbei', 'xinyang', 15),
  ('xinyang', 'changjiangbei', 15),
  ('huanghenan', 'qufu', 11),
  ('qufu', 'huanghenan', 11),
  ('luoyang', 'huanghenan', 8),
  ('huanghenan', 'luoyang', 8),
  ('luoyang', 'zhongyuan', 9),
  ('zhongyuan', 'luoyang', 9),
  ('huashan', 'changan', 15),  -- use 15 or 22?
  ('changan', 'huashan', 15),
  ('huanghenan', 'changan', 18),
  ('changan', 'huanghenan', 18),
  ('luoyang', 'changan', 18),
  ('changan', 'luoyang', 18),
  ('changan', 'chengdu', 19),
  ('chengdu', 'changan', 19),
  ('tianlongsi', 'chengdu', 11),
  ('chengdu', 'tianlongsi', 11),
  ('tianlongsi', 'dali', 11),
  ('dali', 'tianlongsi', 11),
  ('chengdu', 'yueyang', 15),
  ('yueyang', 'chengdu', 15),
  ('yueyang', 'jiangzhou', 10),
  ('jiangzhou', 'yueyang', 10),
  ('jiangzhou', 'nanchang', 10),
  ('nanchang', 'jiangzhou', 10),
  ('nanchang', 'quanzhou', 9),
  ('quanzhou', 'nanchang', 9),
  ('quanzhou', 'fuzhou', 9),
  ('fuzhou', 'quanzhou', 9),
  ('quanzhou', 'jiaxing', 5),
  ('jiaxing', 'quanzhou', 5),
  ('jiaxing', 'yashan', 13),
  ('yashan', 'jiaxing', 13),
  ('yashan', 'mingzhou', 4),
  ('mingzhou', 'yashan', 4),
  ('mingzhou', 'jiaxing', 7),
  ('jiaxing', 'mingzhou', 7),
  ('jiaxing', 'suzhou', 5),
  ('suzhou', 'jiaxing', 5),
  ('suzhou', 'zhenjiang', 17),
  ('zhenjiang', 'suzhou', 17),
  ('dufu', 'jiankang', 8),
  ('jiankang', 'dufu', 8),
  ('jiankang', 'suzhou', 21),
  ('suzhou', 'jiankang', 21),
  ('jiankang', 'jiaxing', 22),
  ('jiaxing', 'jiankang', 22),
  ('jiankang', 'zhenjiang', 16),
  ('zhenjiang', 'jiankang', 16),
  ('jiankang', 'jiangzhou', 14),
  ('jiangzhou', 'jiankang', 14),
  ('jiankang', 'linan', 19),
  ('linan', 'jiankang', 19),
  ('linan', 'quanzhou', 14),
  ('quanzhou', 'linan', 14),
  ('yueyang', 'changjiangnan', 19),
  ('changjiangnan', 'yueyang', 19),
  ('jiangzhou', 'changjiangnan', 12),
  ('changjiangnan', 'jiangzhou', 12),
  ('jiankang', 'changjiangnan', 12),
  ('changjiangnan', 'jiankang', 12),
  ('zhenjiang', 'changjiangnan', 11),
  ('changjiangnan', 'zhenjiang', 11),
  ('suzhou', 'changjiangnan', 22),
  ('changjiangnan', 'suzhou', 22),
  ('changjiangbei', 'changjiangnan', 1),
  ('changjiangnan', 'changjiangbei', 1),
  ('huanghenan', 'lingzhou', 17),
  ('lingzhou', 'huanghenan', 17),
  ('lingzhou', 'dalunsi', 16),  -- use zanpu as connect-point
  ('dalunsi', 'lingzhou', 16),
  ('dalunsi', 'chengdu', 13),  -- use zanpu as connect-point
  ('chengdu', 'dalunsi', 13),
  ('huanghenan', 'huizuxiaozhen', 21),
  ('huizuxiaozhen', 'huanghenan', 21),
  ('huizuxiaozhen', 'changan', 10),
  ('changan', 'huizuxiaozhen', 10),
  ('luoyang', 'qilincun', 13),
  ('qilincun', 'luoyang', 13),
  ('dali', 'kunming', 11),
  ('kunming', 'dali', 11),
  ('kunming', 'pingxiwangfu', 7),
  ('pingxiwangfu', 'kunming', 7)
;

update zone_connectivity set boat = 1
where (startcode = 'changjiangnan' and endcode = 'changjiangbei')
or (startcode = 'changjiangbei' and endcode = 'changjiangnan');

--.separator ':'
--.import char2pinyin.csv chr2pinyin
--.import pinyin2char.csv pinyin2chr
