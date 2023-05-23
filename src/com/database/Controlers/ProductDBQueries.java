package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.Product;
import com.database.Models.Promotion;

import java.util.ArrayList;

public class ProductDBQueries {
    public static ArrayList<Product> getAllProducts() {
        DBConnection.connect();
        String query = "SELECT * FROM DB.PRODUKT";
        ArrayList<ArrayList<String>> productList = DBConnection.rawQuery(query);
        ArrayList<Product> finalList = new ArrayList<>();
        for (ArrayList<String> el : productList) {
            int id = Integer.parseInt(el.get(0));
            String nazwa = (el.get(1));
            int ilosc = Integer.parseInt(el.get(2));
            String producent = (el.get(3));
            float cena = Float.parseFloat(el.get(4));
            int promocja_id = Integer.parseInt(el.get(5));
            finalList.add(new Product(id, nazwa, producent, ilosc, cena, promocja_id));
        }
        return finalList;
    }

    public static void addProduct(Product product) {
        DBConnection.connect();
        String query = "INSERT INTO DB.PRODUKT (NAZWA, ILOSC_MAGAZYNOWA, PRODUCENT, CENA, " +
                "PROMOCJA_ID) values ('" + product.nazwa + "', " + product.ilosc + ", '" +
                product.producent + "', " + product.cena + ", " + product.id_promocji + ")";
        DBConnection.rawQuery(query);
    }

    public static void updateProduct(int id, Product product) {
        String query = "UPDATE DB.PRODUKT SET " +
                "NAZWA = '" + product.nazwa + "', " +
                "ILOSC_MAGAZYNOWA = " + product.ilosc + ", " +
                "PRODUCENT = '" + product.producent + "', " +
                "CENA = " + product.cena + ", " +
                "PROMOCJA_ID = " + product.id_promocji +
                " WHERE PRODUKT_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static Product getProductById(int id) {
        String query = "SELECT * FROM DB.PRODUKT" +
                " WHERE PRODUKT_ID = " + id;
        ArrayList<String> list = DBConnection.rawQuery(query).get(0);
        String nazwa = list.get(1);
        String producent = list.get(3);
        int ilosc = Integer.parseInt(list.get(2));
        float cena = Float.parseFloat(list.get(4));
        int id_promocji = Integer.parseInt(list.get(5));
        return new Product(id, nazwa, producent, ilosc, cena, id_promocji);
    }

    public static void updateProductQuantity(int id, int ilosc) {
        String query = "UPDATE DB.PRODUKT SET " +
                "ILOSC_MAGAZYNOWA = " + ilosc +
                " WHERE PRODUKT_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static void updateProductPrice(int id, float cena) {
        String query = "UPDATE DB.PRODUKT SET " +
                "CENA = " + cena +
                " WHERE PRODUKT_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static void deleteProduct(int id) {
        String query = "DELETE FROM DB.PRODUKT WHERE PRODUKT_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static ArrayList<Product> getProductsByPrice(String price){
        String query = "SELECT * FROM DB.PRODUKT WHERE CENA " + price;
        ArrayList<ArrayList<String>> productList = DBConnection.rawQuery(query);
        ArrayList<Product> finalList = new ArrayList<>();

        for (ArrayList<String> el : productList) {
            int id = Integer.parseInt(el.get(0));
            String nazwa = (el.get(1));
            int ilosc = Integer.parseInt(el.get(2));
            String producent = (el.get(3));
            float cena = Float.parseFloat(el.get(4));
            int promocja_id = Integer.parseInt(el.get(5));
            finalList.add(new Product(id, nazwa, producent, ilosc, cena, promocja_id));
        }
        return finalList;
    }

    public static ArrayList<Product> getProductsByProducent(String brand){
        String query = "SELECT * FROM DB.PRODUKT WHERE PRODUCENT = " + brand;
        ArrayList<ArrayList<String>> productList = DBConnection.rawQuery(query);
        ArrayList<Product> finalList = new ArrayList<>();

        for (ArrayList<String> el : productList) {
            int id = Integer.parseInt(el.get(0));
            String nazwa = (el.get(1));
            int ilosc = Integer.parseInt(el.get(2));
            String producent = (el.get(3));
            float cena = Float.parseFloat(el.get(4));
            int promocja_id = Integer.parseInt(el.get(5));
            finalList.add(new Product(id, nazwa, producent, ilosc, cena, promocja_id));
        }
        return finalList;
    }

    public static ArrayList<Product> getProductsByPriceAndProducent(String price, String brand){
        String query = "SELECT * FROM DB.PRODUKT WHERE PRODUCENT = " + brand + "" +
                " AND WHERE CENA " + price;
        ArrayList<ArrayList<String>> productList = DBConnection.rawQuery(query);
        ArrayList<Product> finalList = new ArrayList<>();

        for (ArrayList<String> el : productList) {
            int id = Integer.parseInt(el.get(0));
            String nazwa = (el.get(1));
            int ilosc = Integer.parseInt(el.get(2));
            String producent = (el.get(3));
            float cena = Float.parseFloat(el.get(4));
            int promocja_id = Integer.parseInt(el.get(5));
            finalList.add(new Product(id, nazwa, producent, ilosc, cena, promocja_id));
        }
        return finalList;
    }
}
