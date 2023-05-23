package com.application.Gui.controllers;

import com.database.Models.Product;
import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.input.MouseEvent;

public class GridItemController {
    @FXML
    private Label nameLabel;
    @FXML
    private Label priceLabel;
    @FXML
    private Label promotionLabel;

    private Product product;

    private ZalogowanyController controller;

    @FXML
    public void click(MouseEvent event) {
        controller.setChosenProduct(product);
        // tutaj kod do obsługi nacisniecia na element - wyswietlenie jego wartosci w polu obok - jezeli to mozliwe - jezeli nie nic sie dzieje - potrzebyn dodatkowy argument w funkcji
    }

    public void setDataZalogowany(Product passedProduct, ZalogowanyController listener) {
        product = passedProduct;
        controller = listener;
        nameLabel.setText(passedProduct.nazwa);
        priceLabel.setText(String.valueOf(passedProduct.cena) + " zł");
        if ((passedProduct.promotion.getTyp_promocji() >= 1)) {
            promotionLabel.setText("Tak");
        } else {
            promotionLabel.setText("Nie");
        }
    }

    public void setDataNiezalogowany(Product passedProduct) {
        controller = null;
        product = passedProduct;
        nameLabel.setText(passedProduct.nazwa);
        priceLabel.setText(String.valueOf(passedProduct.cena) + " zł");
        if ((passedProduct.promotion.getTyp_promocji() >= 1)) {
            promotionLabel.setText("Tak");
        } else {
            promotionLabel.setText("Nie");
        }
    }

}
