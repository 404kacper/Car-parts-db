package com.application.Gui.controllers;

import com.database.Models.Product;
import com.sun.jdi.Value;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.ChoiceBox;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.Region;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.ArrayList;
import static com.database.Controlers.ProductDBQueries.getAllProducts;

public class NiezalogowanyController {

    @FXML
    private ChoiceBox brand;

    @FXML
    private ChoiceBox price;

    @FXML
    private GridPane grid;

    private ArrayList<Product> products;

    @FXML
    public void goToLogin(MouseEvent event) {
        switchToLogin(event);
    }

    @FXML
    public void sort(MouseEvent event) {displaySorted();}

    public void initialize() {
        products = getAllProducts();
        fillGrid(products);
        brand.getItems().add("BMW");
        brand.getItems().add("Audi");
        brand.getItems().add("Honda");

        price.getItems().add("< 100 zł");
        price.getItems().add("> 100 zł");
        price.getItems().add("> 999 zł");
    }

    public void fillGrid(ArrayList<Product> productsList) {
        int row = 1, col = 0;
        try {
            for (int i = 0; i < productsList.size(); i++) {
                FXMLLoader fxmlLoader = new FXMLLoader();
                fxmlLoader.setLocation(getClass().getResource("/com/application/Gui/views/gridItemNiezalogowany.fxml"));
                AnchorPane anchorPane = fxmlLoader.load();

                GridItemController gridItemController = fxmlLoader.getController();
                gridItemController.setDataNiezalogowany(productsList.get(i));

                if (col == 3) {
                    col = 0;
                    row ++;
                }
                 grid.add(anchorPane, col++, row);
            }
            // set grid width
            grid.setMinWidth(Region.USE_COMPUTED_SIZE);
            grid.setPrefWidth(Region.USE_COMPUTED_SIZE);
            grid.setMaxWidth(Region.USE_COMPUTED_SIZE);

            // set grid height
            grid.setMinHeight(Region.USE_COMPUTED_SIZE);
            grid.setPrefHeight(Region.USE_COMPUTED_SIZE);
            grid.setMaxHeight(Region.USE_COMPUTED_SIZE);
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    public void displaySorted() {
        grid.getChildren().clear();
        ArrayList<Product> sortedProductsByBrand = new ArrayList<>();
        ArrayList<Product> sortedProducts = new ArrayList<>();


        if (brand.getValue() != null) {
            for (Product produkt: products) {
                // po prostu sprawdzenie czy zgadzaja sie stringi w polu i w produkcie - nieczule na duze litery
                if (produkt.getProducent().equalsIgnoreCase(brand.getValue().toString())) {
                    sortedProductsByBrand.add(produkt);
                } else if (brand.getValue().equals("null")){
                    sortedProductsByBrand.add(produkt);
                }
            }
        } else {
            sortedProductsByBrand = products;
        }

        if (price.getValue() != null) {
            int selectedPrice =  Integer.parseInt(price.getValue().toString().substring(2,5));
            String operator = price.getValue().toString().substring(0, 1);

            for (Product produkt : sortedProductsByBrand) {
                if (operator.equals("<") && produkt.getFinalPrice() < selectedPrice) {
                    sortedProducts.add(produkt);
                } else if (operator.equals(">") && produkt.getFinalPrice() > selectedPrice && produkt.getFinalPrice() < 999) {
                    System.out.println(produkt.getFinalPrice());
                    System.out.println(selectedPrice);
                    sortedProducts.add(produkt);
                }
                else if (operator.equals(">") && produkt.getFinalPrice() > selectedPrice && selectedPrice == 999) {
                    sortedProducts.add(produkt);
                }
            }
        }  else {
            sortedProducts = sortedProductsByBrand;
        }

        fillGrid(sortedProducts);
    }

    public void switchToLogin(MouseEvent event) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/login.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new LoginController());
            viewParent = loader.load();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        Stage window = (Stage)((Node)event.getSource()).getScene().getWindow();

        window.setScene(new Scene(viewParent));
        window.show();
    }
}
