-- Курсовой проект. База данных видеостримингово сервиса Twitch.tv.

-- Автор: Шенк Евгений Станиславович

DROP DATABASE IF EXISTS db_twitch;
CREATE DATABASE db_twitch;

USE db_twitch;

	-- Accounts
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL COMMENT 'Логин пользователя',
  email VARCHAR(150) UNIQUE NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX users_username_idx (username),
  INDEX users_email_idx (email)
)COMMENT = 'Идентификационные данные пользователей';

CREATE TABLE pictures(
  id SERIAL PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(50) NOT NULL,
  filename VARCHAR(255) NOT NULL UNIQUE,
  size INT NOT NULL,
  metadata JSON,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX pictures_user_id_idx (user_id),
  INDEX pictures_name_idx (name),
  CONSTRAINT pictures_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id)
)COMMENT = 'Изображения';

CREATE TABLE profiles (
  user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  display_name VARCHAR(50) NOT NULL COMMENT 'Имя, которое будет отображаться для других пользователей',
  picture_id BIGINT UNSIGNED,
  banner_id BIGINT UNSIGNED,
  bio TEXT COMMENT 'Информация о пользователе',
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX profiles_display_name_idx (display_name),
  CONSTRAINT profiles_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT profiles_picture_id_fk FOREIGN KEY (picture_id) REFERENCES pictures(id),
  CONSTRAINT profiles_banner_id_fk FOREIGN KEY (banner_id) REFERENCES pictures(id)
)COMMENT = 'Данные профиля пользователя';

CREATE TABLE content_types (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW()
)COMMENT = 'Таблица типов контента ';

CREATE TABLE content (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW()
)COMMENT = 'Таблица названий контента';

CREATE TABLE content_groups (
  name_id BIGINT UNSIGNED NOT NULL,
  type_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  PRIMARY KEY (name_id, type_id),
  CONSTRAINT content_groups_name_id_fk FOREIGN KEY (name_id) REFERENCES content(id),
  CONSTRAINT content_groups_type_id_fk FOREIGN KEY (type_id) REFERENCES content_types(id)
)COMMENT = 'Таблица соотношений типов с названиями (у одного типа много позиций и одна позиция может быть ко многим типам)';

	-- Channels
CREATE TABLE channels (
  user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  info MEDIUMTEXT COMMENT 'Информация о канале',
  banner_id BIGINT UNSIGNED,
  content_id BIGINT UNSIGNED COMMENT 'Транслируемым контента (название игры и т.д.)',
  viewers BIGINT UNSIGNED NOT NULL DEFAULT '0',
  channel_options JSON COMMENT 'Настройки канала: правила ретрансляции, разрешения и т.д.',
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX channels_name_idx (name),
  CONSTRAINT channels_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT channels_banner_id_fk FOREIGN KEY (banner_id) REFERENCES pictures(id),
  CONSTRAINT channels_content_id_fk FOREIGN KEY (content_id) REFERENCES content(id)
)COMMENT = 'Данные канала';

	-- Subs
CREATE TABLE followers (
  user_id BIGINT UNSIGNED NOT NULL COMMENT 'Кто следует',
  channel_id BIGINT UNSIGNED NOT NULL COMMENT 'За кем следует',
  status TINYINT(1) NOT NULL DEFAULT '1' COMMENT 'действующее или нет',
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  PRIMARY KEY (user_id, channel_id),
  CONSTRAINT followers_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT followers_channel_id_fk FOREIGN KEY (channel_id) REFERENCES users(id)
)COMMENT = 'Последователи';

CREATE TABLE hosting_list (
  user_id BIGINT UNSIGNED NOT NULL COMMENT 'Кто ретранслирует',
  channel_id BIGINT UNSIGNED NOT NULL COMMENT 'Кого ретранслирует',
  status TINYINT(1) NOT NULL DEFAULT '1' COMMENT 'действующее или нет',
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  PRIMARY KEY (user_id, channel_id),
  CONSTRAINT hosting_list_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT hosting_list_channel_id_fk FOREIGN KEY (channel_id) REFERENCES users(id)
)COMMENT = 'Список каналов для ретрансляции';

CREATE TABLE subscription_types (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  sub_type VARCHAR(50) UNIQUE NOT NULL COMMENT 'Тип подписки',
  price DECIMAL(6,2) UNSIGNED NOT NULL,
  description VARCHAR(255) COMMENT 'Описание что входит в подписку'
)COMMENT = 'Типы подписок';

CREATE TABLE subscriptions (
  user_id BIGINT UNSIGNED NOT NULL COMMENT 'Кто подписан',
  channel_id BIGINT UNSIGNED NOT NULL COMMENT 'На кого подписан',
  type_id INT UNSIGNED NOT NULL,
  gifted BIGINT UNSIGNED COMMENT 'NULL – подписка от пользователя, либо id пользователя который подарил',
  created_at DATETIME DEFAULT NOW(),
  end_time DATETIME,
  PRIMARY KEY (user_id, created_at),
  INDEX subscriptions_type_id_idx (type_id),
  INDEX subscriptions_channel_id_idx (channel_id),
  CONSTRAINT subscriptions_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT subscriptions_channel_id_fk FOREIGN KEY (channel_id) REFERENCES users(id),
  CONSTRAINT subscriptions_type_id_fk FOREIGN KEY (type_id) REFERENCES subscription_types(id)
)COMMENT = 'Подписки';

CREATE TABLE subscription_gifts (
  channel_id BIGINT UNSIGNED NOT NULL COMMENT 'Канал, на который подписка',
  picture_id BIGINT UNSIGNED NOT NULL COMMENT 'Картинка (обычно смайлик), для использования в чате',
  min_sub_requirements_id INT UNSIGNED NOT NULL DEFAULT '1' COMMENT 'id минимального уровеня подписки для получения', 
  min_sub_time INT UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Минимальное время подписки на канал (в месяцах)',
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  PRIMARY KEY (channel_id, picture_id),
  CONSTRAINT subscription_gifts_channel_id_fk FOREIGN KEY (channel_id) REFERENCES users(id),
  CONSTRAINT subscription_gifts_picture_id_fk FOREIGN KEY (picture_id) REFERENCES pictures(id),
  CONSTRAINT subscription_gifts_min_sub_requirements_id_fk FOREIGN KEY (min_sub_requirements_id) REFERENCES subscription_types(id)
)COMMENT = 'Награды за подписку';

-- Coomunication
CREATE TABLE communication_types (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW()
)COMMENT = 'Типы коммуникации';

CREATE TABLE messages (
  from_user_id BIGINT UNSIGNED NOT NULL,
  to_user_id BIGINT UNSIGNED NOT NULL,
  type_id INT UNSIGNED NOT NULL,
  body TEXT NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  PRIMARY KEY (from_user_id, created_at),
  INDEX messages_to_user_id_idx (to_user_id), 
  INDEX messages_type_id_idx (type_id),
  CONSTRAINT messages_from_user_id_fk FOREIGN KEY (from_user_id) REFERENCES users(id),
  CONSTRAINT messages_to_user_id_fk FOREIGN KEY (to_user_id) REFERENCES users(id),
  CONSTRAINT messages_type_id_id_fk FOREIGN KEY (type_id) REFERENCES communication_types(id)
)COMMENT = 'Сообщения';

CREATE TABLE mute_list (
  user_id BIGINT UNSIGNED NOT NULL COMMENT 'Кто заглушил',
  to_user_id BIGINT UNSIGNED NOT NULL COMMENT 'Кого заглушил',
  type_id INT UNSIGNED NOT NULL COMMENT 'Тип коммуникации, который заглушили',
  status TINYINT(1) NOT NULL DEFAULT '1' COMMENT 'действующее или нет',
  reason VARCHAR(255),
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  end_time DATETIME,
  PRIMARY KEY (user_id, to_user_id, type_id),
  CONSTRAINT mute_list_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id), 
  CONSTRAINT mute_list_to_user_id_fk FOREIGN KEY (to_user_id) REFERENCES users(id), 
  CONSTRAINT mute_list_type_id_id_fk FOREIGN KEY (type_id) REFERENCES communication_types(id) 
)COMMENT = 'Список заглушенных';

CREATE TABLE ban_list (
  admin_id BIGINT UNSIGNED NOT NULL COMMENT 'Кто заблокировал',
  to_user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY COMMENT 'Кого заблокировали',
  permissions JSON COMMENT 'Список типов действий, которые можно заблокировать (username, start broadcast, use chat, etc)',
  status TINYINT(1) NOT NULL DEFAULT '1' COMMENT 'действующее или нет',
  reason VARCHAR(255),
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  end_time DATETIME,
  CONSTRAINT ban_list_admin_id_fk FOREIGN KEY (admin_id) REFERENCES users(id), 
  CONSTRAINT ban_list_to_user_id_fk FOREIGN KEY (to_user_id) REFERENCES users(id)
)COMMENT = 'Список заблокированных'; 
  
 -- Media
CREATE TABLE video(
  id SERIAL PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  filename VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(50) NOT NULL,
  content_id BIGINT UNSIGNED COMMENT 'Название контента (название игры и т.д.)',
  views BIGINT UNSIGNED NOT NULL DEFAULT '0',
  size INT NOT NULL,
  metadata JSON,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX video_user_id_idx (user_id),
  CONSTRAINT video_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT video_content_id_fk FOREIGN KEY (content_id) REFERENCES content(id)
)COMMENT = 'Видео';

	-- Bits(local money)
CREATE TABLE currency_vallet(
  user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  quantity BIGINT UNSIGNED NOT NULL DEFAULT '0',
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  CONSTRAINT bits_vallet_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id)
)COMMENT = 'Локальная валюта (Bits), для поддержки стримеров';

CREATE TABLE currency_transactions(
  from_user_id BIGINT UNSIGNED NOT NULL,
  to_user_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  created_at DATETIME DEFAULT NOW(),
  PRIMARY KEY (from_user_id, created_at),
  INDEX bits_transactions_to_user_id_idx(to_user_id),
  CONSTRAINT bits_transactions_from_user_id_fk FOREIGN KEY (from_user_id) REFERENCES users(id),
  CONSTRAINT bits_transactions_to_user_id_fk FOREIGN KEY (to_user_id) REFERENCES users(id)   
)COMMENT = 'Транзакции локальной валюты (Bits)';


	-- Veiws
CREATE OR REPLACE VIEW users_info AS
SELECT u.username, u.email, p.display_name, c.name AS Channel, p.bio 
FROM users u
  JOIN profiles p
	ON u.id = p.user_id
  JOIN channels c
	ON u.id = c.user_id
ORDER BY u.email;

CREATE OR REPLACE VIEW subscriptions_info AS
SELECT u1.username AS Subscriber, u2.username AS Streamer, sub_t.sub_type
FROM subscriptions sub
  JOIN users u1
	ON sub.user_id = u1.id
  JOIN users u2
	ON sub.channel_id = u2.id
  JOIN subscription_types sub_t
    ON sub.type_id = sub_t.id;

   
	-- Triggers
DELIMITER //
DROP TRIGGER IF EXISTS mute_end_check//
CREATE TRIGGER mute_end_check BEFORE INSERT ON mute_list
FOR EACH ROW
BEGIN
	IF (NEW.created_at >= NEW.end_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled, end time is before creation time';
	END IF;
END//
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS ban_end_check//
CREATE TRIGGER ban_end_check BEFORE INSERT ON ban_list
FOR EACH ROW
BEGIN
	IF (NEW.created_at >= NEW.end_time) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled, end time is before creation time';
	END IF;
END//
DELIMITER ;

	-- Procedures
DELIMITER //
DROP PROCEDURE IF EXISTS data_check//
CREATE PROCEDURE data_check (num BIGINT UNSIGNED)
BEGIN
DECLARE cr DATETIME DEFAULT (SELECT created_at FROM users WHERE id = num);
DECLARE up DATETIME DEFAULT (SELECT updated_at FROM users WHERE id = num);
IF (cr>=NOW()) THEN
	SELECT 'Wrong data, creation date is wrong';
ELSEIF (up>=NOW()) THEN
	SELECT 'Wrong data, update date is wrong';
ELSEIF (cr >= up) THEN
	SELECT 'Wrong data, creation date is more then update';
ELSE
	SELECT 'created_at and updated_at are OK';
END IF;	
END//
DELIMITER ;

