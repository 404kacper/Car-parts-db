package com.application.Gui.controllers;

import com.database.Controlers.UserDBQueries;
import com.database.Models.User;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.stage.Stage;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.ResourceBundle;

import static com.database.Controlers.UserDBQueries.getAllUsers;
import static com.database.Controlers.UserDBQueries.deleteUser;


public class AdministratorController implements Initializable {
    User loggedUser;
    @FXML
    private Label username;
    @FXML
    private ListView<String> interfaceList;
    @FXML
    private TextField usernameInput;
    @FXML
    private TextField passwordInput;
    @FXML
    private TextField roleInput;

    @FXML
    public void getUsers(MouseEvent event) {
        interfaceList.getItems().clear();
        ArrayList<User> usersList = getAllUsers();
        usersList.forEach(user -> {
            interfaceList.getItems().add(user.toString());
        });
    }

    @FXML
    public void addUser(MouseEvent event) {
        String username = usernameInput.getText();
        String password = passwordInput.getText();
        String role = roleInput.getText();
        User.UserType dbRole = null;

        switch (role) {
            case "administrator":
                dbRole = User.getUserType(4);
                break;
            case "pracownik" :
                dbRole = User.getUserType(3);
                break;
            case "zalogowany" :
                dbRole = User.getUserType(2);
                break;
            default:
                dbRole = User.getUserType(1);
                break;
        }

        if (!usernameInput.getText().trim().isEmpty() & !passwordInput.getText().trim().isEmpty() & !roleInput.getText().trim().isEmpty()) {
            User newUser = new User(null, "userCreatedByAdmin", username, password, null, null);
            newUser.typ = dbRole;
            UserDBQueries.addUser(newUser);
            getUsers(event);
        }

    }

    @FXML
    public void deleteSelectedUser(MouseEvent event) {
        String userString = interfaceList.getSelectionModel().getSelectedItems().toString();
        userString = userString.substring(1, userString.length() - 1);
        String[] fields = userString.split(", ");
//        for (String field: fields) {
//            System.out.println(field);
//        }
        // cut out the part before id
        int startingIndex = fields[0].indexOf("{")+1;
        fields[0] = fields[0].substring(startingIndex);
        // cut out the part after niezalogowany --> closed brackets
        int stopIndex = fields[fields.length-1].indexOf("}");
        fields[fields.length-1] = fields[fields.length-1].substring(0, stopIndex);
        // create hashmap with appropriate values
        Map<String, String> map = new HashMap<>();
        for (String field : fields) {
            String[] pair = field.split("=");
            map.put(pair[0], pair[1]);
        }

//        System.out.println(map.get("id"));
//        System.out.println(map.get("nazwa"));
//        System.out.println(map.get("login"));
//        System.out.println(map.get("haslo"));
//        System.out.println(map.get("adres"));
//        System.out.println(map.get("typ"));

        // delete user by id from db
        deleteUser(Integer.parseInt(map.get("id")));
        // update displayed list
        getUsers(event);
    }

    AdministratorController(User passedUser) {
        this.loggedUser = passedUser;
    }

    // tak powinno wygladac kazde initalize ale w javie widocznie to nie ma znaczenia ...
    @Override
    public void initialize(URL url, ResourceBundle resourceBundle) {
        username.setText(loggedUser.nazwa);
    }

    public void switchToUnverified(MouseEvent event) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/niezalogowany.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new NiezalogowanyController());
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
    }
}
