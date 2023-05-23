package com.application.Gui.controllers;

import com.database.Models.Basket;
import com.database.Models.Order;
import com.database.Models.Product;
import com.database.Models.User;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.input.MouseEvent;
import javafx.stage.Stage;

import java.io.IOException;

import static com.database.Controlers.ProductDBQueries.getProductById;
import static com.database.Controlers.OrderDBQueries.addOrder;

public class BasketController {
    Basket basket;
    Product baskedProduct;
    User loggedUser;

    @FXML
    private Label nameLabel;

    @FXML
    private Label priceLabel;

    @FXML
    private Label amountLabel;

    @FXML
    private Label totalPriceLabel;

    @FXML
    public void send(MouseEvent event) {
        sendOrder();
        switchToLogged(event);
    }

    BasketController (Basket passedBasket, User passedUser) {
        basket = passedBasket;
        loggedUser=passedUser;
    }

    public void initialize() {
        baskedProduct = getProductById(basket.produkt_id);
        nameLabel.setText(baskedProduct.nazwa);
        amountLabel.setText(String.valueOf(1));
        priceLabel.setText(String.format("%.2f", baskedProduct.getFinalPrice()));
        totalPriceLabel.setText(String.format("%.2f", baskedProduct.getFinalPrice()+ 9.99));
    }

    public void sendOrder() {
        Order order = new Order(null, loggedUser.id, baskedProduct.id, basket.id,  0, 0);
        addOrder(order);
    }

    @FXML
    public void goToLogged(MouseEvent event) {
        switchToLogged(event);
    }

    public void switchToLogged(MouseEvent event) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/zalogowany.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new ZalogowanyController(loggedUser));
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
    }
}
