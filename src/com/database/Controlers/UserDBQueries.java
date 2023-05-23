package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.User;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;

import static com.database.Models.User.getUserType;

public class UserDBQueries {
    public static ArrayList<User> getAllUsers() {
        String query = "SELECT * FROM DB.UZYTKOWNIK";
        ArrayList<ArrayList<String>> userList = DBConnection.rawQuery(query);
        ArrayList<User> finalList = new ArrayList<>();
        for (ArrayList<String> el : userList) {
            int id = Integer.parseInt(el.get(0));
            String login = (el.get(1));
            String haslo = (el.get(2));
            String nazwa = (el.get(3));
            String adres = (el.get(4));
            int type = Integer.parseInt(el.get(5));
            User.UserType userType = getUserType(type);
            finalList.add(new User(id, nazwa, login, haslo, adres, userType));
        }
        return finalList;
    }

    public static void addUser(User user) {
        String query = "INSERT INTO DB.UZYTKOWNIK (LOGIN, HASLO, NAZWA, ADRES," +
                " TYP_UZYTKOWNIKA) values ('" + user.login + "', '" + user.haslo + "', '"
                + user.nazwa + "', '" + user.adres + "', " + user.getDBUserType() + ")";
        DBConnection.rawQuery(query);
    }

    public static void updateUser(int id, User user) {
        DBConnection.connect();
        String query = "UPDATE DB.UZYTKOWNIK SET " +
                "LOGIN = '" + user.login + "', " +
                "HASLO = '" + user.haslo + "', " +
                "NAZWA = '" + user.nazwa + "', " +
                "ADRES = '" + user.adres + "', " +
                "TYP_UZYTKOWNIKA = " + user.getDBUserType() +
                " WHERE UZYTKOWNIK_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static void updateUserType(int id, int typUzytkownika) {
        String query = "UPDATE DB.UZYTKOWNIK SET " +
                "TYP_UZYTKOWNIKA = " + typUzytkownika +
                " WHERE UZYTKOWNIK_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static User findUserByLoginAndPassword(String login, String haslo) throws IndexOutOfBoundsException {
        // Tutaj DB.uzytkownik -> po dodaniu uprawnien do uzytkownikow w skrypcie sql tworza sie odpowednie table (tylko te do ktorych przyznano dostep)
        // -> np w sql developerze: polaczenie->administrator->other users db (moja nazwa polaczenia ktore tworzy baze)
        // -> wtedy skladania to Select from uzytkownik.tabela ...
        // no i tu pojawia sie problem bo dostep do danych uzytkownikow - tabla UZYTKOWNIK - powinen miec tylko administrator
        String query = "SELECT * FROM DB.UZYTKOWNIK" +
                " WHERE LOGIN = '" + login + "' AND HASLO = '" + haslo + "'";
        ArrayList<String> list = DBConnection.rawQuery(query).get(0);
        int id = Integer.parseInt(list.get(0));
        String nazwa = (list.get(3));
        String adres = (list.get(4));
        int type = Integer.parseInt(list.get(5));
        User.UserType userType = getUserType(type);
        return new User(id, nazwa, login, haslo, adres, userType);
    }

    public static void deleteUser(int id) {
        String query = "DELETE FROM DB.UZYTKOWNIK WHERE UZYTKOWNIK_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static ArrayList<User> sereltUs() {
        String query = "SELECT * FROM DB.UZYTKOWNIK";
        ArrayList<ArrayList<String>> userList = DBConnection.rawQuery(query);
        ArrayList<User> finalList = new ArrayList<>();
        for (ArrayList<String> el : userList) {
            int id = Integer.parseInt(el.get(0));
            String login = (el.get(1));
            String haslo = (el.get(2));
            String nazwa = (el.get(3));
            String adres = (el.get(4));
            int type = Integer.parseInt(el.get(5));
            User.UserType userType = getUserType(type);
            finalList.add(new User(id, nazwa, login, haslo, adres, userType));
        }
        return finalList;
    }
}
