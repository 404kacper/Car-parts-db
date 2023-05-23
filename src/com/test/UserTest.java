package com.test;

import com.database.DBConnection;
import com.database.Models.Product;
import com.database.Models.User;
import static com.database.Controlers.UserDBQueries.*;
import org.junit.Assert;
import org.junit.Test;

import java.util.ArrayList;

public class UserTest {

    @Test
    public void dodajUzytkownika() {
        DBConnection connection = new DBConnection();
        connection.setUSER("administrator");
        connection.setPASS("abc");
        connection.connect();

        User newUser = new User(1, "Audo", "Audo", "123456789", "77604 Nelson Avenue", User.UserType.KLIENT);
        addUser(newUser);

        ArrayList<User> list = getAllUsers();
        Assert.assertTrue(list.contains(newUser));
    }
}
