package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.Logs;

import java.util.ArrayList;

public class LogsDBQueries {
    public static ArrayList<Logs> getAllLogs() {
        String query = "SELECT * FROM DB.LOGI";
        ArrayList<ArrayList<String>> logsList = DBConnection.rawQuery(query);
        ArrayList<Logs> finalList = new ArrayList<>();
        for (ArrayList<String> el : logsList) {
            int id = Integer.parseInt(el.get(0));
            String typ = (el.get(1));
            int zamowienie_id = Integer.parseInt(el.get(2));
            int uzytkownik_id = Integer.parseInt(el.get(3));
            int status = Integer.parseInt(el.get(4));

            finalList.add(new Logs(id, typ, zamowienie_id, uzytkownik_id, status));
        }
        return finalList;
    }

    public static void deleteOrder(int id) {
        String query = "DELETE FROM DB.LOGI WHERE LOG_ID = " + id;
        DBConnection.rawQuery(query);
    }
}
