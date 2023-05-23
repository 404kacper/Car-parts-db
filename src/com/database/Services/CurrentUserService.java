package com.database.Services;

import com.database.Models.User;

import static com.database.Controlers.UserDBQueries.addUser;
import static com.database.Controlers.UserDBQueries.findUserByLoginAndPassword;

public final class CurrentUserService extends User {
    private static CurrentUserService instance;

    public CurrentUserService() {
        super(null, null, null, null, null, UserType.NIEZALOGOWANY);
    }

    public static CurrentUserService getInstance() {
        if (instance == null) {
            instance = new CurrentUserService();
        }
        return instance;
    }

    public boolean isLoggedIn() {
        return this.typ != null && this.typ != UserType.NIEZALOGOWANY;
    }

    public boolean isEmployee() {
        return this.typ == UserType.PRACOWNIK;
    }

    public boolean isAdmin() {
        return this.typ == UserType.ADMIN;
    }

    public void register(User user) {
        addUser(user);
        // Od razu logujemy po rejestracji jako klient
        this.typ = UserType.KLIENT;
        this.adres = user.adres;
        this.nazwa = user.nazwa;
        this.id = user.id;
    }

    public void logout() {
        this.typ = UserType.NIEZALOGOWANY;
        this.adres = null;
        this.nazwa = null;
        this.id = null;
    }

    public void login(String login, String haslo) {
        try {
            User user = findUserByLoginAndPassword(login, haslo);
            this.adres = user.adres;
            this.nazwa = user.nazwa;
            this.typ = user.typ;
            this.id = user.id;
        } catch (IndexOutOfBoundsException e) {
            System.out.println("Zalogowany uzytkownik nie znajduje sie w bazie danych");
//            System.out.println(e.getErrorCode());
//            e.printStackTrace();
        }
    }

    public User loginForUser(String login, String haslo) {
        User user = new User(null, null, null, null, null, null);
        try {
            user = findUserByLoginAndPassword(login, haslo);
            this.adres = user.adres;
            this.nazwa = user.nazwa;
            this.typ = user.typ;
            this.id = user.id;
        } catch (IndexOutOfBoundsException e) {
            System.out.println("Zalogowany uzytkownik nie znajduje sie w bazie danych");
        }
        return user;
    }
}
