package com.database.Models;

public class User {
    public enum UserType {
        ADMIN, PRACOWNIK, KLIENT, NIEZALOGOWANY;
    }

    public Integer id;
    public String nazwa;
    public String login;
    public String haslo;
    public String adres;
    public UserType typ;

    public User(Integer id, String nazwa, String login, String haslo, String adres, UserType typ) {
        this.id = id;
        this.nazwa = nazwa;
        this.login = login;
        this.haslo = haslo;
        this.adres = adres;
        this.typ = typ;
    }

    public int getDBUserType() {
        return switch (this.typ) {
            case ADMIN -> 4;
            case PRACOWNIK -> 3;
            case KLIENT -> 2;
            default -> 1;
        };
    }

    public static UserType getUserType(int dbType) {
        return switch (dbType) {
            case 4 -> UserType.ADMIN;
            case 3 -> UserType.PRACOWNIK;
            case 2 -> UserType.KLIENT;
            default -> UserType.NIEZALOGOWANY;
        };
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", nazwa='" + nazwa + '\'' +
                ", login='" + login + '\'' +
                ", haslo='" + haslo + '\'' +
                ", adres='" + adres + '\'' +
                ", typ=" + typ +
                '}';
    }
}
