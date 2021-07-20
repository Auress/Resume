-- Курсовой проект. База данных видеостримингово сервиса Twitch.tv.

-- Автор: Шенк Евгений Станиславович


USE db_twitch;

	-- Запрос общего количества зрителей по контенту с указанием категорий
SELECT t1.name, GROUP_CONCAT(DISTINCT C) AS Categories, SUM(channels.viewers) AS Num_of_viewers FROM (
  SELECT content.id, content.name, GROUP_CONCAT(DISTINCT c_t.name) AS C 
  FROM content
    JOIN content_groups c_g
	  ON content.id = c_g.name_id
    JOIN content_types c_t
	  ON c_g.type_id = c_t.id
  GROUP BY content.id
  ) t1
  JOIN channels
	ON channels.content_id = t1.id
GROUP BY t1.name
ORDER BY Num_of_viewers DESC;

	-- Запрос каналов за которыми следит пользователь (здесь id=25), с сортировкой по кол-ву смотрящих
SELECT p.display_name AS Name, c.viewers FROM followers AS f
  JOIN users u
	ON f.channel_id = u.id
  JOIN profiles p
	ON f.channel_id = p.user_id
  JOIN channels c
	ON f.channel_id = c.user_id
WHERE f.user_id = '25'
ORDER BY c.viewers DESC;

	-- Запрос пользователей, которые имеют подписку на канал пользователя (здесь id=25)
SELECT c.name, s_t.sub_type FROM subscriptions AS s
  JOIN channels c
    ON s.channel_id = c.user_id
  JOIN subscription_types s_t
    ON s.type_id = s_t.id
WHERE s.user_id = '26';

	-- Запрос пользователя у всех видео которого больше всего просмотров в категории IRL (content_id = 4)
SELECT p.display_name AS Name, Total FROM (
  SELECT user_id, SUM(views) AS Total FROM video
  WHERE content_id = 4
  GROUP BY user_id
  ORDER BY SUM(views) DESC
  LIMIT 1) AS t1
JOIN profiles p
  ON t1.user_id = p.user_id;

 
   	-- Views check
SELECT * FROM users_info; 

SELECT * FROM subscriptions_info;
 
 
  	-- Triggers check
INSERT INTO `mute_list` 
	(`user_id`, `to_user_id`, `type_id`, `status`, `reason`, `created_at`, `updated_at`, `end_time`) 
VALUES ('114', '123', 1, 1, 'Adipisci est quod recusandae et corporis vel voluptates.',
'2018-05-08 04:14:03', '2016-10-21 08:00:14', '2017-01-19 16:02:55');

INSERT INTO `ban_list` 
(`admin_id`, `to_user_id`, `permissions`, `status`, `reason`, `created_at`, `updated_at`, `end_time`) 
VALUES ('1122', '3', NULL, 1, 'Nemo recusandae aut doloribus architecto rem qui.', 
'2018-03-23 05:00:57', '2007-07-30 04:55:38', '2017-10-16 09:11:56');

  	-- Procedures check
CALL data_check(25);

CALL data_check(26);

