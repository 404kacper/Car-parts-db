package com.test;

import com.database.DBConnection;
import com.database.Models.Order;
import org.junit.Assert;
import org.junit.Test;

import java.util.ArrayList;

import static com.database.Controlers.OrderDBQueries.*;


public class OrderTest {
    @Test
    public void zmienZamowienie() {
        DBConnection connection = new DBConnection();
        connection.setUSER("administrator");
        connection.setPASS("abc");
        connection.connect();

        // Stan początkowy - reset wartosci w bazie przed kazdym testem
        Order order2 = new Order(12,1,2,3,41.9f,0);
        updateOrder(12, order2);

        // zmieniany bedzie order z id = 12 - początkowo
        ArrayList<Order> allOrders = getAllOrders();

        // zebranie informacji o starym zamówieniu
        int[] oldKoszykId = {-1};
        allOrders.forEach(listItem -> {
            if (listItem.getId() == 12) {
                oldKoszykId[0]=listItem.getKoszyk_id();
            }
        });

        // utworzenie nowego zamówienia i zmiana parametrów
        Order order = new Order(12,1,2,2,41.9f,0);
        updateOrder(12, order);
        ArrayList<Order> allOrdersAfterUpdate = getAllOrders();

        int[] newKoszykId = {-2};
        allOrdersAfterUpdate.forEach(listItem -> {
            if (listItem.getId() == 12) {
                newKoszykId[0]=listItem.getKoszyk_id();
            }
        });
        Assert.assertNotEquals(oldKoszykId[0], newKoszykId[0]);
    }
}
