package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.Basket;

import java.sql.Date;
import java.util.ArrayList;

public class BasketDBQueries {
    public static ArrayList<Basket> getAllBaskets() {
        String query = "SELECT * FROM DB.KOSZYK";
        ArrayList<ArrayList<String>> basketList = DBConnection.rawQuery(query);
        ArrayList<Basket> finalList = new ArrayList<>();
        for (ArrayList<String> el : basketList) {
            int id = Integer.parseInt(el.get(0));
            int id_produkt = Integer.parseInt(el.get(1));
            Date date = Date.valueOf(el.get(2));
            int ilosc = Integer.parseInt(el.get(3));

            finalList.add(new Basket(id, id_produkt, date, ilosc));
        }
        return finalList;
    }

    public static int getHighestBasketID() {
        String query = "SELECT KOSZYK_ID FROM DB.KOSZYK WHERE koszyk_id = (SELECT MAX(koszyk_id) from DB.KOSZYK)";
        ArrayList<String> list = DBConnection.rawQuery(query).get(0);
        return Integer.parseInt(list.get(0));
    }

    public static void addBasket(Basket basket) {
        String query = "INSERT INTO DB.KOSZYK (PRODUKT_ID, DATA_UTWORZENIA, " +
                "ILOSC) values (" + basket.produkt_id + ", '" + basket.data + "', "
                + basket.ilosc + ")";
        DBConnection.rawQuery(query);
    }

    public static void deleteBasket(int id) {
        String query = "DELETE FROM DB.KOSZYK WHERE KOSZYK_ID = " + id;
        DBConnection.rawQuery(query);
    }
}
