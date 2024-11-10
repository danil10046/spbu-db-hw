-- Создание базы Университетов
Create database University

\c University

-- 1. Создание таблицы courses
CREATE TABLE courses (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    is_exam BOOLEAN,
    min_grade INT,
    max_grade INT
);

-- Вставим данные в таблицу courses
INSERT INTO courses (id, name, is_exam, min_grade, max_grade) VALUES
(1, 'Mathematics', TRUE, 50, 100),
(2, 'History', FALSE, 0, 100),
(3, 'Data science', TRUE, 60, 100),
(4, 'Machine learning', TRUE, 55, 100);

Select * From courses;

-- 2. Создадим таблицу groups
CREATE TABLE groups (
    id INT PRIMARY KEY,
    full_name VARCHAR(255),
    short_name VARCHAR(50),
    students_ids VARCHAR(255)
);

-- Вставим данные в таблицу groups
INSERT INTO groups (id, full_name, short_name, students_ids) VALUES
(1, 'Engineering Group 24', 'ENG24', '1,2,6'),
(2, 'AI and data science', 'M84', '3,4,5,7');

-- 3. Создадим таблицу students
CREATE TABLE students (
    id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    group_id INT,
    courses_ids VARCHAR(255),
    FOREIGN KEY (group_id) REFERENCES groups(id)
);

-- Вставить данные в таблицу students
INSERT INTO students (id, first_name, last_name, group_id, courses_ids) VALUES
(1, 'John', 'Doe', 1, '1,2'),
(2, 'Jane', 'Smith', 1, '1,2'),
(3, 'Alice', 'Johnson', 2, '3,4'),
(4, 'Ron', 'Williams', 2, '3,4'),
(5, 'Mark', 'Stephens', 2, '3,4'),
(6, 'Viola', 'Reynolds', 1, '1,2'),
(7, 'Jim', 'Reyes', 2, '3,4');

-- 4. Создадим таблицу для курса
-- (мне показалось, что стоит создать таблицу в которой будет столбец course_id, который будет связан с таблицой courses)
CREATE TABLE course_grades (
    student_id INT,
    course_id INT,
    grade INT,
    grade_str VARCHAR(50),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

-- Вставим данные в таблицу course_grades
INSERT INTO course_grades (student_id, course_id, grade, grade_str) VALUES
(1, 1, 75, 'Pass'), -- Mathematics
(2, 1, 90, 'Pass'), -- Mathematics
(1, 2, 85, 'Pass'), -- History
(3, 3, 50, 'No pass'),-- Data science
(4, 2, 85, 'Pass'), -- Data science
(4, 4, 85, 'Pass'), -- Machine learning
(5, 3, 45, 'No pass'), -- Data science
(5, 3, 65, 'Pass'), -- Machine learning
(6, 1, 33, 'No pass'); -- Mathematics

SELECT * from course_grades;

-- Фильтрация
-- Найти всех студентов конкретной группы
SELECT first_name, last_name FROM students WHERE group_id = 1;

-- Найти студентов, которые сдали экзамен по Mathematics
SELECT students.first_name, students.last_name, course_grades.grade
FROM students JOIN course_grades ON students.id = course_grades.student_id JOIN courses c ON course_grades.course_id = c.id
WHERE c.name = 'Mathematics' AND course_grades.grade >= c.min_grade;

-- Подсчитать количество студентов, сдавших экзамены по каждому курсу:
SELECT courses.name, COUNT(*) AS passed_students
FROM course_grades JOIN courses ON course_grades.course_id = courses.id
WHERE course_grades.grade >= courses.min_grade GROUP BY courses.name;

-- Агрегация
-- Подсчитать количество студентов в каждой группе:
SELECT group_id,  COUNT(*) AS num_students FROM students GROUP BY group_id;
-- Найти средний балл по каждому курсу:
SELECT courses.name, AVG(course_grades.grade) AS average_grade
FROM course_grades JOIN courses ON course_grades.course_id = courses.id
GROUP BY courses.name;
