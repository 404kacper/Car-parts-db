package com.application.Gui.controllers;

import com.database.DBConnection;
import com.database.Models.User;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.TextField;
import javafx.scene.input.MouseEvent;
import javafx.stage.Stage;

import java.io.IOException;

public class LoginController {

    @FXML
    private TextField loginInput;

    @FXML
    private TextField hasloInput;

    public void tryLogin(MouseEvent mouseEvent) {
        User retrievedUser = DBConnection.connectForUser(loginInput.getText(), hasloInput.getText());
        if (DBConnection.getSqlConnection() != null) {
            if (retrievedUser.getDBUserType() == 2) {
                switchToVerified(mouseEvent, retrievedUser);
            } else if(retrievedUser.getDBUserType() == 4) {
                switchToAdmin(mouseEvent, retrievedUser);
            } else if(retrievedUser.getDBUserType() == 3) {
                switchToPracownik(mouseEvent, retrievedUser);
            } else if(retrievedUser.getDBUserType() == 1) {
                switchToUnverified(mouseEvent);
            }
        } else {
            System.out.println("Ze wzgledu na wprowadzone dane nie mozna pomyslnie zalogowac uzytkownika.");
        }

    }

    public void tryUnverified(MouseEvent mouseEvent) {
        String login = "niezalogowany";
        String haslo = "1234";
        User retrievedUser = DBConnection.connectForUser(login, haslo);
        if (DBConnection.getSqlConnection() != null) {
            switchToUnverified(mouseEvent);
        } else {
            System.out.println("Ze wzgledu na wprowadzone dane nie mozna pomyslnie zalogowac uzytkownika.");
        }
    }

    public void switchToPracownik(MouseEvent event, User passedUser) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/pracownik.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new PracownikController(passedUser));
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
    }

    public void switchToAdmin(MouseEvent event, User passedUser) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/administrator.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new AdministratorController(passedUser));
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
    }

    public void switchToVerified(MouseEvent event, User passedUser) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/zalogowany.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new ZalogowanyController(passedUser));
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
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
