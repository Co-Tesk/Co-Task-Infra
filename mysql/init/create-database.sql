drop database if exists `user_service_db`;
drop database if exists `project_service_db`;
drop database if exists `task_service_db`;

create database if not exists `user_service_db` character set utf8mb4 collate utf8mb4_unicode_ci;
create database if not exists `project_service_db` character set utf8mb4 collate utf8mb4_unicode_ci;
create database if not exists `task_service_db` character set utf8mb4 collate utf8mb4_unicode_ci;
