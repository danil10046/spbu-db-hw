-- ВТОРАЯ ЧАСТЬ. Временные структуры и представления, способы валидации запросов
-- Добавим несколько примеров запросов для валидации данных.

-- Убедимся, что новая оценка находится в допустимом диапазоне перед добавлением
DO $$
DECLARE
    grade_to_insert INT := 6;
BEGIN
    IF grade_to_insert NOT BETWEEN 1 AND 5 THEN
        RAISE EXCEPTION 'Оценка должна быть в между  1 и 5';
    END IF;

    INSERT INTO student_grades (student_id, teacher_subject_id, date, grade, comment)
    VALUES (197, 1, '2024-09-01', grade_to_insert, 'Отлично!');
END $$;
-- Проверим, существует ли ученик с таким же именем и датой рождения перед добавлением
-- Возможно не совсем корректно, т.к. бывают люди с одинаковыми ФИО и датой рождения, но это в качестве примера :)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM students WHERE first_name = 'Андрей' AND last_name = 'Васильев' AND date_of_birth = '2009-01-15') THEN
        RAISE EXCEPTION 'Студент с таким именем и датой рождения уже добавлены';
    END IF;

    INSERT INTO students (first_name, last_name, date_of_birth, class_id)
    VALUES ('Андрей', 'Васильев', '2009-01-15', 1);
END $$;

-- Проверим, существует ли запись перед удалением
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM student_grades WHERE student_id = 197 AND teacher_subject_id = 1 AND date = '2024-09-01') THEN
        RAISE EXCEPTION 'Grade record does not exist';
    END IF;

    DELETE FROM student_grades
    WHERE student_id = 197 AND teacher_subject_id = 1 AND date = '2024-09-01';
END $$;

-- Временные структуры и Представления
--Допустим, мы хотим временно хранить информацию о новых учениках перед тем, как добавить их в основную таблицу students.
--Мы можем создать временную таблицу, вставить в нее данные, а затем добавить их в основную таблицу.

-- Создадим временной таблицы
CREATE TEMP TABLE temp_new_students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    class_id INT
);

-- Добавим данные во временную таблицу
INSERT INTO temp_new_students (first_name, last_name, date_of_birth, class_id)
VALUES
('Иван', 'Иванов', '2010-01-01', 1),
('Мария', 'Петрова', '2010-02-02', 2),
('Алексей', 'Сидоров', '2010-03-03', 3);

-- Пперенесём данные из временной таблицы в основную таблицу
INSERT INTO students (first_name, last_name, date_of_birth, class_id)
SELECT first_name, last_name, date_of_birth, class_id
FROM temp_new_students;

-- Теперь добавим представление
CREATE VIEW student_grades_view AS
SELECT s.student_id, s.first_name, s.last_name, sub.subject_name, g.grade, g.date
FROM students s JOIN student_grades g ON s.student_id = g.student_id
JOIN teacher_subjects ts ON g.teacher_subject_id = ts.teacher_subject_id
JOIN subjects sub ON ts.subject_id = sub.subject_id;

-- Теперь сделаем запрос на поиск среднего балла ученика по каждому премету
SELECT last_name, first_name, subject_name, AVG(grade) AS average_grade
FROM student_grades_view
WHERE student_id = 197
GROUP BY last_name, first_name, subject_name
ORDER BY subject_name LIMIT 10;

-- Или запросим оценки по математике для всех учеников
SELECT last_name, first_name, grade, date
FROM student_grades_view
WHERE subject_name = 'Математика'
ORDER BY last_name, first_name, date LIMIT 25;

-- Создадим ещё одно представление для информации о домашних заданиях
CREATE VIEW homework_info_view AS
SELECT h.homework_id, h.description, h.due_date, c.class_number, c.class_letter, sub.subject_name, t.first_name AS teacher_first_name, t.last_name AS teacher_last_name
FROM homework h
JOIN classes c ON h.class_id = c.class_id
JOIN teacher_subjects ts ON h.teacher_subject_id = ts.teacher_subject_id
JOIN subjects sub ON ts.subject_id = sub.subject_id
JOIN teachers t ON ts.teacher_id = t.teacher_id;

-- Теперь узнаем какое домашнее задание задали 8А классу
SELECT *
FROM homework_info_view
WHERE class_number = 8 AND class_letter = 'A';
