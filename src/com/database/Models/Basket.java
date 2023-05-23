package com.database.Models;

import java.sql.Date;

public class Basket {
    public Integer id;
    public int produkt_id;
    public Date data;
    public int ilosc;

    public Basket() {};

    public Basket(Integer id, int produkt_id, Date date, int ilosc) {
        this.id = id;
        this.produkt_id = produkt_id;
        this.data = date;
        this.ilosc = ilosc;
    }

    @Override
    public String toString() {
        return "Basket{" +
                "id=" + id +
                ", produkt_id=" + produkt_id +
                ", date=" + data +
                ", ilosc=" + ilosc +
                '}';
    }
}
