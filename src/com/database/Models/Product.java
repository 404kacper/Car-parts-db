package com.database.Models;

import static com.database.Controlers.PromotionDBQueries.getPromotionById;

public class Product {
    public Integer id;
    public String nazwa;
    public String producent;
    public int ilosc;
    public float cena;
    public int id_promocji;
    public Promotion promotion;

    public Product(Integer id, String nazwa, String producent, int ilosc, float cena, int id_promocji) {
        this.id = id;
        this.nazwa = nazwa;
        this.producent = producent;
        this.ilosc = ilosc;
        this.cena = cena;
        this.id_promocji = id_promocji;

        this.promotion = getPromotionById(id_promocji);
    }

    public String getProducent() {
        return producent;
    }

    public float getFinalPrice() {
        return this.cena * promotion.wysokosc_promocji;
    }

    @Override
    public String toString() {
        return "Product{" +
                "id=" + id +
                ", nazwa='" + nazwa + '\'' +
                ", producent='" + producent + '\'' +
                ", ilosc=" + ilosc +
                ", cena=" + cena +
                ", id_promocji=" + id_promocji +
                ", promotion=" + promotion +
                '}';
    }
}
