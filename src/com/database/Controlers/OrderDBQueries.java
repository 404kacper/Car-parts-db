package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.Order;

import java.util.ArrayList;

public class OrderDBQueries {
    public static ArrayList<Order> getAllOrders() {
        String query = "SELECT * FROM DB.ZAMOWIENIE";
        ArrayList<ArrayList<String>> orderList = DBConnection.rawQuery(query);
        ArrayList<Order> finalList = new ArrayList<>();
        for (ArrayList<String> el : orderList) {
            int id = Integer.parseInt(el.get(0));
            int id_uzytkownik = Integer.parseInt(el.get(1));
            int id_promocja = Integer.parseInt(el.get(2));
            int id_koszyk = Integer.parseInt(el.get(3));
            float koszt = Float.parseFloat(el.get(4));
            int status = Integer.parseInt(el.get(5));

            finalList.add(new Order(id, id_uzytkownik, id_promocja, id_koszyk, koszt, status));
        }
        return finalList;
    }

    public static void addOrder(Order order) {
        String query = "INSERT INTO DB.ZAMOWIENIE (UZYTKOWNIK_ID, PROMOCJA_ID, " +
                "KOSZYK_ID, STATUS) values (" + order.uzytkownik_id + ", " +
                order.promocja_id + ", " + order.koszyk_id + ", " + order.status + ")";
        DBConnection.rawQuery(query);
    }

    public static void updateOrder(int id, Order order) {
        String query = "UPDATE DB.ZAMOWIENIE SET " +
                "UZYTKOWNIK_ID = " + order.uzytkownik_id + ", " +
                "PROMOCJA_ID = " + order.promocja_id + ", " +
                "KOSZYK_ID = " + order.koszyk_id + ", " +
                "KOSZT = " + order.koszyk_id + ", " +
                "STATUS = " + order.status +
                " WHERE ZAMOWIENIE_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static int getHighestOrderID() {
        String query = "SELECT KOSZYK_ID FROM DB.KOSZYK WHERE koszyk_id = (SELECT MAX(koszyk_id) from DB.KOSZYK)";
        ArrayList<String> list = DBConnection.rawQuery(query).get(0);
        return Integer.parseInt(list.get(0));
    }

    public static void updateOrderStatus(int id, int nowyStatus) {
        String query = "UPDATE DB.ZAMOWIENIE SET " +
                "STATUS = " + nowyStatus +
                " WHERE ZAMOWIENIE_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static void deleteOrder(int id) {
        String query = "DELETE FROM DB.ZAMOWIENIE WHERE ZAMOWIENIE_ID = " + id;
        DBConnection.rawQuery(query);
    }
}
