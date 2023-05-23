package com.database.Models;

public class Promotion {
    public Integer id;
    public int typ_promocji;
    public float wysokosc_promocji;

    public Promotion(Integer id, int typ_promocji, float wysokosc_promocji) {
        this.id = id;
        this.typ_promocji = typ_promocji;
        this.wysokosc_promocji = wysokosc_promocji;
    }


    public int getTyp_promocji() {
        return typ_promocji;
    }

    @Override
    public String toString() {
        return "Promotion{" +
                "id=" + id +
                ", typ_promocji=" + typ_promocji +
                ", wysokosc_promocji=" + wysokosc_promocji +
                '}';
    }
}
