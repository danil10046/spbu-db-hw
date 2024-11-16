-- HW 2
-- Создадим таблицу student_courses
CREATE TABLE student_courses (
    id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    UNIQUE(student_id, course_id), -- Гарантирование уникального отношения
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- Вставим данные в таблицу student_courses
INSERT INTO student_courses (id, student_id, course_id) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 1),
(4, 2, 2),
(5, 3, 3),
(6, 3, 4),
(7, 4, 3),
(8, 4, 4),
(9, 5, 3),
(10, 5, 4),
(11, 6, 1),
(12, 6, 2),
(11, 7, 3),
(12, 7, 4);

-- Создадим таблицу group_courses
CREATE TABLE group_courses (
    id INT PRIMARY KEY,
    group_id INT,
    course_id INT,
    UNIQUE(group_id, course_id), -- Гарантирование уникального отношения
    FOREIGN KEY (group_id) REFERENCES groups(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- Вставим данные в таблицу group_courses
INSERT INTO group_courses (id, group_id, course_id) VALUES
(1, 1, 1), -- Engineering Group 24 - Mathematics
(2, 1, 2), -- Engineering Group 24 - History
(3, 2, 3), -- AI and data science - Data science
(4, 2, 4); -- AI and data science - Machine learning

-- Удалим поля courses_ids из таблицы students и students_ids из таблицы groups
ALTER TABLE students DROP COLUMN courses_ids;
ALTER TABLE groups DROP COLUMN students_ids;

-- Добавим уникальное ограничение на поле name
ALTER TABLE courses ADD CONSTRAINT unique_course_name UNIQUE (name);

-- Создадим индекс на поле group_id
CREATE INDEX idx_group_id ON students(group_id);
-- Индексирование поможет ускорить выполнение запросов, таких как JOIN, WHERE и другие, которые используют поле group_id.
-- Индексирование позволит более эффективно находить строки в таблице.

-- Запрос списка всех студентов с их курсами:
SELECT s.first_name, s.last_name, c.name AS course_name
FROM students s JOIN student_courses sc ON s.id = sc.student_id JOIN courses c ON sc.course_id = c.id;

-- Запрос нахождения студентов с самой высокой средней оценкой по курсам в их группе:
SELECT s.first_name, s.last_name, AVG(cg.grade) AS average_grade
FROM students s JOIN course_grades cg ON s.id = cg.student_id
GROUP BY s.id, s.first_name, s.last_name, s.group_id
HAVING AVG(cg.grade) > (
    SELECT AVG(cg2.grade)
    FROM students s2
    JOIN course_grades cg2 ON s2.id = cg2.student_id
    WHERE s2.group_id = s.group_id
    GROUP BY s2.id
);

-- Подсчитать количество студентов на каждом курсе:
SELECT c.name AS course_name, COUNT(sc.student_id) AS num_students
FROM courses c JOIN student_courses sc ON c.id = sc.course_id
GROUP BY c.name;

-- Найти среднюю оценку на каждом курсе:
SELECT c.name AS course_name, AVG(cg.grade) AS average_grade
FROM courses c JOIN course_grades cg ON c.id = cg.course_id
GROUP BY c.name;
