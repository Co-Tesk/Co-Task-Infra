use `user_service_db`;

-- 1. `users` 테이블: 사용자 기본 정보
CREATE TABLE `users`
(
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '사용자 식별 값',
    `email` VARCHAR(100) UNIQUE NOT NULL COMMENT '사용자 이메일(아이디)',
    `password` VARCHAR(255) NOT NULL COMMENT '사용자 비밀번호 (해시값)',
    `nickname` VARCHAR(30) NOT NULL COMMENT '사용자 닉네임',
    `is_verify` BOOLEAN DEFAULT FALSE COMMENT '이메일 인증 여부',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
    `is_deleted` BOOLEAN DEFAULT FALSE COMMENT '삭제 여부', -- ✨ 사용자 소프트 삭제 컬럼 추가
    `deleted_at` DATETIME NULL COMMENT '삭제 일시' -- ✨ 사용자 소프트 삭제 일시 추가
) COMMENT='사용자 정보 테이블';

-- 2. `tokens` 테이블: 사용자 재발급 토큰 (Refresh Token) 저장소
-- 한 사용자는 여러 기기/세션에서 로그인할 수 있으므로, 1:N 관계를 가집니다.
CREATE TABLE `tokens`
(
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '토큰 식별 값',
    `user_id` BIGINT NOT NULL COMMENT '사용자 식별 값 (FK)',
    `token` VARCHAR(255) UNIQUE NOT NULL COMMENT '재발급 토큰 (Refresh Token)',
    `expired_date` DATETIME NOT NULL COMMENT '토큰 만료일',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) COMMENT='재발급 토큰 저장소 (Refresh Token)';

-- 3. `verifies` 테이블: 이메일/비밀번호 인증 코드 저장소
-- 인증 타입, 코드, 만료 시간, 사용 여부를 관리합니다.
CREATE TABLE `verifies`
(
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '인증 식별 값',
    `user_id` BIGINT NOT NULL COMMENT '사용자 식별 값 (FK)',
    `type` ENUM('EMAIL', 'PASSWORD') NOT NULL COMMENT '인증 타입: 이메일, 비밀번호',
    `code` VARCHAR(36) NOT NULL COMMENT '인증 코드 (UUID 형태 예상)',
    `expires_at` DATETIME NOT NULL COMMENT '만료 시간 (생성 시각으로부터 1시간)',
    `is_used` BOOLEAN DEFAULT FALSE COMMENT '사용 여부',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) COMMENT='이메일/비밀번호 인증 토큰 저장소';

use `project_service_db`;

-- 4. `projects` 테이블: 프로젝트 기본 정보
CREATE TABLE `projects`
(
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '프로젝트 식별 값',
    `creator_user_id` BIGINT NOT NULL COMMENT '프로젝트 생성자 사용자 식별 값 (FK)',
    `name` VARCHAR(100) NOT NULL COMMENT '프로젝트 제목',
    `description` TEXT COMMENT '프로젝트 설명 (옵션)',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시각',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시각',
    `is_deleted` BOOLEAN DEFAULT FALSE COMMENT '삭제 여부',
    `deleted_at` DATETIME NULL COMMENT '삭제 일시'
) COMMENT='프로젝트 정보 테이블';

-- 5. `project_members` 테이블: 프로젝트와 사용자 간의 N:M 관계 및 권한 관리
-- 복합 기본 키 (user_id, project_id)를 사용하여 고유한 멤버 관계를 정의합니다.
CREATE TABLE `project_members`
(
    `user_id` BIGINT NOT NULL COMMENT '사용자 식별 값 (FK)',
    `project_id` BIGINT NOT NULL COMMENT '프로젝트 식별 값 (FK)',
    `role` ENUM('MEMBER', 'VIEWER') NOT NULL COMMENT '프로젝트 별 사용자의 권한',
    PRIMARY KEY (`user_id`, `project_id`), -- 복합 기본 키
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) COMMENT='프로젝트에 참여한 멤버 정보 테이블';

-- 6. `project_invites` 테이블: 프로젝트 초대 코드 관리
-- 프로젝트별 고유한 초대 코드를 관리하며, 만료 타입과 일수를 포함합니다.
-- 초대 코드는 특정 기간/횟수 이후 만료되므로, 소프트 삭제보다는 만료 기간으로 관리하는 것이 일반적입니다.
CREATE TABLE `project_invites`
(
    `project_id` BIGINT NOT NULL COMMENT '프로젝트 식별 값 (FK)',
    `code` VARCHAR(255) UNIQUE NOT NULL COMMENT '초대코드 (UUID 형태 예상, 프로젝트 내 유니크)',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '초대코드 생성일',
    `expires_type` ENUM('NONE', 'DATE') DEFAULT 'NONE' COMMENT '만료 타입: NONE (만료 없음), DATE (만료일 있음)',
    `date` INT NULL COMMENT '생성일로부터 더할 일수 (expires_type이 DATE일 경우)',
    PRIMARY KEY (`project_id`, `code`), -- 복합 기본 키
    FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) COMMENT='프로젝트 참여를 위한 초대코드 저장소';

use `task_service_db`;

-- 7. `tasks` 테이블: 프로젝트 내 태스크(작업) 정보
-- 특정 프로젝트에 속하며, 사용자에게 할당될 수 있습니다.
CREATE TABLE `tasks`
(
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '태스크 식별 값',
    `project_id` BIGINT NOT NULL COMMENT '프로젝트 식별자 (FK)',
    `user_id` BIGINT NULL COMMENT '작업 할당자 (FK to users.id, NULL 가능)',
    `due_date` DATETIME NULL COMMENT '만료일 (옵션)',
    `title` VARCHAR(255) NOT NULL COMMENT '태스크 제목',
    `description` TEXT COMMENT '태스크 설명 (옵션)',
    `status` ENUM('TODO', 'IN_PROGRESS', 'DONE') NOT NULL COMMENT '태스크 상태',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
    `is_deleted` BOOLEAN DEFAULT FALSE COMMENT '삭제 여부',
    `deleted_at` DATETIME NULL COMMENT '삭제 일시',
    `deleted_by_user_id` BIGINT NULL COMMENT '삭제한 사용자 식별 값 (FK)'
) COMMENT='프로젝트 내 태스크(작업) 정보 테이블';
