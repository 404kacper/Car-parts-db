package com.database;

import com.database.Models.User;
import com.database.Services.CurrentUserService;

import java.sql.*;
import java.util.ArrayList;

public class DBConnection {
    private static String DB_URL = "jdbc:oracle:thin:@localhost:1521:xe";
    public static String USER = "";
    private static String PASS = "";
    static Connection sqlConnection;

    public static void connect() {
        // Open a connection
        try {
            sqlConnection = DriverManager.getConnection(DB_URL, USER, PASS);
        } catch (SQLException e) {
            if (e.getErrorCode() == 1017) {
                // Mozna tez oddelegowac i wyswietlic odpowiednik komunikat w kontrolerze logowania
                System.out.println("Wprowadzono nieprawidlowe dane logowania");
            } else {
                e.printStackTrace();
            }
//            sqlConnection = null;
//            System.out.println(e.getErrorCode());
        }
    }

    public static User connectForUser(String login, String haslo) {
        setUSER("administrator");
        setPASS("abc");
        connect();

        User retrievedUser;
        CurrentUserService cu = new CurrentUserService();
        // i tu dalej przerabiac login itp itd.
        retrievedUser = cu.loginForUser(login, haslo);
        retrievedUser.id = cu.id;
        retrievedUser.nazwa = cu.nazwa;
        retrievedUser.login = cu.login;
        retrievedUser.haslo = cu.haslo;
        retrievedUser.adres = cu.adres;
        retrievedUser.typ = cu.typ;
        // Wylogowanie admina
        sqlConnection = null;
        USER = login;
        PASS = haslo;
        // Open a connection
        connect();

        return retrievedUser;
    }

    public static ArrayList<ArrayList<String>> rawQuery(String fullCommand) {
        try {
            // create statement
            Statement stm = sqlConnection.createStatement();

            // query
            ResultSet result = null;
            boolean returningRows = stm.execute(fullCommand);
            if (returningRows)
                result = stm.getResultSet();
            else
                return new ArrayList<ArrayList<String>>();

            // get metadata
            ResultSetMetaData meta = null;
            meta = result.getMetaData();

            // get column names
            int colCount = meta.getColumnCount();
            ArrayList<String> cols = new ArrayList<String>();
            for (int index = 1; index <= colCount; index++)
                cols.add(meta.getColumnLabel(index));
            //meta.getColumnLabel(arg0)

            // fetch out rows
            ArrayList<ArrayList<String>> rows = new ArrayList<ArrayList<String>>();

            while (result.next()) {
                ArrayList<String> row = new ArrayList<String>();
                for (String colName : cols) {
                    Object val = result.getObject(colName);
                    row.add(val.toString());
                }
                rows.add(row);
            }

            // close statement
            stm.close();

            // pass back rows
            return rows;
        } catch (Exception ex) {
            System.out.print(ex.getMessage());
            return new ArrayList<ArrayList<String>>();
        }
    }

    public static Connection getSqlConnection() {
        return sqlConnection;
    }

    public static void setUSER(String USER) {
        DBConnection.USER = USER;
    }

    public static void setPASS(String PASS) {
        DBConnection.PASS = PASS;
    }

}
