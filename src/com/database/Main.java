package com.database;


import com.application.Gui.DatabaseGui;
import com.database.Models.*;
import com.database.Services.CurrentUserService;

import java.util.ArrayList;

import static com.database.Controlers.OrderDBQueries.updateOrder;
import static com.database.Controlers.ProductDBQueries.*;
import static com.database.Controlers.PromotionDBQueries.updatePromotion;
import static com.database.Controlers.UserDBQueries.*;


public class Main {

    public static void main(String[] args) {
//        User user = new User(101, "A", "B", "haslo", "8 Debra Lane", User.UserType.NIEZALOGOWANY);
//        updateUser(15, user);
//        Product product = new Product(101, "Smar", "Hyudai", 100, 49.9f, 2);
//        updateProduct(10, product);
//        Order order = new Order(100,1,2,3,41.9f,0);
//        updateOrder(12, order);
//        Promotion promotion = new Promotion(9,1, 0.9f);
//        updatePromotion(2, promotion);
//
//        deleteUser(105);

//        ArrayList<User> list = getAllUsers();
//        for (User el: list) {
//            System.out.println(el.toString());
//        }


        // Obsluga wyjątków przy logowaniu wywalanie błędu, że user nie istnieje
        // Przyciski w zależności od funkcji isAdmin isEmployee itp

//        System.out.println(CurrentUserService.getInstance().toString());
//        CurrentUserService.getInstance().login("Ehlerding", "Lgk67F5xI");
//
//        System.out.println(CurrentUserService.getInstance().toString());
//        CurrentUserService.getInstance().logout();
//        System.out.println(CurrentUserService.getInstance().toString());
//
//        //Bo register jest tylko jako klient na pracownika może zmienić jedynie admin, więc zwróci klienta
//        User newUser = new User(null, "Maciej", "Hajduk", "Haslo",
//                "38066 Blaine Street", User.UserType.PRACOWNIK);
//        CurrentUserService.getInstance().register(newUser);
//        System.out.println(CurrentUserService.getInstance().toString());
//
//        //Dodanie obiektu promocja do obiektu Produkt po PROMOCJA_ID
//        System.out.println(getAllProducts());
        // TODO list:
        //  - dodawanie/usuwanie produktu i user
        //  - wyswietlanie powyzszych
        //  - zamówienie - obsługa po stronie pracownika
        //  - edytowanie uzytkownikow admin
        //  - ważne -- trzeba dokończyć tworzenie zamówienia z koszyka w ostatnim interface
        DatabaseGui.main(args);
    }
}
