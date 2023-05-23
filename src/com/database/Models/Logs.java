package com.database.Models;

public class Logs {
    Integer id;
    String typ;
    int zamowienie_id;
    int uzytkownik_id;
    int status;

    public Logs(Integer id, String typ, int zamowienie_id, int uzytkownik_id, int status) {
        this.id = id;
        this.typ = typ;
        this.zamowienie_id = zamowienie_id;
        this.uzytkownik_id = uzytkownik_id;
        this.status = status;
    }

    @Override
    public String toString() {
        return "Logs{" +
                "id=" + id +
                ", typ='" + typ + '\'' +
                ", zamowienie_id=" + zamowienie_id +
                ", uzytkownik_id=" + uzytkownik_id +
                ", status=" + status +
                '}';
    }
}
