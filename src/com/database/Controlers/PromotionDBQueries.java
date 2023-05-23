package com.database.Controlers;

import com.database.DBConnection;
import com.database.Models.Promotion;

import java.util.ArrayList;

public class PromotionDBQueries {
    public static ArrayList<Promotion> getAllPromotions() {
        String query = "SELECT * FROM DB.PROMOCJA";
        ArrayList<ArrayList<String>> promotionList = DBConnection.rawQuery(query);
        ArrayList<Promotion> finalList = new ArrayList<>();
        for (ArrayList<String> el : promotionList) {
            int id = Integer.parseInt(el.get(0));
            int typ = Integer.parseInt(el.get(1));
            float wysokosc = Float.parseFloat(el.get(2));

            finalList.add(new Promotion(id, typ, wysokosc));
        }
        return finalList;
    }

    public static void addPromotion(Promotion promotion) {
        String query = "INSERT INTO DB.PROMOCJA (TYP_PROMOCJI, WYSOKOSC_PROMOCJI) values " +
                "(" + promotion.typ_promocji + ", " + promotion.wysokosc_promocji + ")";
        DBConnection.rawQuery(query);
    }

    public static void updatePromotion(int id, Promotion promotion) {
        String query = "UPDATE DB.PROMOCJA SET " +
                "TYP_PROMOCJI = " + promotion.typ_promocji + ", " +
                "WYSOKOSC_PROMOCJI = " + promotion.wysokosc_promocji +
                " WHERE PROMOCJA_ID = " + id;
        DBConnection.rawQuery(query);
    }

    public static Promotion getPromotionById(int id) {
        String query = "SELECT * FROM DB.PROMOCJA" +
                " WHERE PROMOCJA_ID = " + id;
        ArrayList<String> list = DBConnection.rawQuery(query).get(0);
        int typ_promocji = Integer.parseInt(list.get(1));
        float wysokosc = Float.parseFloat(list.get(2));
        return new Promotion(id, typ_promocji, wysokosc);
    }

    public static void deletePromotion(int id) {
        String query = "DELETE FROM DB.PROMOCJA WHERE PROMOCJA_ID = " + id;
        DBConnection.rawQuery(query);
    }
}
