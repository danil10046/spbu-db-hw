-- HW4
-- 1. Создать триггеры со всеми возможными ключевыми словами, а также рассмотреть операционные триггеры
-- Создадим триггер, который пересчитывает среднюю оценку студента после вставки или обновления его оценок в таблице course_grades.
CREATE OR REPLACE FUNCTION recalculate_student_average_grade()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE students
    SET average_grade = (SELECT AVG(grade) FROM course_grades WHERE student_id = NEW.student_id)
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_or_update_grade
AFTER INSERT OR UPDATE ON course_grades
FOR EACH ROW EXECUTE FUNCTION recalculate_student_average_grade();

-- Пример использования
INSERT INTO course_grades (student_id, course_id, grade, grade_str) VALUES (1, 2, 80, 'Pass');
UPDATE course_grades SET grade = 90 WHERE student_id = 1 AND course_id = 1;

-- Создадим триггер, который будет автоматически обновлять строку таблицы groups, чтобы поддерживать количество студентов в группе.
CREATE OR REPLACE FUNCTION update_group_student_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE groups
    SET students_count = (SELECT COUNT(*) FROM students WHERE group_id = NEW.group_id)
    WHERE id = NEW.group_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Добавление столбца для хранения количества студентов в группе
ALTER TABLE groups ADD COLUMN students_count INT DEFAULT 0;

CREATE TRIGGER after_insert_or_delete_student
AFTER INSERT OR DELETE ON students
FOR EACH ROW EXECUTE FUNCTION update_group_student_count();

-- Пример использования
INSERT INTO students (id, first_name, last_name, group_id) VALUES (9, 'Alex', 'Taylor', 1);
DELETE FROM students WHERE id = 9;


-- создадим триггер, который будет срабатывать перед удалением записи из таблицы students и,
-- например, перемещать удаляемую запись в архивную таблицу archived_students.
CREATE TABLE archived_students (
    id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    group_id INT,
    deletion_time TIMESTAMP DEFAULT current_timestamp
);

-- Создание функции триггера
CREATE OR REPLACE FUNCTION archive_student_before_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Удаление связанных записей в таблицах (иначе не сможем удалить запись)
    DELETE FROM student_courses WHERE student_id = OLD.id;
    DELETE FROM course_grades WHERE student_id = OLD.id;

    -- Перемещение удаляемой записи в архивную таблицу
    INSERT INTO archived_students (id, first_name, last_name, group_id)
    VALUES (OLD.id, OLD.first_name, OLD.last_name, OLD.group_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для таблицы students
CREATE TRIGGER before_delete_student
BEFORE DELETE ON students
FOR EACH ROW EXECUTE FUNCTION archive_student_before_delete();

DELETE FROM students WHERE id = 1;
SELECT * FROM archived_students WHERE id = 1 LIMIT 5;

-- Создадим операционный триггер, который будет подсчитывать общее количество студентов в таблице students
-- после каждой операции вставки.
-- Создадим вспомогателную таблицу для хранения количества студентов:
CREATE TABLE student_count (
    total_students INT
);
-- Вставим начальное значение
INSERT INTO student_count (total_students) VALUES (0);

-- Создание функции триггера
CREATE OR REPLACE FUNCTION update_student_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE student_count
    SET total_students = (SELECT COUNT(*) FROM students)
    WHERE total_students IS NOT NULL; -- Условие для явного указания обновления единственной строки
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_update_delete_students
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH STATEMENT EXECUTE FUNCTION update_student_count();

INSERT INTO students (id, first_name, last_name, group_id) VALUES (10, 'Anna', 'White', 1);
UPDATE students SET first_name = 'Annabelle' WHERE id = 10;
DELETE FROM students WHERE id = 10;

SELECT * FROM student_count; -- здесь LIMIT можно не ставить т.к. в таблице всего лишь одна запись, которая считает количество студетов
-- 2. Попрактиковаться в созданиях транзакций
-- (привести пример успешной и фейл транзакции, объяснить в комментариях почему она зафейлилась)

-- Примерыуспешных транзакций
-- В этой транзакции мы добавим нового студента и свяжем его с новым курсом.
BEGIN;
    INSERT INTO students (id, first_name, last_name, group_id) VALUES (12, 'Lara', 'Croft', 2);
    INSERT INTO courses (id, name, is_exam, min_grade, max_grade) VALUES (5, 'Archaeology', FALSE, 0, 100);
    INSERT INTO student_courses (id, student_id, course_id) VALUES (13, 12, 5);
    -- Подтверждение транзакции, если все операции успешны
COMMIT;
ROLLBACK;

-- В этой транзакции мы обновим информацию о студенте и добавим запись в таблицу group_courses.
BEGIN;
    UPDATE students
    SET last_name = 'Johnson-Smith'
    WHERE id = 2;

    INSERT INTO group_courses (id, group_id, course_id)
    VALUES (5, 2, 1);
    -- Подтверждение транзакции, если все операции успешны
COMMIT;
ROLLBACK;

-- Примеры неудачных транзакций
BEGIN;
    -- Попытка вставить дублирующую запись в таблицу courses
    INSERT INTO courses (id, name, is_exam, min_grade, max_grade) VALUES (5, 'Mathematics', TRUE, 50, 100);
    -- Вставка записи с тем же значением name
    INSERT INTO courses (id, name, is_exam, min_grade, max_grade) VALUES (6, 'Mathematics', FALSE, 0, 100);
    -- Подтверждение транзакции
COMMIT;
ROLLBACK;
-- Данная транзакция неудачная, т.к. здесь присутствует Нарушение уникального ограничения.
-- Первая вставка нарушает уникальное ограничение на поле id в таблице courses, так как значение "5" уже существует.

-- Теперь попробуем ещё одну неудачную транзацкцию
-- Изменим таблицу students
ALTER TABLE students
ALTER COLUMN first_name SET NOT NULL;

BEGIN;
    -- Попытка вставить запись в таблицу students с NULL значением для поля first_name
    INSERT INTO students (id, first_name, last_name, group_id) VALUES (15, NULL, 'Smith', 1);
    -- Вставка записи в таблицу student_courses
    INSERT INTO student_courses (id, student_id, course_id) VALUES (16, 15, 1);
    -- Подтверждение транзакции
COMMIT;
ROLLBACK;
-- Данная транзакция неудачная, т.к. здесь присутствует нарушение NOT NULL ограничения
-- Поле first_name в таблице students имеет ограничение NOT NULL, что означает, что оно не может содержать NULL значения.

-- 3. Попробовать использовать RAISE внутри триггеров для логирования.
-- Создадим триггер, который будет использовать оператор RAISE для логирования информации при выполнении определенных операций.

-- Создадим доп. таблицу в которой мы будем даписывать логи
CREATE TABLE log_entries (
    log_id SERIAL PRIMARY KEY,
    log_message TEXT,
    log_time TIMESTAMP DEFAULT current_timestamp
);

CREATE OR REPLACE FUNCTION log_insert_student()
RETURNS TRIGGER AS $$
BEGIN
    -- Логирование информации с использованием RAISE
    RAISE NOTICE 'Добавлен студент с ID: % и Именем: % %', NEW.id, NEW.first_name, NEW.last_name;

    -- Вставка лог-сообщения в таблицу log_entries
    INSERT INTO log_entries (log_message)
    VALUES (format('Добавлен студент с ID: %s и Именем: %s %s', NEW.id, NEW.first_name, NEW.last_name));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_student
AFTER INSERT ON students
FOR EACH ROW EXECUTE FUNCTION log_insert_student();

DROP TRIGGER IF EXISTS after_insert_student ON students;

INSERT INTO students (id, first_name, last_name, group_id) VALUES (15, 'Clark', 'Kent', 1);
INSERT INTO students (id, first_name, last_name, group_id) VALUES (16, 'Bruce', 'Wayne', 1);
