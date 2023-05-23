  -- PRZYWRACANIE DO POCZATKOWEGO STANU -- 

  DROP TABLE "UZYTKOWNIK" cascade constraints;
  DROP TABLE "ZAMOWIENIE" cascade constraints;
  DROP TABLE "PROMOCJA" cascade constraints;
  DROP TABLE "PRODUKT" cascade constraints;
  DROP TABLE "KOSZYK" cascade constraints;
  DROP TABLE "LOGI" cascade constraints;
  DROP VIEW "WIDOK_PROMOCJI" cascade constraints;
  DROP VIEW "WIDOK_NIEZREA_ZAMOWIEN" cascade constraints;

  DROP TRIGGER LOG_TRIGGER;
  DROP TRIGGER ILOSC_TRIGGER;
  DROP TRIGGER ZAMOWIENIE_TRIGGER;
  DROP TRIGGER KOSZT_TRIGGER;

  DROP USER NIEZALOGOWANY CASCADE;
  DROP USER ZALOGOWANY CASCADE;
  DROP USER PRACOWNIK CASCADE;
  DROP USER ADMINISTRATOR CASCADE;

  DROP SEQUENCE log_counter;

  -- SEKWENCJE --

  CREATE SEQUENCE log_counter START WITH 1;

  -- TWORZENIE BAZY --

  CREATE TABLE "UZYTKOWNIK" (
    "UZYTKOWNIK_ID" NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT BY 1),
    "LOGIN" varchar(50) NOT NULL,
    "HASLO" varchar(50) NOT NULL,
    "NAZWA" varchar(50) NOT NULL,
    "ADRES" varchar(90),
    "TYP_UZYTKOWNIKA" int NOT NULL,
    PRIMARY KEY ("UZYTKOWNIK_ID")
  );

  CREATE TABLE "PROMOCJA" (
    "PROMOCJA_ID" NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT BY 1),
    "TYP_PROMOCJI" int NOT NULL,
    "WYSOKOSC_PROMOCJI" float NOT NULL,
    PRIMARY KEY ("PROMOCJA_ID")
  );

  CREATE TABLE "PRODUKT" (
    "PRODUKT_ID" NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT BY 1),
    "NAZWA" varchar(90) NOT NULL,
    "ILOSC_MAGAZYNOWA" int,
    "PRODUCENT" varchar(90) NOT NULL,
    "CENA" float NOT NULL,
    "PROMOCJA_ID" int NOT NULL,
    PRIMARY KEY ("PRODUKT_ID"),
    CONSTRAINT "FK_PRODUKT.PROMOCJA_ID"
      FOREIGN KEY ("PROMOCJA_ID")
        REFERENCES "PROMOCJA"("PROMOCJA_ID")
  );

  CREATE TABLE "KOSZYK" (
    "KOSZYK_ID" NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT BY 1),
    "PRODUKT_ID" int NOT NULL,
    "DATA_UTWORZENIA" DATE,
    "ILOSC" int,
    PRIMARY KEY ("KOSZYK_ID"),
          CONSTRAINT "FK_KOSZYK.PRODUKT_ID"
      FOREIGN KEY ("PRODUKT_ID")
        REFERENCES "PRODUKT"("PRODUKT_ID")
  );


  CREATE TABLE "ZAMOWIENIE" (
    "ZAMOWIENIE_ID" NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT BY 1),
    "UZYTKOWNIK_ID" int NOT NULL,
    "PROMOCJA_ID" int NOT NULL,
    "KOSZYK_ID" int NOT NULL,
    "KOSZT" float,
    "STATUS" int NOT NULL,
  PRIMARY KEY ("ZAMOWIENIE_ID"),
    CONSTRAINT "FK_ZAMOWIENIE.UZYTKOWNIK_ID"
      FOREIGN KEY ("UZYTKOWNIK_ID")
        REFERENCES "UZYTKOWNIK"("UZYTKOWNIK_ID") ON DELETE CASCADE,
    CONSTRAINT "FK_ZAMOWIENIE.PROMOCJA_ID"
    FOREIGN KEY ("PROMOCJA_ID")
        REFERENCES "PROMOCJA"("PROMOCJA_ID"),
        CONSTRAINT "FK_ZAMOWIENIE.KOSZYK_ID"
    FOREIGN KEY ("KOSZYK_ID")
        REFERENCES "KOSZYK"("KOSZYK_ID")
  );

  CREATE TABLE "LOGI" (
      "LOG_ID" int NOT NULL,
      "TYP_OPERACJI" varchar(90) NOT NULL,
      "ZAMOWIENIE_ID" int NOT NULL,
      "UZYTKOWNIK_ID" int NOT NULL,
      "STATUS" int NOT NULL,
      PRIMARY KEY("LOG_ID")
  );

  -- WIDOKI --

  CREATE VIEW WIDOK_PROMOCJI AS SELECT PROMOCJA_ID,TYP_PROMOCJI,WYSOKOSC_PROMOCJI FROM PROMOCJA ORDER BY WYSOKOSC_PROMOCJI DESC;
  CREATE VIEW WIDOK_NIEZREA_ZAMOWIEN AS SELECT ZAMOWIENIE_ID, UZYTKOWNIK_ID, KOSZT, STATUS FROM ZAMOWIENIE WHERE STATUS = 0; 


  -- TWORZENIE UZYTKOWNIKOW --

  alter session set "_ORACLE_SCRIPT"=true; 

  CREATE USER NIEZALOGOWANY IDENTIFIED BY "1234";
  CREATE USER ZALOGOWANY IDENTIFIED BY "123";
  CREATE USER PRACOWNIK IDENTIFIED BY "321";
  CREATE USER ADMINISTRATOR IDENTIFIED BY "abc";

  -- UPRAWNIENIA --
  GRANT SELECT ON PRODUKT TO NIEZALOGOWANY, ZALOGOWANY;
  GRANT SELECT ON PROMOCJA TO NIEZALOGOWANY, ZALOGOWANY;

  -- TWORZENIE SESJI --
  GRANT CREATE SESSION TO NIEZALOGOWANY, ZALOGOWANY, PRACOWNIK, ADMINISTRATOR;
  -- ZALOGOWANY -- 
  GRANT UPDATE, DELETE, SELECT, INSERT ON KOSZYK TO ZALOGOWANY;
  GRANT SELECT, UPDATE ON ZAMOWIENIE TO ZALOGOWANY;
  -- PRACOWNIK --
  GRANT UPDATE, DELETE, SELECT ON ZAMOWIENIE TO PRACOWNIK;
  GRANT INSERT, DELETE, SELECT, UPDATE ON PROMOCJA TO PRACOWNIK;
  GRANT INSERT, DELETE, SELECT, UPDATE ON PRODUKT TO PRACOWNIK;
  -- ADMINISTRATOR --
  GRANT ALL PRIVILEGES TO ADMINISTRATOR;

  -- TRIGGERY -- 

  -- PRZECHOWUJE STARE WARTOSCI ZAMOWIEN PO MODYFIKACJI --
  CREATE OR REPLACE TRIGGER LOG_TRIGGER
  AFTER UPDATE OR DELETE ON ZAMOWIENIE
  FOR EACH ROW
  DECLARE
      OLD_ZAM_ID int;
      OLD_UZ_ID int;
      OLD_STATUS int;
      LOG_ACTION LOGI.TYP_OPERACJI%TYPE;
  BEGIN
      OLD_ZAM_ID := :OLD.ZAMOWIENIE_ID;
      OLD_UZ_ID := :OLD.UZYTKOWNIK_ID;
      OLD_STATUS := :OLD.STATUS;
      
      IF UPDATING THEN    
      LOG_ACTION := 'UPDATE';
      ELSIF DELETING THEN
      LOG_ACTION := 'DELETE';
      ELSE
      LOG_ACTION := 'UNIDENTIFIED';
      END IF;
      
    INSERT INTO LOGI ("LOG_ID", "TYP_OPERACJI", "ZAMOWIENIE_ID", "UZYTKOWNIK_ID", "STATUS") VALUES (log_counter.NEXTVAL, LOG_ACTION, OLD_ZAM_ID, OLD_UZ_ID, OLD_STATUS);

  END;
  /

  -- AKTUALIZUJE ILOSC W KOSZYKU W PRZYPADKU KIEDY UZYTKOWNIK WYMAGA WIECEJ NIZ JEST DOSTEPNE W MAGAZYNIE --
  CREATE OR REPLACE TRIGGER ILOSC_TRIGGER
  BEFORE INSERT OR UPDATE ON KOSZYK
  FOR EACH ROW
  DECLARE
      NEW_ILOSC int;
      NEW_PRODUKT_ID int;
      STAN_MAGAZYNU int;
      NEW_KOSZYK_ID int;
      OBLICZONY_STAN_MAGAZYNU int;
  BEGIN
      NEW_ILOSC := :NEW.ILOSC;
      NEW_PRODUKT_ID := :NEW.PRODUKT_ID;
      SELECT ILOSC_MAGAZYNOWA INTO STAN_MAGAZYNU FROM PRODUKT WHERE PRODUKT_ID = NEW_PRODUKT_ID;
      NEW_KOSZYK_ID := :NEW.KOSZYK_ID;
      
      IF STAN_MAGAZYNU < NEW_ILOSC THEN
      :NEW.ILOSC := 0;
      DBMS_OUTPUT.PUT_LINE('REQUESTED AMOUNT WAS BIGGER THAN AVAILABLE SETTING ORDER AMOUNT BACK TO 0');
      ELSE
      UPDATE PRODUKT SET ILOSC_MAGAZYNOWA = STAN_MAGAZYNU - NEW_ILOSC WHERE PRODUKT_ID = NEW_PRODUKT_ID;
      END IF;
  END;
  /

  -- AKTUALIZUJE WARTOSC KOSZYKA NA PODSTAWIE WARTOSCI PRODUKTU I JEGO ILOSCI --
  CREATE OR REPLACE TRIGGER KOSZT_TRIGGER
  BEFORE INSERT OR UPDATE ON ZAMOWIENIE
  FOR EACH ROW
  DECLARE
    NEW_KOSZYK_ID int;
    SELECTED_CENA_PRODUKTU int;
    SELECTED_ILOSC_PRODUKTU int;
    SELECTED_ID_PRODUKTU int;
  BEGIN
    NEW_KOSZYK_ID := :NEW.KOSZYK_ID;
    SELECT PRODUKT_ID INTO SELECTED_ID_PRODUKTU FROM KOSZYK WHERE KOSZYK_ID = NEW_KOSZYK_ID;
    SELECT ILOSC INTO SELECTED_ILOSC_PRODUKTU FROM KOSZYK WHERE KOSZYK_ID = NEW_KOSZYK_ID;
    SELECT CENA INTO SELECTED_CENA_PRODUKTU FROM PRODUKT WHERE PRODUKT_ID = SELECTED_ID_PRODUKTU;
    
    :NEW.KOSZT := SELECTED_CENA_PRODUKTU * SELECTED_ILOSC_PRODUKTU;

  END;
  /

  -- PREZENTACJA --

  -- DODAWANIE ELEMENTOW --

  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('niezalogowany', '1234', 'Kacper', '265 Arkansas Road', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('zalogowany', '123', 'Kacper', '265 Arkansas Road', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('pracownik', '321', 'Kacper', '321 Arkansas Road', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('administrator', 'abc', 'Kacper', '265 Arkansas Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('homeuser', 'password2', 'Kacper', '2653 Arkansas Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Dunkinson', 'NLQ1vdJ', 'Nissan', '2653 Arkansas Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Hammor', '4WmYbU', 'Mazda', '11194 Mitchell Point', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Coskerry', 'TVtjmpH1c', 'Mercury', '61326 Melrose Road', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Graalmans', 'RcLnGR', 'Nissan', '5073 Kensington Way', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Ghelarducci', 'fl0UvnkfrVqD', 'Mazda', '38066 Blaine Street', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Ehlerding', 'Lgk67F5xI', 'Honda', '84 Morningstar Court', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('McGeffen', 'DCOyCiAkYe', 'Kia', '8 Debra Lane', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Abbate', '91IXoxwN2ZRx', 'Mitsubishi', '9660 2nd Way', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Olander', 'DpHfrnlBk', 'GMC', '3 Harper Point', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Semper', 'gzKlSbyQ225', 'BMW', '409 Kedzie Place', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Amburgy', '6dP7KOc8L', 'Ford', '25405 Brentwood Alley', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Trustrie', 'TWq4zAh1iR', 'Ford', '44 Golf View Park', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Spire', 'TOhbHR', 'Chevrolet', '43948 Maple Point', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Pretty', 'rIPEDWAEt', 'Toyota', '9945 Waywood Point', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Walbrook', 'hIGRJnTb1ij', 'Chrysler', '090 Kedzie Alley', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Fair', '9bro9seqf5sF', 'Cadillac', '5089 Northfield Drive', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Stedman', 'Al7iCk7hfy', 'Mercedes-Benz', '0 Barnett Center', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Defrain', 'evzuLCGRx', 'Buick', '6804 Red Cloud Road', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Banasiak', 'P7cTV1', 'Subaru', '131 Brentwood Center', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Vasenin', '81olQ7LVMz', 'Infiniti', '7 Warbler Terrace', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('McMurty', 'TsAF6PD8GJR', 'Scion', '10501 Monterey Trail', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Robertsson', 'JZ735bkntJ', 'Acura', '26 Gale Lane', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Burnside', 'pZbpljq77E', 'Dodge', '579 Burning Wood Place', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Coyett', 'ZR7gwO4IIx', 'Toyota', '77604 Nelson Avenue', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Hatz', '8etJZc3s9U', 'Lincoln', '54455 International Park', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Sedgman', 'A7Y1Frg1JHDu', 'Infiniti', '815 Mcguire Lane', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Wem', 'QwHfwM', 'Volkswagen', '80105 Gulseth Parkway', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Keysall', 'MWBWIKexyEZy', 'Infiniti', '0896 Marcy Avenue', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Belshaw', 'CEfTrdjknOk8', 'Pontiac', '47795 Bobwhite Parkway', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Roycroft', 'OgKOLqhAXK38', 'Pontiac', '35837 South Plaza', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Hazlegrove', 'zRGNL3Dr2C', 'Peugeot', '46399 Eggendart Trail', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Burrett', 'dL3VkgyEO8C', 'Mercedes-Benz', '24017 Katie Trail', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Astlatt', 'GzH5IzF', 'Kia', '8 Brown Lane', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Garthside', 'G2cILsqv', 'Suzuki', '86 Thierer Lane', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Sevitt', 'vSK0kw', 'Honda', '94 Burning Wood Court', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Mebius', 'qiaI1PY', 'Pontiac', '5383 Magdeline Plaza', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Santos', 'tQvpN5l2zkNO', 'GMC', '26 Southridge Way', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Reason', 'mBRpHe', 'Mercedes-Benz', '7 Ohio Junction', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Valentetti', 'UJHE5D', 'Mitsubishi', '5830 Bartelt Point', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('McArtan', '4IHUfYsqP', 'Ford', '63893 Haas Lane', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Armitage', 'mt92yPSr', 'Mazda', '225 Nova Junction', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Bardnam', 'b6hYticyIO', 'Mercury', '97960 Blackbird Center', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Hawford', 'UfEqZ0', 'Hyundai', '1903 Kim Junction', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Pendell', 'cIMaVo', 'Nissan', '9288 Luster Terrace', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Cockrem', 'bAMpLDuU0DV', 'Dodge', '84 Hauk Avenue', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Gofforth', '9v1DJcGTi', 'Ford', '1888 Surrey Avenue', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Korejs', 'FBs8Iuk0APlf', 'Saab', '30013 Vernon Place', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Tayspell', 'Uy4L24QoQ', 'Chevrolet', '7 Hayes Drive', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('McKennan', 'k1XqS6DNFp', 'Ford', '86 Charing Cross Court', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Krop', 'Y6rsHLpbc', 'Toyota', '83 Schurz Street', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Heys', 'uV4HmUfEy', 'Subaru', '942 Vera Hill', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Tipping', 'EXr6dd', 'Mercedes-Benz', '4617 Dennis Pass', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Wasteney', 'teBjC8', 'Nissan', '802 Nancy Road', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Crummey', 'juWXeF', 'Hyundai', '675 Dakota Drive', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Robbe', '3plwDorZ', 'Suzuki', '2895 Marquette Terrace', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Roubay', '1ex0k63uQRsF', 'Toyota', '35 Darwin Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Deal', 'hPXMts', 'Ford', '24990 Banding Junction', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Rickasse', 'P4n89gIDm', 'Chevrolet', '33404 Texas Hill', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Tevelov', 'qZLYjm74vF2i', 'Chevrolet', '5020 Derek Circle', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Feveryear', 'ntY3u6', 'Mercury', '743 Cottonwood Crossing', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Mc Menamin', 'oX6SBWjK5FQx', 'Ford', '6 Sutteridge Court', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Busek', '4jXCmuOVRLy', 'Honda', '381 Summit Court', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Bourner', 'owbPnlQU', 'Land Rover', '20698 Bellgrove Hill', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Roggieri', '5C73Ls', 'Saab', '551 Florence Lane', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Prenty', 'wjJCfNygkK', 'Mercedes-Benz', '481 Prairieview Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Geekie', 'A9ZXgr', 'Toyota', '073 Farragut Trail', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Jessett', '3nt31c6FG', 'Mercedes-Benz', '334 Loftsgordon Crossing', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Flemyng', 'o6mHYJ', 'Chevrolet', '45 Heffernan Place', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Lavelle', '5W9l4ceB7lEe', 'Pontiac', '1 Shasta Place', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Alison', 'e5Kl1QE1aJ', 'Subaru', '16 Sutherland Terrace', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Levins', 't9kqS1EwJmnZ', 'Subaru', '08791 Mesta Parkway', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Stanyan', 'PTCyK0T', 'Dodge', '2 Onsgard Circle', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Vasenin', 'ka3xPz', 'Bentley', '585 Anderson Road', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Cawston', 'LRz37xphmXf', 'Acura', '46 Boyd Center', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Worshall', '7dyeXzz', 'Acura', '0693 Buena Vista Court', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Whitelock', 'Bb6ng0M68HuF', 'Porsche', '2 Mandrake Alley', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Pecht', 'Feo3rM7ncUG9', 'Toyota', '47633 Clyde Gallagher Lane', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Tummasutti', 'HMkzINb04j6D', 'Mercury', '20 Sunnyside Junction', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Holt', '8tUrvMiu', 'Ford', '6027 Gina Plaza', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Lidgate', 'sZ30QxKhwf', 'Chevrolet', '2173 Johnson Parkway', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Diaper', '47W25ges', 'Dodge', '2 Bultman Parkway', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Bakeup', 'nGNKCPGhD', 'Ford', '38829 Shoshone Center', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('McTaggart', 'NzJtEPyF8n6', 'Geo', '7509 Manley Road', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Whiles', 'tzjhdf', 'Lincoln', '7507 Gulseth Hill', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Iban', 'jc312EXO', 'Alfa Romeo', '7589 Division Crossing', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Johannesson', 'WI2holmk', 'Volvo', '78647 Carey Avenue', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Licquorish', 'eEk9QKCa', 'Toyota', '00648 Brown Court', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Goodie', 'Wz4LSmvz7HB', 'Chevrolet', '07034 Hudson Crossing', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Kasher', '1LWW7HE', 'Toyota', '72 Jackson Trail', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Eburne', 'PqWysL1i', 'Mitsubishi', '0 Rockefeller Court', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Monard', 'WnHWO0qM', 'Eagle', '47 Bunting Parkway', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Scroyton', 'VjoHqX51R', 'Mercedes-Benz', '65 Eagan Circle', 2);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Kleinzweig', 'iL6NpaQOUP', 'Oldsmobile', '57057 Fairfield Terrace', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Beckmann', 'JBaTueA2', 'Chrysler', '3 Donald Drive', 1);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Crowden', 'hHsE682NAI', 'Mercedes-Benz', '10276 Grayhawk Lane', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Cook', 'kJySpFxC', 'Saturn', '548 Upham Crossing', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Dinning', 'VWNc5L5GoGFa', 'Mercedes-Benz', '56212 Annamark Plaza', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Cupper', 'H2UVCw', 'GMC', '4152 Glendale Crossing', 4);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Kenelin', '4ZBSpe6rnV1', 'Pontiac', '0224 Havey Drive', 3);
  insert into UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES, TYP_UZYTKOWNIKA) values ('Center', 'HgHcNwT', 'Ford', '0 Jana Circle', 4);

  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.74);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (1, 0.32);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.92);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.11);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.78);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.5);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (1, 0.47);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.23);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.71);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.34);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.05);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.96);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.93);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.34);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.69);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.03);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.59);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.6);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.3);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.88);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.84);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.41);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.68);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.47);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.25);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.19);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.05);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.76);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.19);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.38);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.54);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.46);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.76);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.75);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.28);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.18);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.28);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.1);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.5);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.47);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.8);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.81);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.67);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.48);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.36);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.16);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.59);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.37);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.21);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.33);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.62);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.79);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.17);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.47);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.26);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.96);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.99);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.82);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.22);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.33);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.01);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.09);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.79);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.27);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.49);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.55);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.44);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.38);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.29);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.06);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.03);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.7);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.68);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.8);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.06);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.75);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.99);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.54);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.87);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.66);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.62);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.38);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.02);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.15);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.58);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.17);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.83);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.2);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.43);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.1);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.16);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.45);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.32);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.38);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.31);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.16);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.37);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.11);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.1);
  insert into PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values (0, 0.25);

  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Cormier-Bahringer', 107.77, 'Hyundai', 5.3, 61.0);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Littel and Sons', 498.63, 'Toyota', 918.97, 58.85);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Turner-Hudson', 16.6, 'Chrysler', 855.72, 7.26);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hegmann, Conroy and Christiansen', 314.52, 'Nissan', 911.43, 29.74);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Kozey LLC', 316.88, 'Saab', 988.59, 94.55);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gibson and Sons', 290.79, 'Ford', 466.57, 5.51);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Konopelski-Goodwin', 270.71, 'Mercedes-Benz', 69.7, 84.37);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gutkowski-Schaefer', 496.81, 'Mercury', 287.43, 18.06);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Howe, Bergstrom and Koch', 100.31, 'Audi', 2222.62, 7.23);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Konopelski-Langosh', 482.55, 'Suzuki', 615.16, 55.58);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Crona-Simonis', 461.84, 'Hyundai', 84.53, 22.62);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Jakubowski Inc', 29.68, 'Mercedes-Benz', 733.24, 74.71);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Bogan-Kerluke', 397.21, 'Porsche', 126.18, 16.37);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Predovic, Barton and Bogan', 195.69, 'Audi', 1234.55, 49.38);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Dare Group', 123.57, 'Toyota', 8.6, 50.53);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Swaniawski-O''Connell', 367.47, 'Toyota', 277.71, 84.13);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Anderson-Runte', 46.22, 'Buick', 57.74, 41.39);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('O''Connell, Ernser and Lind', 136.81, 'Ford', 689.22, 99.91);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Quitzon, Ziemann and Murphy', 121.11, 'Toyota', 8.76, 62.67);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Parisian-Jacobs', 439.72, 'GMC', 782.76, 59.81);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('O''Conner, Wyman and Shields', 215.84, 'Ford', 811.11, 96.29);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Schowalter-Ferry', 111.85, 'Chrysler', 751.6, 37.22);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Greenfelder-Ferry', 366.27, 'Buick', 523.12, 51.09);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Heidenreich-Brown', 260.72, 'Lincoln', 678.4, 39.56);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gorczany-Douglas', 4.63, 'Dodge', 276.45, 70.91);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Bednar, Nitzsche and Tillman', 149.89, 'Maybach', 741.66, 47.57);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Grady, Cronin and Crona', 393.79, 'Cadillac', 349.19, 34.52);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Borer-Terry', 267.15, 'Mazda', 218.84, 65.01);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Stokes-Okuneva', 481.91, 'Buick', 687.62, 8.99);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hamill, Schmeler and Smitham', 328.51, 'Toyota', 767.47, 14.13);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Haley-Herzog', 111.91, 'Mercedes-Benz', 369.96, 39.6);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Konopelski Inc', 296.73, 'Toyota', 296.21, 54.01);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Rosenbaum LLC', 102.14, 'Honda', 139.53, 49.32);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Bednar, Rolfson and Huels', 222.21, 'Chevrolet', 543.27, 98.84);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Pouros-Kirlin', 109.32, 'Dodge', 750.3, 1.13);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('McDermott, Considine and Dibbert', 157.74, 'Volvo', 259.29, 89.88);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Morissette-Gulgowski', 394.42, 'Buick', 568.21, 34.75);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Wuckert, Haag and Hilpert', 375.99, 'Dodge', 849.93, 21.95);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Feeney Group', 250.84, 'Plymouth', 734.48, 9.47);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('McDermott LLC', 223.06, 'Chevrolet', 74.16, 1.19);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Walter LLC', 59.64, 'Volvo', 947.84, 78.74);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hand, Satterfield and Daugherty', 30.18, 'Chevrolet', 789.05, 95.23);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Yundt Inc', 383.23, 'Pontiac', 318.51, 76.2);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Cormier-Oberbrunner', 214.04, 'Toyota', 940.5, 70.41);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Nitzsche LLC', 249.63, 'BMW', 186.34, 64.35);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gibson, McKenzie and Harber', 397.87, 'Mazda', 161.39, 25.84);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Greenfelder and Sons', 17.87, 'BMW', 580.52, 92.86);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Volkman Group', 409.82, 'Nissan', 196.17, 11.36);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Smith-Koss', 319.73, 'Plymouth', 838.46, 16.54);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Weissnat-Lind', 462.83, 'Pontiac', 492.37, 7.87);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Frami LLC', 318.96, 'Mercury', 946.67, 15.95);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hand LLC', 362.45, 'Chevrolet', 443.74, 1.38);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Halvorson-Hilll', 385.21, 'Plymouth', 897.22, 71.59);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hintz-Moen', 278.26, 'Volvo', 981.26, 26.36);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Baumbach-Collins', 427.47, 'Ford', 311.95, 73.17);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Jaskolski-Boehm', 336.54, 'Chevrolet', 336.06, 21.3);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('O''Kon, Barton and Ebert', 359.06, 'Chrysler', 343.93, 88.4);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Bruen-Rempel', 302.04, 'Dodge', 645.3, 88.84);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Johnston Group', 456.17, 'Jeep', 16.96, 45.12);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Grimes Group', 466.81, 'Maybach', 785.47, 33.49);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Simonis and Sons', 441.99, 'Mazda', 202.21, 54.41);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('McDermott-Hayes', 7.34, 'Chevrolet', 412.12, 46.3);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Herman, Kertzmann and Terry', 329.06, 'Mercury', 641.56, 57.19);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Parker-Kozey', 177.12, 'Volkswagen', 556.84, 51.35);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Metz, Turcotte and Bartoletti', 75.16, 'Mazda', 697.01, 25.14);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Kassulke Inc', 107.44, 'Ford', 177.78, 15.34);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Mueller, McLaughlin and Schuster', 87.06, 'Chevrolet', 772.38, 86.2);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Stoltenberg, Schroeder and Heaney', 366.17, 'Chrysler', 604.77, 41.2);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Williamson-Luettgen', 358.74, 'Nissan', 147.66, 38.9);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Johnson-Thiel', 170.7, 'Chevrolet', 761.38, 64.63);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Heaney and Sons', 169.2, 'Lincoln', 110.44, 30.41);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Metz-Lemke', 276.51, 'GMC', 461.43, 28.38);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gusikowski, Haag and Little', 150.56, 'Chevrolet', 29.25, 57.23);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Grady-O''Hara', 164.95, 'Mazda', 696.06, 16.99);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Huels Group', 391.06, 'Chevrolet', 732.3, 80.5);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Carter, Huel and Bechtelar', 232.74, 'Audi', 757.65, 8.33);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Reichel and Sons', 55.56, 'Toyota', 273.81, 20.67);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Zulauf, Rodriguez and Jacobi', 424.62, 'Mitsubishi', 932.8, 54.31);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('O''Connell, Tremblay and Nolan', 234.03, 'Volvo', 261.66, 44.13);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Borer-Roberts', 239.72, 'BMW', 60.41, 96.64);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Nolan LLC', 269.08, 'BMW', 492.88, 24.1);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Dickinson-Nicolas', 262.14, 'Chevrolet', 487.62, 70.61);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Rogahn and Sons', 253.37, 'Acura', 766.44, 94.96);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Schmeler, Sanford and Green', 362.32, 'Chevrolet', 994.89, 49.55);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Hayes Inc', 189.6, 'Ford', 230.5, 5.63);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Denesik Group', 365.23, 'Pontiac', 52.27, 74.71);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Tremblay, Pfannerstill and Mitchell', 301.35, 'Lincoln', 542.98, 51.89);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Williamson Inc', 366.9, 'Chevrolet', 57.18, 35.15);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Maggio-Reilly', 354.95, 'Lotus', 435.42, 31.3);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Schmidt, Lockman and Goyette', 151.22, 'Infiniti', 487.42, 44.2);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('McKenzie Group', 426.48, 'Subaru', 74.85, 32.02);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Beer, Davis and Feil', 203.99, 'Oldsmobile', 421.44, 42.11);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Blanda and Sons', 122.4, 'Porsche', 41.11, 38.88);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Gleason, Schaden and Sanford', 455.62, 'GMC', 966.22, 75.25);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Kulas, Dibbert and Bednar', 424.73, 'BMW', 12345.2, 37.68);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Cartwright Inc', 345.78, 'GMC', 312.51, 91.26);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Harris Group', 245.77, 'Nissan', 393.8, 69.2);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Muller LLC', 224.39, 'Infiniti', 663.25, 94.05);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Fay-Pouros', 408.04, 'Pontiac', 311.86, 46.86);
  insert into PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, PROMOCJA_ID) values ('Dicki Group', 70.84, 'Cadillac', 820.4, 46.48);

  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (58, '2022-04-22', 26);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (14, '2022-02-06', 14);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (79, '2022-04-19', 39);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (35, '2022-04-25', 45);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (36, '2022-11-30', 15);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (47, '2022-09-21', 44);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (8, '2022-10-12', 50);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (45, '2022-09-21', 30);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (25, '2021-12-24', 10);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (90, '2022-12-06', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (70, '2022-09-13', 3);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (52, '2022-08-24', 28);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (40, '2022-04-23', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (7, '2022-05-22', 36);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (75, '2022-08-25', 4);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (53, '2022-10-15', 26);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (50, '2022-03-28', 36);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (56, '2022-10-16', 11);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (89, '2022-07-04', 3);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (75, '2022-03-20', 1);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (99, '2022-11-21', 34);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (7, '2022-12-04', 13);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (6, '2022-06-25', 10);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (75, '2022-02-22', 7);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (45, '2022-01-10', 38);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (67, '2022-10-16', 12);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (43, '2022-04-01', 15);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (53, '2022-08-06', 16);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (14, '2022-01-18', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (13, '2022-06-22', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (83, '2021-12-21', 49);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (74, '2022-05-25', 44);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (50, '2022-02-23', 25);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (20, '2022-05-07', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (13, '2022-05-13', 22);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (91, '2022-03-15', 22);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (51, '2022-11-26', 45);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (15, '2022-08-28', 27);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (39, '2022-08-15', 28);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (48, '2022-05-27', 17);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (90, '2022-08-15', 34);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (18, '2022-05-04', 39);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (35, '2022-10-24', 23);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (95, '2022-03-12', 32);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (16, '2022-06-19', 40);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (7, '2022-09-22', 11);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (36, '2022-05-29', 37);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (80, '2021-12-23', 32);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (92, '2022-02-09', 41);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (64, '2022-04-12', 40);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (23, '2022-04-11', 34);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (43, '2022-10-20', 17);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (90, '2022-05-25', 8);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (29, '2022-11-13', 34);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (11, '2022-03-22', 4);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (93, '2022-10-08', 47);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (61, '2022-07-26', 43);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (19, '2022-01-19', 18);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (61, '2021-12-19', 44);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (16, '2022-01-15', 11);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (14, '2022-06-17', 25);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (16, '2022-05-16', 31);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (85, '2022-06-02', 9);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (55, '2022-01-08', 17);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (51, '2022-07-30', 47);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (97, '2022-05-09', 35);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (12, '2022-07-17', 14);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (46, '2022-04-03', 50);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (96, '2022-11-17', 19);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (39, '2022-03-09', 11);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (80, '2022-11-19', 10);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (41, '2022-07-12', 5);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (5, '2022-07-10', 50);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (45, '2022-04-09', 45);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (54, '2022-12-11', 33);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (43, '2022-08-22', 5);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (71, '2022-06-20', 40);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (91, '2022-07-01', 10);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (27, '2022-07-07', 1);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (81, '2021-12-23', 31);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (69, '2022-07-16', 29);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (32, '2022-07-23', 29);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (84, '2022-07-11', 1);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (74, '2022-11-23', 17);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (32, '2022-06-03', 40);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (77, '2022-06-15', 21);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (72, '2022-07-05', 5);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (47, '2022-09-28', 29);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (8, '2022-01-10', 3);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (36, '2022-09-25', 29);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (78, '2022-10-04', 7);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (42, '2022-08-18', 15);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (99, '2022-07-05', 32);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (97, '2022-03-26', 6);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (98, '2022-06-25', 19);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (84, '2022-11-06', 1);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (99, '2022-06-30', 4);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (27, '2022-04-01', 39);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (21, '2022-06-25', 44);
  insert into KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (44, '2022-04-21', 23);

  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (46, 32, 1, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (7, 5, 2, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (85, 31, 3, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (90, 14, 4, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (55, 52, 5, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (68, 81, 6, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (24, 68, 7, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (1, 87, 8, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (65, 52, 9, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (31, 75, 10, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (53, 31, 11, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (74, 68, 12, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (40, 73, 13, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (24, 83, 14, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (97, 10, 15, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (31, 42, 16, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (47, 14, 17, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (38, 54, 18, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (39, 75, 19, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (32, 52, 20, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (78, 43, 21, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (59, 99, 22, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (76, 86, 23, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (60, 69, 24, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (9, 68, 25, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (56, 63, 26, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (91, 83, 27, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (92, 91, 28, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (15, 68, 29, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (82, 89, 30, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (92, 63, 31, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (72, 75, 32, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (33, 94, 33, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (57, 73, 34, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (65, 9, 35, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (87, 1, 36, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (22, 35, 37, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (88, 90, 38, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (26, 12, 39, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (95, 98, 40, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (84, 65, 41, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (51, 100, 42, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (16, 89, 43, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (99, 98, 44, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (75, 60, 45, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (29, 40, 46, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (46, 12, 47, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (60, 25, 48, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (18, 13, 49, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (23, 34, 50, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (76, 13, 51, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (45, 63, 52, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (19, 55, 53, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (65, 65, 54, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (28, 14, 55, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (49, 57, 56, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (4, 41, 57, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (58, 80, 58, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (58, 95, 59, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (67, 57, 60, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (81, 67, 61, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (58, 69, 62, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (47, 33, 63, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (84, 38, 64, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (24, 67, 65, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (1, 94, 66, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (89, 15, 67, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (2, 82, 68, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (37, 35, 69, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (34, 83, 70, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (94, 55, 71, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (16, 95, 72, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (96, 100, 73, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (4, 36, 74, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (81, 98, 75, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (17, 93, 76, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (1, 26, 77, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (53, 87, 78, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (45, 74, 79, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (62, 10, 80, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (55, 34, 81, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (53, 22, 82, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (28, 68, 83, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (35, 98, 84, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (17, 64, 85, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (17, 44, 86, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (57, 75, 87, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (29, 12, 88, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (27, 72, 89, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (42, 58, 90, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (70, 72, 91, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (94, 73, 92, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (68, 53, 93, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (91, 31, 94, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (57, 94, 95, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (55, 52, 96, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (83, 89, 97, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (77, 22, 98, 0);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (42, 21, 99, 1);
  insert into ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, KOSZYK_ID, STATUS) values (5, 56, 100, 0);


  -- WYSWIETLANIE WIDOKOW --

  --SELECT * FROM WIDOK_PROMOCJI;
  --SELECT * FROM WIDOK_NIEZREA_ZAMOWIEN;

  -- MODYFIKACJA I WYSWIETLANIE Z UZYCIEM TRIGEROW --

  SELECT * FROM LOGI;
  SELECT * FROM ZAMOWIENIE;
  SELECT * FROM KOSZYK;
  SELECT * FROM PRODUKT WHERE PRODUKT_ID = 47;
  -- W INSERCIE JEST 302.04 --> 276 czyli dzia?a
  SELECT * FROM PRODUKT WHERE PRODUKT_ID = 58;
  UPDATE ZAMOWIENIE SET STATUS = 1 WHERE ZAMOWIENIE_ID = 1;

  -- TESTY INTEGRALNO?CIOWE --
  -- SEMANTYCZNA --
  --insert into KOSZYK (KOSZYK_ID, ZAMOWIENIE_ID, PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (100, 83, "80", '2021-12-23', 37);
  -- ENCJI --
  --insert into KOSZYK (KOSZYK_ID, ZAMOWIENIE_ID, PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (100, 83, 80, '2021-12-23', 37);
  --insert into KOSZYK (KOSZYK_ID, ZAMOWIENIE_ID, PRODUKT_ID, DATA_UTWORZENIA, ILOSC) values (NULL, 83, 80, '2021-12-23', 37);
  -- REFERENCJI --
  --SELECT PROMOCJA_ID FROM PRODUKT WHERE PRODUKT_ID = 1;
  --SELECT WYSOKOSC_PROMOCJI FROM PROMOCJA WHERE PROMOCJA_ID = 51;
