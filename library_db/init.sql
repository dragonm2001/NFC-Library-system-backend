-- Создание схем
CREATE SCHEMA library_schema;
CREATE SCHEMA db_logs;
CREATE SCHEMA employee_schema;
CREATE SCHEMA library_trgs;

-- Установка расширение pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Таблицы в library_schema

-- Разделы
CREATE TABLE library_schema.sections (
                                         section_id SERIAL PRIMARY KEY,
                                         section_name TEXT NOT NULL CHECK (length(section_name) <= 100) UNIQUE
);

-- Стеллажи
CREATE TABLE library_schema.racks (
                                      rack_id SERIAL PRIMARY KEY,
                                      rack_name TEXT NOT NULL CHECK (length(rack_name) <= 100),
                                      section_id INT NOT NULL REFERENCES library_schema.sections(section_id)
);


-- Полки
CREATE TABLE library_schema.shelfs (
                                       shelf_id SERIAL PRIMARY KEY,
                                       shelf_number INT NOT NULL CHECK (shelf_number > 0),
                                       rack_id INT NOT NULL REFERENCES library_schema.racks(rack_id),
                                       UNIQUE (shelf_number, rack_id)
);

-- Авторы
CREATE TABLE library_schema.authors (
                                        author_id SERIAL PRIMARY KEY,
                                        author_lname TEXT NOT NULL CHECK (length(author_lname) <= 100),
                                        author_fname TEXT NOT NULL CHECK (length(author_fname) <= 100),
                                        author_mname TEXT CHECK (length(author_mname) <= 100),
                                        birth_year INT NOT NULL CHECK (birth_year > 0 AND birth_year <= extract(year from now())),
                                        death_year INT CHECK (death_year > birth_year AND death_year <= extract(year from now()))
);

-- Жанры
CREATE TABLE library_schema.genres (
                                       genre_id SERIAL PRIMARY KEY,
                                       genre_name TEXT NOT NULL CHECK (length(genre_name) <= 100) UNIQUE
);

-- Категории
CREATE TABLE library_schema.categories (
                                           category_id SERIAL PRIMARY KEY,
                                           category_name TEXT NOT NULL CHECK (length(category_name) <= 100) UNIQUE
);

-- Издатели
CREATE TABLE library_schema.publishers (
                                           publisher_id SERIAL PRIMARY KEY,
                                           publisher_name TEXT NOT NULL CHECK (length(publisher_name) <= 100) UNIQUE
);

-- Книги
CREATE TABLE library_schema.books (
                                      book_id SERIAL PRIMARY KEY,
                                      book_name TEXT NOT NULL CHECK (length(book_name) <= 255),
                                      publishing_year INT NOT NULL CHECK (publishing_year > 0 AND publishing_year <= extract(year from now())),
                                      pages_number INT NOT NULL CHECK (pages_number > 0),
                                      category_id INT NOT NULL REFERENCES library_schema.categories(category_id),
                                      genre_id INT NOT NULL REFERENCES library_schema.genres(genre_id)
);

-- Книги-авторы
CREATE TABLE library_schema.authors_books (
                                              author_id INT NOT NULL REFERENCES library_schema.authors(author_id),
                                              book_id INT NOT NULL REFERENCES library_schema.books(book_id)
);

-- Копии книг
CREATE TABLE library_schema.book_copies (
                                            copy_id SERIAL PRIMARY KEY,
                                            photo TEXT NOT NULL,
                                            status TEXT NOT NULL CHECK (status IN ('Доступна', 'На руках', 'Повреждена', 'Утеряна')) DEFAULT 'Доступна',
                                            book_id INT NOT NULL REFERENCES library_schema.books(book_id),
                                            publisher_id INT NOT NULL REFERENCES library_schema.publishers(publisher_id)
);

-- Местонахождение книги
CREATE TABLE library_schema.book_locations (
                                               shelf_id INT NOT NULL REFERENCES library_schema.shelfs(shelf_id),
                                               copy_id INT NOT NULL REFERENCES library_schema.book_copies(copy_id)
);

-- Карточки пользователей
CREATE TABLE library_schema.user_cards (
                                      user_id SERIAL PRIMARY KEY,
                                      user_lname TEXT NOT NULL CHECK (length(user_lname) <= 100),
                                      user_fname TEXT NOT NULL CHECK (length(user_fname) <= 100),
                                      user_mname TEXT CHECK (length(user_mname) <= 100),
                                      user_passport_series INT NOT NULL CHECK (user_passport_series BETWEEN 1000 AND 9999),
                                      user_passport_number INT NOT NULL CHECK (user_passport_number BETWEEN 100000 AND 999999),
                                      user_email TEXT NOT NULL UNIQUE CHECK (length(user_email) <= 255 AND user_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
									  status TEXT NOT NULL CHECK (status IN ('Активный', 'Неактивный')),
                                      photo TEXT NOT NULL,
                                      registration_date TEXT NOT NULL DEFAULT CURRENT_DATE
);

-- Займы
CREATE TABLE library_schema.loans (
                                      loan_id SERIAL PRIMARY KEY,
                                      loan_date DATE NOT NULL,
                                      due_date DATE NOT NULL CHECK (due_date > loan_date),
                                      return_date DATE CHECK (return_date >= loan_date),
                                      copy_id INT NOT NULL REFERENCES library_schema.book_copies(copy_id),
                                      user_id INT NOT NULL REFERENCES library_schema.user_cards(user_id)
);

-- Штрафы
CREATE TABLE library_schema.fines (
                                      fine_id SERIAL PRIMARY KEY,
                                      fine_amount DECIMAL(10,2) NOT NULL CHECK (fine_amount >= 100),
                                      fine_date DATE NOT NULL DEFAULT CURRENT_DATE,
                                      fine_paid BOOLEAN NOT NULL DEFAULT FALSE,
                                      user_id INT NOT NULL REFERENCES library_schema.user_cards(user_id)
);

-- Штрафы-карточки
CREATE TABLE library_schema.fines_cards (
                                            fine_id INT NOT NULL REFERENCES library_schema.fines(fine_id),
                                            user_id INT NOT NULL REFERENCES library_schema.user_cards(user_id)
);

-- Таблицы в db_logs

-- Логи карточек
CREATE TABLE db_logs.card_logs (
                                            user_id INT NOT NULL,
                                            table_field TEXT NOT NULL,
                                            operation_type TEXT NOT NULL,
                                            prev_value TEXT NOT NULL,
                                            new_value TEXT NOT NULL,
                                            change_time TIMESTAMP NOT NULL DEFAULT now()
);

-- Логи книг
CREATE TABLE db_logs.book_logs (
                                            book_id INT NOT NULL,
                                            table_field TEXT NOT NULL,
                                            operation_type TEXT NOT NULL,
                                            prev_value TEXT NOT NULL,
                                            new_value TEXT NOT NULL,
                                            change_time TIMESTAMP NOT NULL DEFAULT now()
);

-- Логи штрафов
CREATE TABLE db_logs.fine_logs (
                                            fine_id INT NOT NULL,
                                            user_id INT NOT NULL,
                                            table_field TEXT NOT NULL,
                                            operation_type TEXT NOT NULL,
                                            prev_value TEXT NOT NULL,
                                            new_value TEXT NOT NULL,
                                            change_time TIMESTAMP NOT NULL DEFAULT now()
);

-- Логи общие
CREATE TABLE db_logs.overall_logs (
                                            table_name TEXT NOT NULL,
                                            table_field TEXT NOT NULL,
                                            operation_type TEXT NOT NULL,
                                            prev_value TEXT NOT NULL,
                                            new_value TEXT NOT NULL,
                                            change_time TIMESTAMP NOT NULL DEFAULT now()

);

-- Таблицы в employee_schema

-- Сотрудники
CREATE TABLE employee_schema.employees (
                                           employee_id SERIAL PRIMARY KEY,
                                           employee_lname TEXT NOT NULL CHECK (length(employee_lname) <= 100),
                                           employee_fname TEXT NOT NULL CHECK (length(employee_fname) <= 100),
                                           employee_mname TEXT CHECK (length(employee_mname) <= 100),
                                           employee_passport_series INT NOT NULL CHECK (employee_passport_series BETWEEN 1000 AND 9999),
                                           employee_passport_number INT NOT NULL CHECK (employee_passport_number BETWEEN 100000 AND 999999)
);

-- Данные для входа сотрудников
CREATE TABLE employee_schema.employee_credentials (
                                                      credential_id SERIAL PRIMARY KEY,
                                                      employee_id INT NOT NULL REFERENCES employee_schema.employees(employee_id),
                                                      username TEXT NOT NULL UNIQUE CHECK (length(username) <= 100),
                                                      password TEXT NOT NULL CHECK (length(password) >= 8)
);

-- -- Функция для создания штрафа при просрочке
-- CREATE OR REPLACE FUNCTION library_trgs.create_fine()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     IF (NEW.return_date IS NULL AND NEW.due_date < current_date) THEN
--         INSERT INTO library_schema.fines (fine_amount, fine_date, fine_paid)
--         VALUES (100.00, current_date, FALSE);
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_create_fine
--     AFTER INSERT ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.create_fine();

-- -- Функция для обнуления штрафа при его оплате
-- CREATE OR REPLACE FUNCTION library_trgs.reset_fine()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     IF (NEW.fine_paid = TRUE) THEN
--         DELETE FROM library_schema.fines WHERE fine_id = NEW.fine_id;
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_reset_fine
--     AFTER UPDATE ON library_schema.fines
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.reset_fine();

-- -- Функция для запрета на взятие новой книги при наличии непогашенного штрафа
-- CREATE OR REPLACE FUNCTION library_trgs.restrict_loan_with_fines()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     IF EXISTS (
--         SELECT 1
--         FROM library_schema.fines f
--                  JOIN library_schema.fines_cards fc ON f.fine_id = fc.fine_id
--         WHERE fc.user_id = NEW.loan_id AND f.fine_paid = FALSE
--     ) THEN
--         RAISE EXCEPTION 'Cannot take a new loan while there are unpaid fines.';
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_restrict_loan_with_fines
--     BEFORE INSERT ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.restrict_loan_with_fines();

-- -- Функция для обновления статуса книги при аренде
-- CREATE OR REPLACE FUNCTION library_trgs.update_book_status_on_loan()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     UPDATE library_schema.book_copies
--     SET status = 'Доступна'
--     WHERE copy_id = NEW.copy_id;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_book_status_on_loan
--     AFTER INSERT ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.update_book_status_on_loan();

-- -- Функция для обновления статуса книги при возврате
-- CREATE OR REPLACE FUNCTION library_trgs.update_book_status_on_return()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     UPDATE library_schema.book_copies
--     SET status = 'Доступна'
--     WHERE copy_id = NEW.copy_id AND NEW.return_date IS NOT NULL;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_book_status_on_return
--     AFTER UPDATE ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.update_book_status_on_return();

-- -- Функция для создания карточки при аренде книги
-- CREATE OR REPLACE FUNCTION library_trgs.create_card_on_loan()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     INSERT INTO library_schema.user_cards (registration_date, user_id, loan_id)
--     VALUES (current_date, (SELECT user_id FROM library_schema.loans WHERE loan_id = NEW.loan_id), NEW.loan_id);
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_create_card_on_loan
--     AFTER INSERT ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.create_card_on_loan();

-- -- Функция для логирования изменений в таблице fines
-- CREATE OR REPLACE FUNCTION library_trgs.log_fine_changes()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     INSERT INTO db_logs.fine_logs (fine_id, user_id, table_field, operation_type, prev_value, new_value, change_time)
--     VALUES (
--                NEW.fine_id,
--                (SELECT user_id FROM library_schema.fines_cards WHERE fine_id = NEW.fine_id),
--                TG_ARGV[0],
--                TG_OP,
--                OLD.fine_amount::TEXT,
--                NEW.fine_amount::TEXT,
--                now()
--            );
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_log_fine_changes
--     AFTER UPDATE ON library_schema.fines
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.log_fine_changes();

-- -- Функция для ограничения количества книг на руках
-- CREATE OR REPLACE FUNCTION library_trgs.restrict_max_books()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     IF (
--            SELECT COUNT(*)
--            FROM library_schema.loans
--            WHERE user_id = (SELECT user_id FROM library_schema.user_cards WHERE user_id = NEW.loan_id)
--              AND return_date IS NULL
--        ) >= 5 THEN
--         RAISE EXCEPTION 'Cannot borrow more than 5 books at once.';
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_restrict_max_books
--     BEFORE INSERT ON library_schema.loans
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.restrict_max_books();

-- -- Функция для обновления информации о пользователях
-- CREATE OR REPLACE FUNCTION library_trgs.update_user_info_after_check()
--     RETURNS TRIGGER AS $$
-- BEGIN
--     IF EXISTS (
--         SELECT 1
--         FROM library_schema.loans
--         WHERE user_id = NEW.user_id AND return_date IS NULL
--     ) THEN
--         UPDATE library_schema.user_cards
--         SET user_lname = NEW.user_lname,
--             user_fname = NEW.user_fname,
--             user_mname = NEW.user_mname,
--             user_passport_series = NEW.user_passport_series,
--             user_passport_number = NEW.user_passport_number,
--             user_email = NEW.user_email
--         WHERE user_id = NEW.user_id;
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_user_info_after_check
--     AFTER UPDATE ON library_schema.user_cards
--     FOR EACH ROW EXECUTE FUNCTION library_trgs.update_user_info_after_check();

-- Sections
INSERT INTO library_schema.sections (section_name) VALUES
('Фантастика'),
('Детективы'),
('История'),
('Психология'),
('Философия'),
('Биографии'),
('Классическая литература'),
('Научная литература'),
('Детская литература'),
('Мемуары');

-- Racks
INSERT INTO library_schema.racks (rack_name, section_id) VALUES
('Стеллаж A1', 1),
('Стеллаж B2', 2),
('Стеллаж C3', 3),
('Стеллаж D4', 4),
('Стеллаж E5', 5),
('Стеллаж F6', 6),
('Стеллаж G7', 7),
('Стеллаж H8', 8),
('Стеллаж I9', 9),
('Стеллаж J10', 10);

-- Shelfs
INSERT INTO library_schema.shelfs (shelf_number, rack_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- Authors
INSERT INTO library_schema.authors (author_lname, author_fname, author_mname, birth_year, death_year) VALUES
('Толстой', 'Лев', 'Николаевич', 1828, 1910),
('Достоевский', 'Федор', 'Михайлович', 1821, 1881),
('Пушкин', 'Александр', 'Сергеевич', 1799, 1837),
('Чехов', 'Антон', 'Павлович', 1860, 1904),
('Шолохов', 'Михаил', 'Александрович', 1905, 1984),
('Гоголь', 'Николай', 'Васильевич', 1809, 1852),
('Тургенев', 'Иван', 'Сергеевич', 1818, 1883),
('Ахматова', 'Анна', 'Андреевна', 1889, 1966),
('Булгаков', 'Михаил', 'Афанасьевич', 1891, 1940),
('Маяковский', 'Владимир', 'Владимирович', 1893, 1930);

-- Genres
INSERT INTO library_schema.genres (genre_name) VALUES
('Фантастика'),
('Детектив'),
('Исторический роман'),
('Психология'),
('Философия'),
('Биография'),
('Классика'),
('Научная литература'),
('Детская литература'),
('Мемуары');

-- Categories
INSERT INTO library_schema.categories (category_name) VALUES
('Романы'),
('Повести'),
('Рассказы'),
('Эссе'),
('Пьесы'),
('Научные статьи'),
('Детская литература'),
('Автобиографии'),
('Поэзия'),
('Научная фантастика');

-- Publishers
INSERT INTO library_schema.publishers (publisher_name) VALUES
('АСТ'),
('Эксмо'),
('Просвещение'),
('Азбука'),
('МИФ'),
('Росмэн'),
('Питер'),
('Эксмо-Классика'),
('Нигма'),
('Речь');

-- Books
INSERT INTO library_schema.books (book_name, publishing_year, pages_number, category_id, genre_id) VALUES
('Война и мир', 1869, 1225, 1, 7),
('Преступление и наказание', 1866, 671, 1, 2),
('Евгений Онегин', 1833, 224, 9, 7),
('Вишневый сад', 1904, 104, 5, 7),
('Тихий Дон', 1928, 1118, 1, 3),
('Мертвые души', 1842, 352, 1, 7),
('Отцы и дети', 1862, 330, 1, 7),
('Реквием', 1963, 64, 9, 9),
('Мастер и Маргарита', 1967, 480, 1, 1),
('Облако в штанах', 1915, 128, 9, 9);

-- Authors_Books
INSERT INTO library_schema.authors_books (author_id, book_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- Book_Copies
INSERT INTO library_schema.book_copies (photo, status, book_id, publisher_id) VALUES
('photo1.jpg', 'Доступна', 1, 1),
('photo2.jpg', 'На руках', 2, 2),
('photo3.jpg', 'Повреждена', 3, 3),
('photo4.jpg', 'Доступна', 4, 4),
('photo5.jpg', 'Утеряна', 5, 5),
('photo6.jpg', 'Доступна', 6, 6),
('photo7.jpg', 'На руках', 7, 7),
('photo8.jpg', 'Повреждена', 8, 8),
('photo9.jpg', 'Доступна', 9, 9),
('photo10.jpg', 'Утеряна', 10, 10);

-- Book_Locations
INSERT INTO library_schema.book_locations (shelf_id, copy_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

-- User_Cards
INSERT INTO library_schema.user_cards (user_lname, user_fname, user_mname, user_passport_series, user_passport_number, user_email, status, photo) VALUES
('Иванов', 'Иван', 'Иванович', 1234, 654321, 'ivanov@example.com', 'Активный', 'photo_user1.jpg'),
('Петров', 'Петр', 'Петрович', 2345, 765432, 'petrov@example.com', 'Активный', 'photo_user2.jpg'),
('Сидоров', 'Сидор', 'Сидорович', 3456, 876543, 'sidorov@example.com', 'Неактивный', 'photo_user3.jpg'),
('Кузнецов', 'Кузьма', 'Кузьмич', 4567, 987654, 'kuznetsov@example.com', 'Активный', 'photo_user4.jpg'),
('Смирнов', 'Сергей', 'Сергеевич', 5678, 234567, 'smirnov@example.com', 'Неактивный', 'photo_user5.jpg'),
('Попов', 'Павел', 'Павлович', 6789, 345678, 'popov@example.com', 'Активный', 'photo_user6.jpg'),
('Васильев', 'Василий', 'Васильевич', 7890, 456789, 'vasilyev@example.com', 'Активный', 'photo_user7.jpg'),
('Николаев', 'Николай', 'Николаевич', 8901, 567890, 'nikolaev@example.com', 'Неактивный', 'photo_user8.jpg'),
('Морозов', 'Михаил', 'Михайлович', 9012, 678901, 'morozov@example.com', 'Активный', 'photo_user9.jpg'),
('Федоров', 'Федор', 'Федорович', 1234, 789012, 'fedorov@example.com', 'Неактивный', 'photo_user10.jpg');

-- Loans
INSERT INTO library_schema.loans (loan_date, due_date, return_date, copy_id, user_id) VALUES
('2024-09-01', '2024-09-15', NULL, 1, 1),
('2024-09-02', '2024-09-16', NULL, 2, 2),
('2024-09-03', '2024-09-17', NULL, 3, 3),
('2024-09-04', '2024-09-18', NULL, 4, 4),
('2024-09-05', '2024-09-19', '2024-09-10', 5, 5),
('2024-09-06', '2024-09-20', '2024-09-11', 6, 6),
('2024-09-07', '2024-09-21', NULL, 7, 7),
('2024-09-08', '2024-09-22', NULL, 8, 8),
('2024-09-09', '2024-09-23', '2024-09-14', 9, 9),
('2024-09-10', '2024-09-24', NULL, 10, 10);

-- Fines
INSERT INTO library_schema.fines (fine_amount, fine_date, fine_paid, user_id) VALUES
(150.00, '2024-09-12', FALSE, 1),
(200.00, '2024-09-13', TRUE, 2),
(300.00, '2024-09-14', FALSE, 3),
(100.00, '2024-09-15', TRUE, 4),
(250.00, '2024-09-16', FALSE, 5),
(400.00, '2024-09-17', TRUE, 6),
(500.00, '2024-09-18', FALSE, 7),
(350.00, '2024-09-19', TRUE, 8),
(600.00, '2024-09-20', FALSE, 9),
(700.00, '2024-09-21', TRUE, 10);

-- Fines_Cards
INSERT INTO library_schema.fines_cards (fine_id, user_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

INSERT INTO employee_schema.employees (employee_lname, employee_fname, employee_mname, employee_passport_series, employee_passport_number) VALUES
('Ivanov', 'Alexey', 'Petrovich', 1234, 567890),
('Sidorov', 'Dmitry', 'Nikolaevich', 2345, 678901),
('Petrova', 'Olga', 'Sergeevna', 3456, 789012),
('Smirnov', 'Vladimir', 'Igorevich', 4567, 890123),
('Vasiliev', 'Sergey', 'Andreevich', 5678, 901234),
('Kuznetsova', 'Elena', 'Ivanovna', 6789, 123456),
('Nikolaeva', 'Marina', 'Pavlovna', 7890, 234567),
('Fedorov', 'Oleg', 'Vladimirovich', 8901, 345678),
('Orlova', 'Anna', 'Petrovna', 9012, 456789),
('Popov', 'Andrey', 'Alexandrovich', 1234, 567890);

INSERT INTO employee_schema.employee_credentials (employee_id, username, password) VALUES
(1, 'alexey_ivanov', crypt('password123', gen_salt('bf'))),
(2, 'dmitry_sidorov', crypt('securePass456', gen_salt('bf'))),
(3, 'olga_petrova', crypt('olga789!', gen_salt('bf'))),
(4, 'vladimir_smirnov', crypt('vlad_pass1', gen_salt('bf'))),
(5, 'sergey_vasiliev', crypt('sergey_secret', gen_salt('bf'))),
(6, 'elena_kuznetsova', crypt('elena_2021', gen_salt('bf'))),
(7, 'marina_nikolaeva', crypt('marina_s3cure', gen_salt('bf'))),
(8, 'oleg_fedorov', crypt('oleg_strong', gen_salt('bf'))),
(9, 'anna_orlova', crypt('anna_pass456', gen_salt('bf'))),
(10, 'andrey_popov', crypt('popov_secure', gen_salt('bf')));