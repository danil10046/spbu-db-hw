-- ТРЕТЬЯ ЧАСТЬ. Триггеры и транзакции
-- Триггер BEFORE INSERT
-- Создадим функцию триггера, которая будет проверять фамилию ученика:
CREATE OR REPLACE FUNCTION before_insert_student_check()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверка, чтобы фамилия студента не была пустой
    IF NEW.last_name IS NULL THEN
        RAISE EXCEPTION 'Фамилия ученика не может быть пустой';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_student
BEFORE INSERT ON students
FOR EACH ROW EXECUTE FUNCTION before_insert_student_check();

-- Попытка вставить запись с пустой фамилией (вызовет ошибку)
INSERT INTO students (first_name, last_name, date_of_birth, class_id)
VALUES ('Иван', NULL, '2009-01-01', 1);

-- Попытка вставить запись с непустой фамилией (успешно)
INSERT INTO students (first_name, last_name, date_of_birth, class_id)
VALUES ('Иван', 'Иванов', '2009-01-01', 1);

-- Триггер AFTER INSERT
-- Создадим триггер, который будет добавлять запись в таблицу student_grades:
CREATE OR REPLACE FUNCTION after_insert_student_add_grade()
RETURNS TRIGGER AS $$
BEGIN
    -- Добавление записи в таблицу student_grades с начальной оценкой
    INSERT INTO student_grades (student_id, teacher_subject_id, date, grade, comment)
    VALUES (NEW.student_id, 1, current_date, 5, 'Начальная оценка');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_student
AFTER INSERT ON students
FOR EACH ROW EXECUTE FUNCTION after_insert_student_add_grade();

INSERT INTO students (first_name, last_name, date_of_birth, class_id)
VALUES ('Алексей', 'Сидоров', '2009-04-04', 1);

-- Триггер BEFORE UPDATE
-- Создадим триггер, который будет проверять имя ученика перед обновлением записи:
CREATE OR REPLACE FUNCTION before_update_student_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.first_name IS NULL THEN
        RAISE EXCEPTION 'Имя ученика не может быть пустым';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_update_student
BEFORE UPDATE ON students
FOR EACH ROW EXECUTE FUNCTION before_update_student_check();

-- Попытка обновить запись с пустым именем (вызовет ошибку)
UPDATE students SET first_name = NULL WHERE student_id = 1;

-- Попытка обновить запись с новым именем (успешно)
UPDATE students SET first_name = 'Александр' WHERE student_id = 1;

-- Триггер AFTER DELETE
-- Создадим таблицу deleted_students для хранения информации об удаленных учениках:
CREATE TABLE deleted_students (
    deleted_student_id SERIAL PRIMARY KEY,
    student_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    class_id INT,
    deletion_time TIMESTAMP DEFAULT current_timestamp
);

-- Создадим триггер, который будет добавлять запись в таблицу deleted_students:
CREATE OR REPLACE FUNCTION after_delete_student_add_record()
RETURNS TRIGGER AS $$
BEGIN
    -- Добавление записи в таблицу deleted_students
    INSERT INTO deleted_students (student_id, first_name, last_name, date_of_birth, class_id)
    VALUES (OLD.student_id, OLD.first_name, OLD.last_name, OLD.date_of_birth, OLD.class_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_delete_student
AFTER DELETE ON students
FOR EACH ROW EXECUTE FUNCTION after_delete_student_add_record();

DELETE FROM students WHERE student_id = 1;

-- Транзакции
-- Успешная транзакция
-- Вставим нового ученика в таблицу students и добавим новую запись в таблицу student_grades.
BEGIN;
    -- Вставка нового ученика
    INSERT INTO students (first_name, last_name, date_of_birth, class_id)
    VALUES ('Данила', 'Заварзин', '2009-04-15', 1);

    -- Добавление оценки ученика
    INSERT INTO student_grades (student_id, teacher_subject_id, date, grade, comment)
    VALUES ((SELECT student_id FROM students WHERE first_name = 'Данила' AND last_name = 'Заварзин'), 1, current_date, 5, 'Отлично!');

    -- Подтверждение транзакции
COMMIT;

-- Неуспешная транзакция
-- Вставим нового ученика в таблицу students и добавим запись в таблицу student_grades с ошибкой в значении внешнего ключа.
BEGIN;
    -- Вставка нового ученика
    INSERT INTO students (first_name, last_name, date_of_birth, class_id)
    VALUES ('Владимир', 'Ленин', '2009-04-22', 2);

    -- Добавление оценки ученика с ошибкой в значении внешнего ключа
    INSERT INTO student_grades (student_id, teacher_subject_id, date, grade, comment)
    VALUES (999, 1, current_date, 5, 'Отлично!');  -- Ошибка: student_id 999 не существует

    -- Подтверждение транзакции
COMMIT;
ROLLBACK;

-- ИЛИ ещё пример неудачной транзакции
-- Попробуем добавить оценку ученику юез указания id предмета учителя (teacher_subject_id)
ALTER TABLE student_grades
ALTER COLUMN teacher_subject_id SET NOT NULL;

BEGIN;
    -- Попытка вставить запись в таблицу students
    INSERT INTO students (first_name, last_name, date_of_birth, class_id)
    VALUES ('Владимир', 'Ленин', '2009-04-22', 2);
    -- Вставка записи в таблицу student_grades (без указания teacher_subject_id)
    INSERT INTO student_grades (student_id, teacher_subject_id, date, grade, comment)
    VALUES (118, NULL, current_date, 5, 'Отлично!');
    -- Подтверждение транзакции
COMMIT;
ROLLBACK;
