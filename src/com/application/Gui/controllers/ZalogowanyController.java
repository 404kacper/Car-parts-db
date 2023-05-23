package com.application.Gui.controllers;

import com.database.Models.Basket;
import com.database.Models.Product;
import com.database.Models.User;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.Region;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;

import static com.database.Controlers.ProductDBQueries.getAllProducts;
import static com.database.Controlers.BasketDBQueries.getHighestBasketID;
import static com.database.Controlers.BasketDBQueries.addBasket;



public class ZalogowanyController {

    @FXML
    private ChoiceBox brand;

    @FXML
    private ChoiceBox price;

    @FXML
    private GridPane grid;

    @FXML
    private Label chosenName;

    @FXML
    private Label chosenPrice;

    @FXML
    private Label chosenDiscount;
    
    @FXML
    private Button basketButton;

    @FXML
    private Label username;

    User loggedUser;

    @FXML
    public void sort(MouseEvent event) {displaySorted();}

    ZalogowanyController(User passedUser) {
        this.loggedUser = passedUser;
    }

    @FXML
    public void addToBasket(MouseEvent event) {
        int highestBasketID = getHighestBasketID();
        basket.id = ++highestBasketID;
        basket.produkt_id = chosenProduct.id;
        basket.data = new java.sql.Date(Calendar.getInstance().getTime().getTime());
        basket.ilosc = 1;
        addBasket(basket);
        switchToBasket(event);
    }

    ArrayList <Product> products;
    Basket basket;
    Product chosenProduct;


    public void initialize() {
        products = getAllProducts();
        fillGrid(products);
        basket = new Basket();
        username.setText(loggedUser.nazwa);

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
                fxmlLoader.setLocation(getClass().getResource("/com/application/Gui/views/gridItem.fxml"));
                AnchorPane anchorPane = fxmlLoader.load();

                GridItemController gridItemController = fxmlLoader.getController();
                gridItemController.setDataZalogowany(productsList.get(i), this);

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

    public void setChosenProduct(Product product) {
        chosenName.setText(product.nazwa);
        chosenPrice.setText(Float.toString(product.cena));
        chosenDiscount.setText(String.format("%.2f",product.promotion.wysokosc_promocji*100));
        chosenProduct = product;
        basketButton.setDisable(false);
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


    @FXML
    public void switchToBasket(MouseEvent event) {
        Parent viewParent = null;
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/com/application/Gui/views/basket.fxml"));
//           Source for what's going on here - haisu answear: https://stackoverflow.com/questions/30814258/javafx-pass-parameters-while-instantiating-controller-class
            loader.setControllerFactory(controllerClass -> new BasketController(basket, loggedUser));
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
