package com.database.Models;

public class Order {
    public Integer id;
    public int uzytkownik_id;
    public int promocja_id;
    public int koszyk_id;
    public float koszt;
    public int status;

    public Order(Integer id, int uzytkownik_id, int promocja_id, int koszyk_id, float koszt, int status) {
        this.id = id;
        this.uzytkownik_id = uzytkownik_id;
        this.promocja_id = promocja_id;
        this.koszyk_id = koszyk_id;
        this.koszt = koszt;
        this.status = status;
    }

    public int getKoszyk_id() {
        return koszyk_id;
    }

    public Integer getId() {
        return id;
    }

    @Override
    public String toString() {
        return "Order{" +
                "id=" + id +
                ", uzytkownik_id=" + uzytkownik_id +
                ", promocja_id=" + promocja_id +
                ", koszyk_id=" + koszyk_id +
                ", koszt=" + koszt +
                ", status=" + status +
                '}';
    }
}
