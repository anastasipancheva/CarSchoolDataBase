DROP SCHEMA IF EXISTS driving_school;
CREATE SCHEMA driving_school;
USE driving_school;

CREATE TABLE BRANCH (
  BRANCH_ID INT PRIMARY KEY AUTO_INCREMENT,
  Address   VARCHAR(255) NOT NULL,
  Phone     VARCHAR(20),
  Working_Hours VARCHAR(100),
  Manager_Name  VARCHAR(255)
);

CREATE TABLE COURSE (
  COURSE_ID INT PRIMARY KEY AUTO_INCREMENT,
  Course_Name VARCHAR(100) NOT NULL,
  Total_Hours_Theory   INT NOT NULL,
  Total_Hours_Practice INT NOT NULL,
  Category  VARCHAR(10) NOT NULL,
  Transmission_Type ENUM('МКПП','АКПП') NOT NULL,
  CONSTRAINT chk_course_theory CHECK (Total_Hours_Theory   > 0),
  CONSTRAINT chk_course_practice CHECK (Total_Hours_Practice > 0)
);

CREATE TABLE ENROLLMENT_GROUP (
  GROUP_ID INT PRIMARY KEY AUTO_INCREMENT,
  COURSE_ID INT NOT NULL,
  Start_Date DATE NOT NULL,
  Planned_End_Date DATE NOT NULL,
  Capacity INT NOT NULL,
  CONSTRAINT fk_group_course FOREIGN KEY (COURSE_ID) REFERENCES COURSE(COURSE_ID),
  CONSTRAINT chk_group_capacity CHECK (Capacity > 0),
  CONSTRAINT chk_group_dates CHECK (Planned_End_Date > Start_Date)
);

CREATE TABLE THEORY_TEACHER (
  TEACHER_ID INT PRIMARY KEY AUTO_INCREMENT,
  Full_Name VARCHAR(255) NOT NULL,
  Phone VARCHAR(20),
  Experience_Years INT,
  BRANCH_ID INT NOT NULL,
  CONSTRAINT fk_teacher_branch FOREIGN KEY (BRANCH_ID) REFERENCES BRANCH(BRANCH_ID),
  CONSTRAINT chk_teacher_exp CHECK (Experience_Years IS NULL OR Experience_Years >= 0)
);

CREATE TABLE INSTRUCTOR (
  INSTRUCTOR_ID INT PRIMARY KEY AUTO_INCREMENT,
  Full_Name VARCHAR(255) NOT NULL,
  Phone VARCHAR(20),
  Driving_Experience_Years INT,
  Teaching_Transmission ENUM('МКПП','АКПП','Обе') NOT NULL DEFAULT 'Обе',
  Category VARCHAR(10) NOT NULL,
  BRANCH_ID INT NOT NULL,
  CONSTRAINT chk_instr_exp CHECK (Driving_Experience_Years IS NULL OR Driving_Experience_Years >= 3),
  CONSTRAINT fk_instr_branch FOREIGN KEY (BRANCH_ID) REFERENCES BRANCH(BRANCH_ID)
);

CREATE TABLE VEHICLE (
  VEHICLE_ID INT PRIMARY KEY AUTO_INCREMENT,
  Make VARCHAR(100),
  Model VARCHAR(100),
  License_Plate VARCHAR(20) NOT NULL,
  Year_of_Manufacture INT,
  Color VARCHAR(50),
  Mileage INT,
  Transmission_Type ENUM('МКПП','АКПП') NOT NULL,
  INSTRUCTOR_ID INT, -- машина может быть закреплена за инструктором (опционально)
  UNIQUE KEY uq_plate (License_Plate),
  CONSTRAINT fk_vehicle_instructor FOREIGN KEY (INSTRUCTOR_ID) REFERENCES INSTRUCTOR(INSTRUCTOR_ID)
);

CREATE TABLE STUDENT (
  STUDENT_ID INT PRIMARY KEY AUTO_INCREMENT,
  Full_Name VARCHAR(255) NOT NULL,
  Date_of_Birth DATE,
  Phone VARCHAR(20),
  Email VARCHAR(100) NOT NULL,
  Address VARCHAR(255),
  Passport_Series_Number VARCHAR(20) NOT NULL,
  COURSE_ID INT NOT NULL,
  GROUP_ID  INT,
  BRANCH_ID INT,
  Theory_Minutes_Completed   INT NOT NULL DEFAULT 0,
  Practice_Minutes_Completed INT NOT NULL DEFAULT 0,
  Admission_Status ENUM('Допущен','Не допущен') NOT NULL DEFAULT 'Не допущен',
  UNIQUE KEY uq_student_email (Email),
  UNIQUE KEY uq_student_passport (Passport_Series_Number),
  CONSTRAINT fk_student_course FOREIGN KEY (COURSE_ID) REFERENCES COURSE(COURSE_ID),
  CONSTRAINT fk_student_group  FOREIGN KEY (GROUP_ID)  REFERENCES ENROLLMENT_GROUP(GROUP_ID),
  CONSTRAINT fk_student_branch FOREIGN KEY (BRANCH_ID) REFERENCES BRANCH(BRANCH_ID)
);

CREATE TABLE MEDICAL_CERTIFICATE (
  CERTIFICATE_ID INT PRIMARY KEY AUTO_INCREMENT,
  STUDENT_ID INT UNIQUE,
  Issue_Date DATE NOT NULL,
  Expiry_Date DATE,
  Driving_Restrictions TEXT,
  CONSTRAINT fk_cert_student FOREIGN KEY (STUDENT_ID) REFERENCES STUDENT(STUDENT_ID) ON DELETE CASCADE,
  CONSTRAINT chk_medcert_dates CHECK (Expiry_Date IS NULL OR Expiry_Date >= Issue_Date)
);

CREATE TABLE THEORY_LESSON (
  THEORY_LESSON_ID INT PRIMARY KEY AUTO_INCREMENT,
  Lesson_Topic VARCHAR(255) NOT NULL,
  Lesson_DateTime DATETIME NOT NULL,
  Planned_Duration_Minutes INT NOT NULL,
  TEACHER_ID INT NOT NULL,
  CONSTRAINT chk_theory_duration CHECK (Planned_Duration_Minutes > 0),
  CONSTRAINT fk_tlesson_teacher FOREIGN KEY (TEACHER_ID) REFERENCES THEORY_TEACHER(TEACHER_ID)
);

CREATE TABLE GROUP_THEORY_LESSON (
  GROUP_ID INT NOT NULL,
  THEORY_LESSON_ID INT NOT NULL,
  PRIMARY KEY (GROUP_ID, THEORY_LESSON_ID),
  CONSTRAINT fk_gtl_group  FOREIGN KEY (GROUP_ID)
    REFERENCES ENROLLMENT_GROUP(GROUP_ID) ON DELETE CASCADE,
  CONSTRAINT fk_gtl_tlesson FOREIGN KEY (THEORY_LESSON_ID)
    REFERENCES THEORY_LESSON(THEORY_LESSON_ID) ON DELETE CASCADE
);

-- Посещаемость теории
CREATE TABLE THEORY_ATTENDANCE (
  THEORY_LESSON_ID INT NOT NULL,
  STUDENT_ID INT NOT NULL,
  Is_Present BOOL NOT NULL DEFAULT TRUE,
  PRIMARY KEY (THEORY_LESSON_ID, STUDENT_ID),
  CONSTRAINT fk_ta_student FOREIGN KEY (STUDENT_ID) REFERENCES STUDENT(STUDENT_ID) ON DELETE CASCADE,
  CONSTRAINT fk_ta_lesson  FOREIGN KEY (THEORY_LESSON_ID) REFERENCES THEORY_LESSON(THEORY_LESSON_ID) ON DELETE CASCADE
);

CREATE TABLE PRACTICE_LESSON (
  PRACTICE_LESSON_ID INT NOT NULL AUTO_INCREMENT, 
  STUDENT_ID INT NOT NULL,     
  COURSE_ID INT NOT NULL,    
  INSTRUCTOR_ID INT NOT NULL,
  VEHICLE_ID INT NOT NULL,
  Visit_Date DATE NOT NULL,  
  Is_Present BOOL NOT NULL DEFAULT FALSE, 
  Actual_Duration_Minutes INT, 
  Mileage_Kilometers DECIMAL(6,2),
  Comment TEXT,
  PRIMARY KEY (PRACTICE_LESSON_ID),
  CONSTRAINT fk_pl_student FOREIGN KEY (STUDENT_ID) REFERENCES STUDENT(STUDENT_ID) ON DELETE CASCADE,
  CONSTRAINT fk_pl_course FOREIGN KEY (COURSE_ID) REFERENCES COURSE(COURSE_ID),
  CONSTRAINT fk_pl_instructor FOREIGN KEY (INSTRUCTOR_ID) REFERENCES INSTRUCTOR(INSTRUCTOR_ID),
  CONSTRAINT fk_pl_vehicle FOREIGN KEY (VEHICLE_ID) REFERENCES VEHICLE(VEHICLE_ID),
  CONSTRAINT chk_pl_duration CHECK (Actual_Duration_Minutes IS NULL OR Actual_Duration_Minutes > 0),
  CONSTRAINT chk_pl_mileage CHECK (Mileage_Kilometers IS NULL OR Mileage_Kilometers >= 0)
);

CREATE TABLE EXAM (
  EXAM_ID INT PRIMARY KEY AUTO_INCREMENT,
  Exam_Type ENUM('Теория','Практика') NOT NULL,
  Exam_Level ENUM('Внутренний','ГАИ') NOT NULL, 
  Exam_DateTime DATETIME NOT NULL,
  Location VARCHAR(255)
);

CREATE TABLE STUDENT_EXAM (
  STUDENT_ID INT NOT NULL,
  EXAM_ID INT NOT NULL,
  Grade_Result ENUM('Сдал','Не сдал','Допущен','Не допущен'),
  Attempt_Count INT,
  Examiner_Notes TEXT,
  PRIMARY KEY (STUDENT_ID, EXAM_ID),
  CONSTRAINT fk_se_student FOREIGN KEY (STUDENT_ID) REFERENCES STUDENT(STUDENT_ID) ON DELETE CASCADE,
  CONSTRAINT fk_se_exam    FOREIGN KEY (EXAM_ID)    REFERENCES EXAM(EXAM_ID) ON DELETE CASCADE,
  CONSTRAINT chk_exam_attempt CHECK (Attempt_Count IS NULL OR Attempt_Count >= 1)
);

CREATE TABLE TRAINING_CONTRACT (
  CONTRACT_ID INT PRIMARY KEY AUTO_INCREMENT,
  Contract_Date DATE NOT NULL,
  Cost DECIMAL(10,2) NOT NULL,
  COURSE_ID INT NOT NULL,
  STUDENT_ID INT NOT NULL,
  CONSTRAINT fk_contract_student FOREIGN KEY (STUDENT_ID)  REFERENCES STUDENT(STUDENT_ID),
  CONSTRAINT fk_contract_course FOREIGN KEY (COURSE_ID) REFERENCES COURSE(COURSE_ID),
  CONSTRAINT chk_contract_cost CHECK (Cost > 0)
);


DELIMITER $$

-- курс студента и автомобиль в занятии
CREATE TRIGGER trg_practice_attendance_course_fit
BEFORE INSERT ON PRACTICE_LESSON
FOR EACH ROW
BEGIN
  DECLARE v_course_trans ENUM('МКПП','АКПП');
  DECLARE v_vehicle_trans ENUM('МКПП','АКПП');

  SELECT c.Transmission_Type
    INTO v_course_trans
  FROM STUDENT s
  JOIN COURSE  c ON c.COURSE_ID = s.COURSE_ID
  WHERE s.STUDENT_ID = NEW.STUDENT_ID
  LIMIT 1;

  SELECT v.Transmission_Type
    INTO v_vehicle_trans
  FROM VEHICLE v
  WHERE v.VEHICLE_ID = NEW.VEHICLE_ID
  LIMIT 1;

  IF v_course_trans <> v_vehicle_trans THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Тип КПП автомобиля не соответствует типу КПП курса студента.';
  END IF;
END$$

-- категория инструктора = категории курса студента
CREATE TRIGGER trg_practice_instructor_category_fit
BEFORE INSERT ON PRACTICE_LESSON
FOR EACH ROW
BEGIN
  DECLARE v_course_cat VARCHAR(10);
  DECLARE v_instr_cat  VARCHAR(10);

  SELECT c.Category INTO v_course_cat
  FROM STUDENT s JOIN COURSE c ON c.COURSE_ID = s.COURSE_ID
  WHERE s.STUDENT_ID = NEW.STUDENT_ID;

  SELECT i.Category INTO v_instr_cat
  FROM INSTRUCTOR i
  WHERE i.INSTRUCTOR_ID = NEW.INSTRUCTOR_ID;

  IF v_course_cat <> v_instr_cat THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Категория инструктора не совпадает с категорией курса студента.';
  END IF;
END$$

-- добавляю минуты за посещения
DELIMITER $$
CREATE TRIGGER trg_tatt_add_minutes
AFTER INSERT ON THEORY_ATTENDANCE
FOR EACH ROW
BEGIN
    DECLARE v_duration INT DEFAULT 0;
        IF NEW.Is_Present = TRUE THEN
        SELECT Planned_Duration_Minutes INTO v_duration
        FROM THEORY_LESSON 
        WHERE THEORY_LESSON_ID = NEW.THEORY_LESSON_ID;

        UPDATE STUDENT
        SET Theory_Minutes_Completed = Theory_Minutes_Completed + IFNULL(v_duration, 0)
        WHERE STUDENT_ID = NEW.STUDENT_ID;

        UPDATE STUDENT s
        JOIN COURSE c ON s.COURSE_ID = c.COURSE_ID
        SET s.Admission_Status = 
            (CASE 
                WHEN s.Theory_Minutes_Completed >= c.Total_Hours_Theory * 60
                AND s.Practice_Minutes_Completed >= c.Total_Hours_Practice * 60
                THEN 'Допущен' 
                ELSE 'Не допущен' 
            END)
        WHERE s.STUDENT_ID = NEW.STUDENT_ID;
        
    END IF;
END$$
DELIMITER ;

INSERT INTO BRANCH (Address, Phone, Working_Hours, Manager_Name) VALUES
('Томск, пр. Ленина, 1','+7 3822 000-001', 'Пн–Пт 09:00–18:00', 'Иванова С.В.'),
('Томск, ул. 79 Гвардейской Дивизии, 12','+7 3822 000-002', 'Пн–Пт 09:00–18:00', 'Петров П.П.'),
('Томск, ул. Красноармейская','+7 3822 000-003', 'Пн–Пт 09:00–18:00', 'Сидорова А.А.'),
('Томск, пер. Красный, 5', '+7 3822 000-004', 'Пн–Пт 09:00–18:00', 'Николаев О.О.'); 

INSERT INTO COURSE (Course_Name, Total_Hours_Theory, Total_Hours_Practice, Category, Transmission_Type) VALUES
('Базовый курс категории B механика', 20, 56, 'B', 'МКПП'),
('Базовый курс категории B автомат', 20, 54, 'B', 'АКПП');

INSERT INTO ENROLLMENT_GROUP (COURSE_ID, Start_Date, Planned_End_Date, Capacity) VALUES
(1,'2025-09-01','2025-12-01',25), 
(2,'2025-09-15','2025-12-15',20),
(1,'2025-10-01','2026-01-15',30), 
(2,'2025-10-10','2026-01-25',18); 

INSERT INTO THEORY_TEACHER (Full_Name,Phone,Experience_Years,BRANCH_ID) VALUES
('Пшеницын Максим Юрьевич', NULL, 18, 1), 
('Носков Олег Анатольевич', NULL, 23, 2),
('Толстогузова Светлана Юрьевна', NULL, 11, 3);

INSERT INTO INSTRUCTOR (Full_Name,Phone,Driving_Experience_Years,Teaching_Transmission, Category, BRANCH_ID) VALUES
('Пистолис Василий Янович', NULL, 41, 'МКПП', 'B', 1),
('Антоний Артем Владимирович', NULL, 12, 'МКПП', 'B', 2),
('Бондаренко Кирилл Евгеньевич', NULL, 15, 'МКПП', 'B', 1),
('Дудин Максим Андреевич', NULL, 12, 'АКПП', 'B', 2),
('Регер Владимир Юрьевич', NULL, 29, 'АКПП', 'B', 1),
('Соколов Михаил Анатольевич', NULL, 26, 'АКПП', 'B', 4),
('Соколова Анна Валериевна', NULL, 23, 'АКПП', 'B', 3),
('Стригин Геннадий Юрьевич', NULL, 31, 'МКПП', 'B', 2); 

INSERT INTO VEHICLE (Make,Model,License_Plate,Year_of_Manufacture,Color,Mileage,Transmission_Type, INSTRUCTOR_ID) VALUES
('Kia','Rio','A111AA70',2019,'Белый', 65000,'МКПП', 1), 
('Hyundai','Solaris','A222AA70',2020,'Серый', 54000,'МКПП', 2),
('Volkswagen','Polo','A333AA70',2018,'Синий', 72000,'МКПП', 3),
('Skoda','Rapid','A444AA70',2021,'Белый', 41000,'АКПП', 4), 
('Renault','Logan','A555AA70',2017,'Черный', 93000,'АКПП', 5), 
('Ford','Focus','A666AA70',2016,'Красный', 110000,'АКПП', 6), 
('Lada','Vesta','A888AA70',2022,'Белый', 22000,'АКПП', 7), 
('Mazda','3','A999AA70',2015,'Серый', 125000,'МКПП', 8);

INSERT INTO STUDENT (Full_Name,Date_of_Birth, Phone, Email,Address,Passport_Series_Number,BRANCH_ID, GROUP_ID, COURSE_ID) VALUES
('Безносов Иван Егорович','2006-01-08','+7 960 911-77-76','ivanov.ps@example.com','Томск, ул. Пушкина, 3-12','7000 123456',1, 1, 1),
('Панчева Анастасия Александровна','2006-11-18','+7 913 816-84-50','pancheva.nastya@gmail.com','Томск, пр. Комсомольский, 43-72','56920 415876',2, 2, 2),
('Петрова Дарья Андреевна','2003-01-22','+7 900 000-01-03','petrova.da@example.com','Томск, ул. Кирова, 15-7','7000 123458',3, 4, 2),
('Кузнецов Алексей Романович','1999-11-30','+7 900 000-01-04','kuznetsov.ar@example.com','Томск, пер. Учебный, 2-9','7000 123459',1, 1, 1),
('Егорова Марина Павловна','2000-05-19','+7 900 000-01-05','egorova.mp@example.com','Томск, ул. Водников, 8-21','7000 123460',4, 3, 1);


INSERT INTO MEDICAL_CERTIFICATE (STUDENT_ID,Issue_Date,Expiry_Date,Driving_Restrictions) VALUES
(1,'2025-09-01','2026-09-01',NULL),
(2,'2025-08-20','2026-08-20','Зрение'),
(3,'2025-09-15','2026-09-15',NULL),
(4,'2025-07-10','2026-07-10',NULL),
(5,'2025-10-05','2026-10-05','Зрение');


INSERT INTO THEORY_LESSON (Lesson_Topic, Lesson_DateTime, Planned_Duration_Minutes, TEACHER_ID) VALUES
('ПДД: знаки (гр.1)','2025-09-20 18:00:00',90, 1), 
('ПДД: знаки (гр.2)','2025-09-20 18:00:00',90, 2),
('ПДД: разметка (гр.1)','2025-09-27 18:00:00',90, 1),
('Основы безопасного вождения','2025-09-25 19:00:00',120, 3),
('Первая помощь (гр.3)', '2025-10-10 18:30:00',90, 2);

INSERT INTO GROUP_THEORY_LESSON (GROUP_ID, THEORY_LESSON_ID) VALUES
(1,1),(2,2),(1,3),(2,4),(3,5);


INSERT INTO THEORY_ATTENDANCE (STUDENT_ID,THEORY_LESSON_ID,Is_Present) VALUES
(1,1,1), -- Безносов 1 гр на 90 мин
(4,1,1), -- Кузнецов 1 гр на 90 мин
(2,2,1), -- Панчева 2 гр на 90 мин
(5,3,1), -- Егорова 3 гр на 90 мин
(2,4,1); -- Панчева 2 гр на 120 мин

INSERT INTO PRACTICE_LESSON (STUDENT_ID, COURSE_ID, INSTRUCTOR_ID, VEHICLE_ID, Visit_Date, Is_Present, Actual_Duration_Minutes, Mileage_Kilometers, Comment) VALUES
(1, 1, 1, 1, '2025-10-01', TRUE, 90, 15.0, NULL),
(2, 2, 4, 4, '2025-10-02', TRUE, 90, 12.5, NULL),
(4, 1, 3, 3, '2025-10-03', TRUE, 120, 22.0, NULL),
(3, 2, 4, 4, '2025-10-04', TRUE, 90, 14.0, NULL),
(5, 1, 3, 3, '2025-10-05', TRUE, 90, 14.0, NULL),
(3, 2, 7, 7, '2025-10-06', TRUE, 120, 20.0, NULL);

INSERT INTO EXAM (Exam_Type, Exam_Level, Exam_DateTime, Location) VALUES
('Теория', 'Внутренний', '2025-10-05 10:00:00','Аудитория 101'),
('Практика', 'Внутренний', '2025-10-20 09:00:00','Офис на Иркутском');


INSERT INTO STUDENT_EXAM (STUDENT_ID, EXAM_ID, Grade_Result, Attempt_Count, Examiner_Notes) VALUES
(1, 1, 'Сдал', 1, '-'),
(4, 1, 'Сдал', 1, '-'),
(2, 1, 'Сдал', 1, '-'),
(5, 1, 'Не сдал', 2, 'Вторая попытка, не сдал'), 
(1, 2, 'Сдал', 1, '2 штрафных балла'),
(4, 2, 'Не сдал', 1, 'Создание помехи'),
(2, 2, 'Сдал', 1, 'Отлично');

INSERT INTO TRAINING_CONTRACT (Contract_Date, Cost, COURSE_ID, STUDENT_ID) VALUES
('2025-09-01', 45000, 1, 1), 
('2025-09-01', 45000, 2, 2),
('2025-09-15', 47000, 2, 3),
('2025-07-10', 45000, 1, 4),
('2025-10-05', 45000, 1, 5);



