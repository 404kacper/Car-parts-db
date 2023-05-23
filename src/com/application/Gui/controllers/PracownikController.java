package com.application.Gui.controllers;

import com.database.Controlers.UserDBQueries;
import com.database.Models.Order;
import com.database.Models.User;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.input.MouseEvent;
import javafx.stage.Stage;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.ResourceBundle;

import static com.database.Controlers.OrderDBQueries.getAllOrders;
import static com.database.Controlers.OrderDBQueries.updateOrderStatus;
import static com.database.Controlers.OrderDBQueries.deleteOrder;




public class PracownikController implements Initializable {
    User loggedUser;
    @FXML
    private Label username;
    @FXML
    private ListView<String> ordersList;

    @FXML
    public void getOrders(MouseEvent event) {
        ordersList.getItems().clear();
        ArrayList<Order> usersList = getAllOrders();
        usersList.forEach(user -> {
            ordersList.getItems().add(user.toString());
        });
    }

    PracownikController(User passedUser) {
        this.loggedUser = passedUser;
    }

    @FXML
    public void deleteSelectedOrder(MouseEvent event) {
        int orderId = getIdFromSelected();
        deleteOrder(orderId);
        getOrders(event);
    }

    @FXML
    public void updateSelectedOrder(MouseEvent event) {
        int orderId = getIdFromSelected();
        updateOrderStatus(orderId, 1);
        getOrders(event);
    }

    public int getIdFromSelected() {
        String userString = ordersList.getSelectionModel().getSelectedItems().toString();
        userString = userString.substring(1, userString.length() - 1);

        String[] fields = userString.split(", ");

        int startingIndex = fields[0].indexOf("{")+1;
        fields[0] = fields[0].substring(startingIndex);
        int stopIndex = fields[fields.length-1].indexOf("}");
        fields[fields.length-1] = fields[fields.length-1].substring(0, stopIndex);

        // create hashmap with appropriate values
        Map<String, String> map = new HashMap<>();
        for (String field : fields) {
            String[] pair = field.split("=");
            map.put(pair[0], pair[1]);
        }

        return Integer.parseInt(map.get("id"));
    }

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
